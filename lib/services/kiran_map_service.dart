import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/place_geo_model.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

class KiranMapKiran {
  final int partNumber;
  final KiranInfo kiranInfo;
  final DateTime date;

  const KiranMapKiran({
    required this.partNumber,
    required this.kiranInfo,
    required this.date,
  });
}

class KiranMapPin {
  final PlaceGeo place;
  final int kiranCount;
  final List<int> years;
  final List<KiranMapKiran> kirans;

  const KiranMapPin({
    required this.place,
    required this.kiranCount,
    required this.years,
    required this.kirans,
  });
}

class KiranRouteArrow {
  final LatLng point;
  final double bearingDegrees;

  const KiranRouteArrow({required this.point, required this.bearingDegrees});
}

enum KiranRouteKind { outbound, inbound }

class KiranRouteLine {
  final KiranRouteKind kind;
  final List<LatLng> points;
  final List<KiranRouteArrow> arrows;

  const KiranRouteLine({
    required this.kind,
    required this.points,
    required this.arrows,
  });
}

class KiranVicharanTrip {
  final int number;
  final DateTime start;
  final DateTime end;
  final List<PlaceGeo> stops;
  final List<KiranMapKiran> kirans;
  final bool returnsHome;

  const KiranVicharanTrip({
    required this.number,
    required this.start,
    required this.end,
    required this.stops,
    required this.kirans,
    required this.returnsHome,
  });

  String get routeSummary => stops.map((stop) => stop.displayName).join(' → ');

  bool containsKiran(int index) =>
      kirans.any((kiran) => kiran.kiranInfo.index == index);

  List<KiranMapKiran> kiransAt(PlaceGeo place) {
    return [
      for (final kiran in kirans)
        if (place.names.any(kiran.kiranInfo.visitsVillage)) kiran,
    ];
  }
}

class KiranMapSnapshot {
  static const homePlaceId = 'piplana';
  static const _distance = Distance();
  static const _minArrowMeters = 800.0;
  static const _longHopMeters = 40000.0;
  static const _arrowEveryMeters = 25000.0;
  static const _routeOffsetMeters = 45.0;

  final List<KiranMapKiran> _kirans;
  final Map<String, PlaceGeo> _byName;
  final Map<String, PlaceGeo> _byId;
  final Map<String, List<LatLng>> _roads;
  final List<KiranVicharanTrip> trips;
  final List<int> years;
  final List<String> unmappedNames;

  const KiranMapSnapshot({
    required List<KiranMapKiran> kirans,
    required Map<String, PlaceGeo> byName,
    required Map<String, PlaceGeo> byId,
    required Map<String, List<LatLng>> roads,
    required this.trips,
    required this.years,
    required this.unmappedNames,
  }) : _kirans = kirans,
       _byName = byName,
       _byId = byId,
       _roads = roads;

  static const empty = KiranMapSnapshot(
    kirans: [],
    byName: {},
    byId: {},
    roads: {},
    trips: [],
    years: [],
    unmappedNames: [],
  );

  PlaceGeo? get home => _byId[homePlaceId];

  bool isHome(PlaceGeo place) => place.id == homePlaceId;

  PlaceGeo? resolve(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    return _byName[trimmed];
  }

  KiranMapKiran? kiranForIndex(int index) {
    for (final kiran in _kirans) {
      if (kiran.kiranInfo.index == index) return kiran;
    }
    return null;
  }

  List<KiranVicharanTrip> tripsFor({int? year}) {
    if (year == null) return trips;
    return [
      for (final trip in trips)
        if (trip.start.year == year ||
            trip.end.year == year ||
            trip.kirans.any((kiran) => kiran.date.year == year))
          trip,
    ];
  }

  KiranVicharanTrip? tripForNumber(int number) {
    for (final trip in trips) {
      if (trip.number == number) return trip;
    }
    return null;
  }

  /// All mapped villages, or those visited in [year]. Home (Piplana) is always
  /// included.
  List<KiranMapPin> pinsFor({int? year}) {
    final Map<String, List<KiranMapKiran>> byPlace = {};
    for (final kiran in _kirans) {
      if (year != null && kiran.date.year != year) continue;
      for (final name in _villageNames(kiran.kiranInfo)) {
        final place = resolve(name);
        if (place == null) continue;
        final list = byPlace.putIfAbsent(place.id, () => []);
        if (list.any((item) => item.kiranInfo.index == kiran.kiranInfo.index)) {
          continue;
        }
        list.add(kiran);
      }
    }

    final pins =
        byPlace.entries.map((entry) {
          final kirans = List<KiranMapKiran>.from(entry.value)
            ..sort((a, b) => a.date.compareTo(b.date));
          final yearSet =
              kirans.map((item) => item.date.year).toSet().toList()..sort();
          return KiranMapPin(
            place: _byId[entry.key]!,
            kiranCount: kirans.length,
            years: yearSet,
            kirans: kirans,
          );
        }).toList();

    final homePlace = home;
    if (homePlace != null && !pins.any((pin) => pin.place.id == homePlaceId)) {
      pins.add(
        KiranMapPin(
          place: homePlace,
          kiranCount: 0,
          years: const [],
          kirans: const [],
        ),
      );
    }
    pins.sort((a, b) {
      if (a.place.id == homePlaceId) return -1;
      if (b.place.id == homePlaceId) return 1;
      return a.place.displayName.compareTo(b.place.displayName);
    });
    return pins;
  }

  List<KiranRouteLine> vicharanRouteLines({int? year, int? tripNumber}) {
    var selected = tripsFor(year: year);
    if (tripNumber != null) {
      selected = [
        for (final trip in selected)
          if (trip.number == tripNumber) trip,
      ];
    }
    final saurashtraOnly = year == null && tripNumber == null;
    final outbound = <String, List<LatLng>>{};
    final inbound = <String, List<LatLng>>{};
    for (final trip in selected) {
      for (var i = 0; i < trip.stops.length - 1; i++) {
        final from = trip.stops[i];
        final to = trip.stops[i + 1];
        if (saurashtraOnly && (!from.isSaurashtra || !to.isSaurashtra)) {
          continue;
        }
        final key = '${from.id}>${to.id}';
        final path = _roadBetween(from, to);
        if (path.length < 2) continue;
        if (_isOutbound(from, to)) {
          outbound.putIfAbsent(key, () => path);
        } else {
          inbound.putIfAbsent(key, () => path);
        }
      }
    }
    return [
      for (final path in outbound.values)
        _lineFor(KiranRouteKind.outbound, path),
      for (final path in inbound.values) _lineFor(KiranRouteKind.inbound, path),
    ];
  }

  KiranRouteLine _lineFor(KiranRouteKind kind, List<LatLng> path) {
    final offset = _offsetPath(path, _routeOffsetMeters);
    return KiranRouteLine(
      kind: kind,
      points: offset,
      arrows: _arrowsOnPath(offset),
    );
  }

  /// Kirans with `places.length > 1` as short polylines.
  List<List<LatLng>> sittingPaths({int? year, int? kiranIndex}) {
    if (year == null && kiranIndex == null) return const [];

    final paths = <List<LatLng>>[];
    for (final kiran in _kirans) {
      if (kiranIndex != null && kiran.kiranInfo.index != kiranIndex) continue;
      if (kiranIndex == null && year != null && kiran.date.year != year) {
        continue;
      }
      final stops = _mappedStops(_villageNames(kiran.kiranInfo));
      if (stops.length <= 1) continue;
      paths.add(_expandStops(stops));
    }
    return paths;
  }

  bool _isOutbound(PlaceGeo from, PlaceGeo to) {
    final homePlace = home;
    if (homePlace == null) return true;
    if (from.id == homePlaceId) return true;
    if (to.id == homePlaceId) return false;
    final origin = LatLng(homePlace.lat, homePlace.lng);
    final fromD = _distance.as(
      LengthUnit.Meter,
      origin,
      LatLng(from.lat, from.lng),
    );
    final toD = _distance.as(LengthUnit.Meter, origin, LatLng(to.lat, to.lng));
    return toD >= fromD;
  }

  List<PlaceGeo> _mappedStops(List<String> names) {
    final stops = <PlaceGeo>[];
    String? lastId;
    for (final name in names) {
      final place = resolve(name);
      if (place == null) continue;
      if (place.id == lastId) continue;
      stops.add(place);
      lastId = place.id;
    }
    return stops;
  }

  List<LatLng> _roadBetween(PlaceGeo from, PlaceGeo to) {
    final path = _roads['${from.id}>${to.id}'];
    if (path != null && path.length >= 2) return path;
    return [LatLng(from.lat, from.lng), LatLng(to.lat, to.lng)];
  }

  List<LatLng> _expandStops(List<PlaceGeo> stops) {
    if (stops.isEmpty) return const [];
    if (stops.length == 1) {
      return [LatLng(stops.first.lat, stops.first.lng)];
    }
    final out = <LatLng>[];
    for (var i = 0; i < stops.length - 1; i++) {
      final seg = _roadBetween(stops[i], stops[i + 1]);
      if (out.isEmpty) {
        out.addAll(seg);
      } else {
        out.addAll(seg.skip(1));
      }
    }
    return out;
  }

  List<LatLng> _offsetPath(List<LatLng> path, double meters) {
    if (path.length < 2 || meters == 0) return path;
    final out = <LatLng>[];
    for (var i = 0; i < path.length; i++) {
      final LatLng a;
      final LatLng b;
      if (i == 0) {
        a = path[0];
        b = path[1];
      } else if (i == path.length - 1) {
        a = path[i - 1];
        b = path[i];
      } else {
        a = path[i - 1];
        b = path[i + 1];
      }
      if (a.latitude == b.latitude && a.longitude == b.longitude) {
        out.add(path[i]);
        continue;
      }
      try {
        out.add(_distance.offset(path[i], meters, _leftBearing(a, b)));
      } catch (_) {
        out.add(path[i]);
      }
    }
    return out;
  }

  double _leftBearing(LatLng from, LatLng to) {
    var bearing = _distance.bearing(from, to) - 90;
    while (bearing > 180) {
      bearing -= 360;
    }
    while (bearing < -180) {
      bearing += 360;
    }
    if (bearing > 180) return 180;
    if (bearing < -180) return -180;
    return bearing;
  }

  List<KiranRouteArrow> _arrowsOnPath(List<LatLng> path) {
    final total = _pathLength(path);
    if (total < _minArrowMeters) return const [];
    if (total < _longHopMeters) {
      final arrow = _arrowAtFraction(path, 0.55);
      return arrow == null ? const [] : [arrow];
    }
    final arrows = <KiranRouteArrow>[];
    var at = _arrowEveryMeters / 2;
    while (at < total) {
      final arrow = _arrowAtFraction(path, at / total);
      if (arrow != null) arrows.add(arrow);
      at += _arrowEveryMeters;
    }
    return arrows;
  }

  double _pathLength(List<LatLng> path) {
    var total = 0.0;
    for (var i = 0; i < path.length - 1; i++) {
      total += _distance.as(LengthUnit.Meter, path[i], path[i + 1]);
    }
    return total;
  }

  KiranRouteArrow? _arrowAtFraction(List<LatLng> path, double fraction) {
    if (path.length < 2) return null;
    final total = _pathLength(path);
    if (total <= 0) return null;
    final target = total * fraction.clamp(0.05, 0.95);
    var walked = 0.0;
    for (var i = 0; i < path.length - 1; i++) {
      final a = path[i];
      final b = path[i + 1];
      final step = _distance.as(LengthUnit.Meter, a, b);
      if (walked + step >= target) {
        final t = step == 0 ? 0.0 : (target - walked) / step;
        return KiranRouteArrow(
          point: LatLng(
            a.latitude + (b.latitude - a.latitude) * t,
            a.longitude + (b.longitude - a.longitude) * t,
          ),
          bearingDegrees: _distance.bearing(a, b),
        );
      }
      walked += step;
    }
    return KiranRouteArrow(
      point: path[path.length - 2],
      bearingDegrees: _distance.bearing(path[path.length - 2], path.last),
    );
  }

  static List<KiranVicharanTrip> buildTrips(
    List<KiranMapKiran> kirans,
    PlaceGeo? Function(String name) resolve,
  ) {
    final trips = <KiranVicharanTrip>[];
    final current = <({KiranMapKiran kiran, PlaceGeo place})>[];
    String? lastId;

    void addTrip(List<({KiranMapKiran kiran, PlaceGeo place})> records) {
      if (records.length <= 1) return;
      if (!records.any((item) => item.place.id != homePlaceId)) return;

      final stops = <PlaceGeo>[];
      String? stopId;
      for (final item in records) {
        if (item.place.id == stopId) continue;
        stops.add(item.place);
        stopId = item.place.id;
      }
      if (stops.length < 2) return;

      final start = _indexOfKiran(kirans, records.first.kiran);
      final end = _indexOfKiran(kirans, records.last.kiran);
      final kiransOnTrip =
          (start >= 0 && end >= start)
              ? kirans.sublist(start, end + 1)
              : [for (final item in records) item.kiran];

      trips.add(
        KiranVicharanTrip(
          number: trips.length + 1,
          start: records.first.kiran.date,
          end: records.last.kiran.date,
          stops: stops,
          kirans: kiransOnTrip,
          returnsHome: stops.last.id == homePlaceId,
        ),
      );
    }

    for (final kiran in kirans) {
      final stops = _stopsOf(kiran, resolve);
      for (var i = 0; i < stops.length; i++) {
        final place = stops[i];
        final endsHere = i == stops.length - 1;
        if (place.id == lastId) {
          if (endsHere && current.isNotEmpty) {
            current[current.length - 1] = (kiran: kiran, place: place);
          }
          continue;
        }

        current.add((kiran: kiran, place: place));
        lastId = place.id;
        if (place.id == homePlaceId &&
            current.length > 1 &&
            current.any((item) => item.place.id != homePlaceId)) {
          addTrip(List.of(current));
          current
            ..clear()
            ..add((kiran: kiran, place: place));
        }
      }
    }
    if (current.any((item) => item.place.id != homePlaceId)) {
      addTrip(List.of(current));
    }
    return trips;
  }

  static int _indexOfKiran(List<KiranMapKiran> kirans, KiranMapKiran kiran) {
    for (var i = 0; i < kirans.length; i++) {
      if (kirans[i].kiranInfo.index == kiran.kiranInfo.index) return i;
    }
    return -1;
  }

  static List<PlaceGeo> _stopsOf(
    KiranMapKiran kiran,
    PlaceGeo? Function(String name) resolve,
  ) {
    final stops = <PlaceGeo>[];
    String? lastId;
    for (final name in _villageNames(kiran.kiranInfo)) {
      final place = resolve(name);
      if (place == null) continue;
      if (place.id == lastId) continue;
      stops.add(place);
      lastId = place.id;
    }
    return stops;
  }

  static List<String> _villageNames(KiranInfo info) {
    if (info.places.isNotEmpty) return info.places;
    if (info.place.isNotEmpty) return [info.place];
    return const [];
  }

  static int _compareKirans(KiranMapKiran a, KiranMapKiran b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    return a.kiranInfo.index.compareTo(b.kiranInfo.index);
  }
}

class KiranMapService {
  static final KiranMapService _instance = KiranMapService._internal();
  factory KiranMapService() => _instance;
  KiranMapService._internal();

  KiranMapSnapshot? _snapshot;
  Future<void>? _loading;

  bool get isLoaded => _snapshot != null;

  KiranMapSnapshot get snapshot => _snapshot ?? KiranMapSnapshot.empty;

  Future<void> load() {
    if (_snapshot != null) return Future.value();
    return _loading ??= _loadUncached();
  }

  Future<void> _loadUncached() async {
    try {
      final kiransRaw = await rootBundle.loadString(
        'assets/book/saxatsavita/_all_kirans_.json',
      );
      final placesRaw = await rootBundle.loadString(
        'assets/book/saxatsavita/places.json',
      );

      final kiransJson = jsonDecode(kiransRaw) as Map<String, dynamic>;
      final placesJson = jsonDecode(placesRaw) as Map<String, dynamic>;
      final roads = await _loadRoads();

      final byName = <String, PlaceGeo>{};
      final byId = <String, PlaceGeo>{};
      for (final item in placesJson['places'] as List<dynamic>? ?? const []) {
        if (item is! Map) continue;
        final place = PlaceGeo.fromMap(Map<String, dynamic>.from(item));
        if (place.id.isEmpty) continue;
        byId[place.id] = place;
        for (final name in place.names) {
          byName[name] = place;
        }
      }

      final kirans = <KiranMapKiran>[];
      final unmapped = <String>{};
      final yearSet = <int>{};

      for (final item in kiransJson['list'] as List<dynamic>? ?? const []) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final info = KiranInfo.fromMap(map);
        final date = Utils.parseKiranDate(info.date);
        if (date == null) continue;

        yearSet.add(date.year);
        kirans.add(
          KiranMapKiran(
            partNumber: (map['part'] as num?)?.toInt() ?? 0,
            kiranInfo: info,
            date: date,
          ),
        );
        for (final name in KiranMapSnapshot._villageNames(info)) {
          if (!byName.containsKey(name)) unmapped.add(name);
        }
      }

      kirans.sort(KiranMapSnapshot._compareKirans);
      final years = yearSet.toList()..sort();
      final unmappedNames = unmapped.toList()..sort();
      final trips = KiranMapSnapshot.buildTrips(
        kirans,
        (name) => byName[name.trim()],
      );

      _snapshot = KiranMapSnapshot(
        kirans: kirans,
        byName: byName,
        byId: byId,
        roads: roads,
        trips: trips,
        years: years,
        unmappedNames: unmappedNames,
      );
    } catch (error, stack) {
      debugPrint('KiranMapService.load failed: $error\n$stack');
      _snapshot = KiranMapSnapshot.empty;
    }
  }

  Future<Map<String, List<LatLng>>> _loadRoads() async {
    try {
      final raw = await rootBundle.loadString(
        'assets/book/saxatsavita/routes.json',
      );
      final json = jsonDecode(raw);
      if (json is! Map) return {};
      final roads = <String, List<LatLng>>{};
      for (final item in json['routes'] as List<dynamic>? ?? const []) {
        if (item is! Map) continue;
        final from = item['from']?.toString() ?? '';
        final to = item['to']?.toString() ?? '';
        final pathRaw = item['path'];
        if (from.isEmpty || to.isEmpty || pathRaw is! List) continue;
        final path = <LatLng>[];
        for (final point in pathRaw) {
          if (point is! List || point.length < 2) continue;
          final lat = (point[0] as num?)?.toDouble();
          final lng = (point[1] as num?)?.toDouble();
          if (lat == null || lng == null) continue;
          path.add(LatLng(lat, lng));
        }
        if (path.length >= 2) roads['$from>$to'] = path;
      }
      return roads;
    } catch (_) {
      return {};
    }
  }
}
