import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/place_geo_model.dart';
import 'package:saxatsavita_flutter/services/kiran_map_service.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

KiranMapSnapshot loadSnapshotFromAssets() {
  final kiransJson =
      jsonDecode(
            File(
              'assets/book/saxatsavita/_all_kirans_.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  final placesJson =
      jsonDecode(File('assets/book/saxatsavita/places.json').readAsStringSync())
          as Map<String, dynamic>;
  final routesJson =
      jsonDecode(File('assets/book/saxatsavita/routes.json').readAsStringSync())
          as Map<String, dynamic>;

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

  final roads = <String, List<LatLng>>{};
  for (final item in routesJson['routes'] as List<dynamic>? ?? const []) {
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

  final kirans = <KiranMapKiran>[];
  for (final item in kiransJson['list'] as List<dynamic>? ?? const []) {
    if (item is! Map) continue;
    final map = Map<String, dynamic>.from(item);
    final info = KiranInfo.fromMap(map);
    final date = Utils.parseKiranDate(info.date);
    if (date == null) continue;
    kirans.add(
      KiranMapKiran(
        partNumber: (map['part'] as num?)?.toInt() ?? 0,
        kiranInfo: info,
        date: date,
      ),
    );
  }
  kirans.sort((a, b) {
    final byDate = a.date.compareTo(b.date);
    if (byDate != 0) return byDate;
    return a.kiranInfo.index.compareTo(b.kiranInfo.index);
  });

  final years = kirans.map((kiran) => kiran.date.year).toSet().toList()..sort();
  return KiranMapSnapshot(
    kirans: kirans,
    byName: byName,
    byId: byId,
    roads: roads,
    trips: KiranMapSnapshot.buildTrips(kirans, (name) => byName[name.trim()]),
    years: years,
    unmappedNames: const [],
  );
}

void main() {
  late KiranMapSnapshot snapshot;

  setUpAll(() {
    snapshot = loadSnapshotFromAssets();
  });

  test('loads places, trips, and years without empty geography', () {
    expect(snapshot.home, isNotNull);
    expect(snapshot.home!.id, KiranMapSnapshot.homePlaceId);
    expect(snapshot.trips, isNotEmpty);
    expect(snapshot.years, isNotEmpty);
    expect(snapshot.pinsFor(), isNotEmpty);
    expect(
      snapshot.pinsFor().any(
        (pin) => pin.place.id == KiranMapSnapshot.homePlaceId,
      ),
      isTrue,
    );
  });

  test('vicharan 1 uses the last home kiran before leaving', () {
    final trip = snapshot.tripForNumber(1);
    expect(trip, isNotNull);
    expect(trip!.kirans.map((kiran) => kiran.kiranInfo.index).toList(), [
      47,
      48,
      49,
    ]);
    expect(trip.stops.first.id, KiranMapSnapshot.homePlaceId);
    expect(trip.stops.last.id, KiranMapSnapshot.homePlaceId);
    expect(trip.returnsHome, isTrue);
  });

  test(
    'every trip has a route, two or more stops, and a previous home kiran',
    () {
      expect(snapshot.trips.length, 26);
      for (final trip in snapshot.trips) {
        expect(
          trip.stops.length,
          greaterThanOrEqualTo(2),
          reason: 'trip ${trip.number}',
        );
        expect(trip.kirans, isNotEmpty, reason: 'trip ${trip.number}');
        expect(
          trip.stops.first.id,
          KiranMapSnapshot.homePlaceId,
          reason: 'trip ${trip.number}',
        );
        expect(
          () => snapshot.vicharanRouteLines(tripNumber: trip.number),
          returnsNormally,
          reason: 'trip ${trip.number} route offset',
        );
        final lines = snapshot.vicharanRouteLines(tripNumber: trip.number);
        expect(lines, isNotEmpty, reason: 'trip ${trip.number}');
        for (final line in lines) {
          expect(line.points.length, greaterThanOrEqualTo(2));
          for (final point in line.points) {
            expect(point.latitude.isFinite, isTrue);
            expect(point.longitude.isFinite, isTrue);
          }
        }
      }
    },
  );

  test('all-years and year filters do not throw when drawing routes', () {
    expect(() => snapshot.vicharanRouteLines(), returnsNormally);
    expect(snapshot.vicharanRouteLines(), isNotEmpty);
    for (final year in snapshot.years) {
      expect(
        () => snapshot.vicharanRouteLines(year: year),
        returnsNormally,
        reason: '$year',
      );
      expect(
        () => snapshot.pinsFor(year: year),
        returnsNormally,
        reason: '$year',
      );
    }
  });
}
