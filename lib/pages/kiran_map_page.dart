import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/helpers/open_kiran.dart';
import 'package:saxatsavita_flutter/helpers/open_kiran_map.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/services/analytics_service.dart';
import 'package:saxatsavita_flutter/services/kiran_map_service.dart';
import 'package:saxatsavita_flutter/services/utils.dart';
import 'package:saxatsavita_flutter/widgets/kiran_place_line.dart';

class KiranMapPage extends StatefulWidget {
  const KiranMapPage({super.key, this.village, this.kiranIndex, this.year});

  final String? village;
  final int? kiranIndex;
  final int? year;

  factory KiranMapPage.fromRoute(RouteSettings settings) {
    final args = settings.arguments;
    if (args is KiranMapArgs) {
      return KiranMapPage(
        village: args.village,
        kiranIndex: args.kiranIndex,
        year: args.year,
      );
    }
    return const KiranMapPage();
  }

  @override
  State<KiranMapPage> createState() => _KiranMapPageState();
}

class _KiranMapPageState extends State<KiranMapPage> {
  static const _saurashtraCenter = LatLng(21.52, 70.46);
  static const _labelMinZoom = 10.0;
  static const _inboundColorLight = Color(0xFFD84315);
  static const _inboundColorDark = Color(0xFFFF8A65);
  static const _homeColorLight = Color(0xFF2E7D32);
  static const _homeColorDark = Color(0xFF81C784);

  static final _northUpInteraction = InteractionOptions(
    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
    cursorKeyboardRotationOptions: CursorKeyboardRotationOptions.disabled(),
  );

  final KiranMapService _service = KiranMapService();
  final MapController _mapController = MapController();

  bool _loading = true;
  bool _mapReady = false;
  bool _didInitialFocus = false;
  bool _didOpenVillageSheet = false;
  bool _showPinLabels = false;
  int? _selectedYear;
  int? _selectedTripNumber;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'kiran_map_page');
    _selectedYear = widget.year;
    _load();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    await _service.load();
    if (!mounted) return;

    if (widget.kiranIndex != null) {
      final kiran = _service.snapshot.kiranForIndex(widget.kiranIndex!);
      if (kiran != null) {
        _selectedYear = kiran.date.year;
      }
      for (final trip in _service.snapshot.trips) {
        if (trip.containsKiran(widget.kiranIndex!)) {
          _selectedTripNumber = trip.number;
          break;
        }
      }
    }

    setState(() => _loading = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fitVisible(preferVillage: true);
      _openInitialVillageSheet();
    });
  }

  List<KiranVicharanTrip> get _visibleTrips =>
      _service.snapshot.tripsFor(year: _selectedYear);

  KiranVicharanTrip? get _selectedTrip =>
      _selectedTripNumber == null
          ? null
          : _service.snapshot.tripForNumber(_selectedTripNumber!);

  List<KiranMapPin> get _visiblePins {
    final snapshot = _service.snapshot;
    var pins = snapshot.pinsFor(year: _selectedYear);
    final trip = _selectedTrip;
    if (_selectedYear == null) {
      final villagePlace =
          widget.village == null ? null : snapshot.resolve(widget.village!);
      pins =
          pins.where((pin) {
            if (pin.place.isSaurashtra) return true;
            if (snapshot.isHome(pin.place)) return true;
            if (villagePlace != null && pin.place.id == villagePlace.id) {
              return true;
            }
            if (trip != null &&
                trip.stops.any((stop) => stop.id == pin.place.id)) {
              return true;
            }
            return false;
          }).toList();
    }

    final village = widget.village;
    if (village != null && village.isNotEmpty) {
      final place = snapshot.resolve(village);
      if (place != null && !pins.any((pin) => pin.place.id == place.id)) {
        pins = [
          ...pins,
          ...snapshot.pinsFor().where((pin) => pin.place.id == place.id),
        ];
      }
    }
    if (trip != null) {
      final extras = snapshot.pinsFor().where(
        (pin) =>
            trip.stops.any((stop) => stop.id == pin.place.id) &&
            !pins.any((existing) => existing.place.id == pin.place.id),
      );
      pins = [...pins, ...extras];
    }
    return pins;
  }

  KiranMapPin? _pinForVillage(String? village) {
    if (village == null || village.isEmpty) return null;
    final place = _service.snapshot.resolve(village);
    if (place == null) return null;
    for (final pin in _visiblePins) {
      if (pin.place.id == place.id) return pin;
    }
    for (final pin in _service.snapshot.pinsFor()) {
      if (pin.place.id == place.id) return pin;
    }
    return null;
  }

  void _setYear(int? year) {
    setState(() {
      _selectedYear = year;
      if (_selectedTripNumber != null &&
          !_visibleTrips.any((trip) => trip.number == _selectedTripNumber)) {
        _selectedTripNumber = null;
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitVisible());
  }

  void _selectTrip(int? number) {
    setState(() => _selectedTripNumber = number);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitVisible());
  }

  void _keepNorthUp(MapCamera camera) {
    if (camera.rotation.abs() > 0.01) {
      _mapController.rotate(0);
    }
  }

  void _fitVisible({bool preferVillage = false}) {
    if (!_mapReady || !mounted) return;
    final pins = _visiblePins;
    if (pins.isEmpty) return;

    if (preferVillage && !_didInitialFocus) {
      final villagePin = _pinForVillage(widget.village);
      if (villagePin != null) {
        _didInitialFocus = true;
        _mapController.move(
          LatLng(villagePin.place.lat, villagePin.place.lng),
          13,
        );
        return;
      }
      if (widget.kiranIndex != null) {
        final sitting = _service.snapshot.sittingPaths(
          kiranIndex: widget.kiranIndex,
        );
        final coords = sitting.expand((path) => path).toList();
        if (coords.length > 1) {
          _didInitialFocus = true;
          _mapController.fitCamera(
            CameraFit.coordinates(
              coordinates: coords,
              padding: const EdgeInsets.all(64),
              maxZoom: 12,
            ),
          );
          return;
        }
        if (coords.length == 1) {
          _didInitialFocus = true;
          _mapController.move(coords.first, 12);
          return;
        }
      }
    }
    _didInitialFocus = true;

    final trip = _selectedTrip;
    final coords = [
      if (trip != null)
        for (final stop in trip.stops) LatLng(stop.lat, stop.lng)
      else
        for (final pin in pins) LatLng(pin.place.lat, pin.place.lng),
    ];
    if (coords.isEmpty) return;
    if (coords.length == 1) {
      _mapController.move(coords.first, 12);
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: coords,
        padding: const EdgeInsets.all(56),
        maxZoom: trip == null ? 11 : 12,
      ),
    );
  }

  void _openInitialVillageSheet() {
    if (_didOpenVillageSheet || !mounted) return;
    final village = widget.village;
    if (village == null || village.isEmpty) return;
    _didOpenVillageSheet = true;

    final pin = _pinForVillage(village);
    if (pin == null) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.kiran_map_unmapped)));
      return;
    }
    _openPinSheet(pin);
  }

  Future<void> _openPinSheet(KiranMapPin pin) async {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.5,
          minChildSize: 0.3,
          maxChildSize: 0.92,
          builder: (context, scrollController) {
            return Column(
              children: [
                ListTile(
                  title: Text(
                    _isHome(pin)
                        ? l10n.kiran_map_home
                        : l10n.kiran_map_kirans_at(pin.place.displayName),
                  ),
                  subtitle: Text(l10n.kiran_map_kiran_count(pin.kiranCount)),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: pin.kirans.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final kiran = pin.kirans[index];
                      final partAccent = Utils.getPartAccentColor(
                        kiran.partNumber,
                        context,
                      );
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        leading: Text(
                          kiran.kiranInfo.number.replaceAll('.', ''),
                          style: TextStyle(
                            fontSize: 22,
                            color: partAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        title: Text(
                          kiran.kiranInfo.title,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              DateFormat('d MMM yyyy').format(kiran.date),
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(color: colorScheme.outline),
                            ),
                            KiranPlaceLine(
                              kiranInfo: kiran.kiranInfo,
                              enableMapTap: false,
                            ),
                          ],
                        ),
                        onTap: () async {
                          Navigator.pop(sheetContext);
                          if (!this.context.mounted) return;
                          await openKiran(
                            this.context,
                            kiranIndex: kiran.kiranInfo.index,
                            partNumber: kiran.partNumber,
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: buildAppBar(context, title: l10n.kiran_map),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _YearChips(
                    years: _service.snapshot.years,
                    selectedYear: _selectedYear,
                    allYearsLabel: l10n.kiran_map_all_years,
                    onSelected: _setYear,
                  ),
                  Expanded(flex: 5, child: _buildMap(context, l10n)),
                  Expanded(
                    flex: 3,
                    child: _VicharanList(
                      trips: _visibleTrips,
                      selectedTripNumber: _selectedTripNumber,
                      onSelected: _selectTrip,
                    ),
                  ),
                ],
              ),
    );
  }

  Widget _buildMap(BuildContext context, AppLocalizations l10n) {
    final colorScheme = Theme.of(context).colorScheme;
    final snapshot = _service.snapshot;
    final pins = _visiblePins;
    final routeLines = snapshot.vicharanRouteLines(
      year: _selectedYear,
      tripNumber: _selectedTripNumber,
    );
    final sitting =
        _selectedYear == null
            ? const <List<LatLng>>[]
            : snapshot.sittingPaths(year: _selectedYear);
    final highlight =
        _selectedYear == null || widget.kiranIndex == null
            ? const <List<LatLng>>[]
            : snapshot.sittingPaths(kiranIndex: widget.kiranIndex);
    final otherPins = pins.where((pin) => !_isHome(pin)).toList();
    final homePins = pins.where(_isHome).toList();

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: _saurashtraCenter,
            initialZoom: 9,
            initialRotation: 0,
            interactionOptions: _northUpInteraction,
            onMapReady: () {
              _mapReady = true;
              _keepNorthUp(_mapController.camera);
              _syncPinLabels(_mapController.camera.zoom);
              _fitVisible(preferVillage: true);
            },
            onPositionChanged: (camera, _) {
              _keepNorthUp(camera);
              _syncPinLabels(camera.zoom);
            },
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.farenidham.books.saxatsavita.app',
            ),
            if (routeLines.isNotEmpty)
              PolylineLayer(
                polylines: [
                  for (final line in routeLines)
                    if (line.points.length > 1)
                      Polyline(
                        points: line.points,
                        color: _routeColor(
                          line.kind,
                          colorScheme,
                        ).withValues(alpha: 0.88),
                        strokeWidth: 4,
                        borderStrokeWidth: 1.5,
                        borderColor: colorScheme.surface.withValues(alpha: 0.7),
                        strokeCap: StrokeCap.round,
                        strokeJoin: StrokeJoin.round,
                      ),
                ],
              ),
            if (sitting.isNotEmpty)
              PolylineLayer(
                polylines: [
                  for (final points in sitting)
                    Polyline(
                      points: points,
                      color: colorScheme.outline.withValues(alpha: 0.55),
                      strokeWidth: 2.5,
                      borderStrokeWidth: 1,
                      borderColor: colorScheme.surface.withValues(alpha: 0.45),
                    ),
                ],
              ),
            if (highlight.isNotEmpty)
              PolylineLayer(
                polylines: [
                  for (final points in highlight)
                    Polyline(
                      points: points,
                      color: colorScheme.secondary,
                      strokeWidth: 5.5,
                      borderStrokeWidth: 1.5,
                      borderColor: colorScheme.surface.withValues(alpha: 0.7),
                    ),
                ],
              ),
            if (routeLines.any((line) => line.arrows.isNotEmpty))
              MarkerLayer(
                rotate: false,
                markers: [
                  for (final line in routeLines)
                    for (final arrow in line.arrows)
                      _arrowMarker(arrow, _routeColor(line.kind, colorScheme)),
                ],
              ),
            MarkerLayer(
              rotate: false,
              markers: [
                for (final pin in otherPins) _pinIconMarker(pin, colorScheme),
                for (final pin in homePins) _pinIconMarker(pin, colorScheme),
              ],
            ),
            MarkerLayer(
              rotate: false,
              markers: [
                for (final pin in otherPins)
                  if (_showName(pin) || pin.kiranCount > 0)
                    _pinCaptionMarker(pin, colorScheme),
                for (final pin in homePins) _pinCaptionMarker(pin, colorScheme),
              ],
            ),
            RichAttributionWidget(
              attributions: [
                TextSourceAttribution(l10n.kiran_map_osm_attribution),
              ],
            ),
          ],
        ),
        if (pins.isEmpty)
          Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Text(l10n.kiran_map_empty),
              ),
            ),
          ),
        Positioned(
          top: 8,
          left: 8,
          child: _MapLegend(
            homeColor: _homeColor(colorScheme),
            outboundColor: _routeColor(KiranRouteKind.outbound, colorScheme),
            inboundColor: _routeColor(KiranRouteKind.inbound, colorScheme),
          ),
        ),
      ],
    );
  }

  Color _routeColor(KiranRouteKind kind, ColorScheme colorScheme) {
    if (kind == KiranRouteKind.outbound) return colorScheme.primary;
    return colorScheme.brightness == Brightness.dark
        ? _inboundColorDark
        : _inboundColorLight;
  }

  Color _homeColor(ColorScheme colorScheme) {
    return colorScheme.brightness == Brightness.dark
        ? _homeColorDark
        : _homeColorLight;
  }

  Color _pinColor(KiranMapPin pin, ColorScheme colorScheme) {
    if (_isHome(pin)) return _homeColor(colorScheme);
    if (_isFocused(pin)) return colorScheme.secondary;
    return colorScheme.primary;
  }

  Marker _arrowMarker(KiranRouteArrow arrow, Color color) {
    return Marker(
      point: arrow.point,
      width: 22,
      height: 22,
      alignment: Alignment.center,
      rotate: false,
      child: IgnorePointer(
        child: Transform.rotate(
          angle: arrow.bearingDegrees * math.pi / 180,
          child: Icon(
            Icons.navigation,
            size: 18,
            color: color,
            shadows: const [Shadow(color: Color(0xCCFFFFFF), blurRadius: 3)],
          ),
        ),
      ),
    );
  }

  void _syncPinLabels(double zoom) {
    final show = zoom >= _labelMinZoom;
    if (show == _showPinLabels) return;
    setState(() => _showPinLabels = show);
  }

  bool _isHome(KiranMapPin pin) => pin.place.id == KiranMapSnapshot.homePlaceId;

  bool _isFocused(KiranMapPin pin) =>
      widget.village != null && pin.place.matches(widget.village!);

  bool _showName(KiranMapPin pin) =>
      _isFocused(pin) || _isHome(pin) || _showPinLabels;

  double _pinIconSize(KiranMapPin pin) =>
      _isHome(pin) || _isFocused(pin) ? 34 : 32;

  Widget? _pinCaption(KiranMapPin pin, ColorScheme colorScheme) {
    final focused = _isFocused(pin);
    final color = _pinColor(pin, colorScheme);
    if (_showName(pin)) {
      return Container(
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: colorScheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Text(
          pin.place.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight:
                focused || _isHome(pin) ? FontWeight.w800 : FontWeight.w600,
            height: 1.15,
            color: colorScheme.onSurface,
          ),
        ),
      );
    }
    if (pin.kiranCount <= 0) return null;
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        Utils.toGujaratiNumerals('${pin.kiranCount}'),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: color,
          height: 1.1,
        ),
      ),
    );
  }

  Marker _pinIconMarker(KiranMapPin pin, ColorScheme colorScheme) {
    final color = _pinColor(pin, colorScheme);
    final size = _pinIconSize(pin);
    return Marker(
      point: LatLng(pin.place.lat, pin.place.lng),
      width: size,
      height: size,
      alignment: Alignment.bottomCenter,
      rotate: false,
      child: GestureDetector(
        onTap: () => _openPinSheet(pin),
        child: Icon(
          _isHome(pin) ? Icons.home : Icons.location_on,
          color: color,
          size: size,
        ),
      ),
    );
  }

  Marker _pinCaptionMarker(KiranMapPin pin, ColorScheme colorScheme) {
    final caption = _pinCaption(pin, colorScheme);
    final iconSize = _pinIconSize(pin);
    final showName = _showName(pin);
    return Marker(
      point: LatLng(pin.place.lat, pin.place.lng),
      width: showName ? 128 : 44,
      height: showName ? iconSize + 24 : iconSize + 18,
      alignment: Alignment.bottomCenter,
      rotate: false,
      child: GestureDetector(
        onTap: () => _openPinSheet(pin),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [if (caption != null) caption, SizedBox(height: iconSize)],
        ),
      ),
    );
  }
}

class _MapLegend extends StatelessWidget {
  const _MapLegend({
    required this.homeColor,
    required this.outboundColor,
    required this.inboundColor,
  });

  final Color homeColor;
  final Color outboundColor;
  final Color inboundColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 2,
      color: colorScheme.surface.withValues(alpha: 0.94),
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _LegendRow(
              icon: Icons.home,
              color: homeColor,
              label: l10n.kiran_map_home,
            ),
            const SizedBox(height: 4),
            _LegendRow(
              icon: Icons.north_east,
              color: outboundColor,
              label: l10n.kiran_map_outbound,
            ),
            const SizedBox(height: 4),
            _LegendRow(
              icon: Icons.south_west,
              color: inboundColor,
              label: l10n.kiran_map_inbound,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}

class _VicharanList extends StatelessWidget {
  const _VicharanList({
    required this.trips,
    required this.selectedTripNumber,
    required this.onSelected,
  });

  final List<KiranVicharanTrip> trips;
  final int? selectedTripNumber;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      elevation: 6,
      color: colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
            child: Text(
              '${l10n.kiran_map_vicharans} · ${Utils.toGujaratiNumerals('${trips.length}')}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: trips.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return ListTile(
                    dense: true,
                    selected: selectedTripNumber == null,
                    leading: Icon(
                      Icons.route,
                      color:
                          selectedTripNumber == null
                              ? colorScheme.primary
                              : colorScheme.outline,
                    ),
                    title: Text(l10n.kiran_map_all_vicharans),
                    onTap: () => onSelected(null),
                  );
                }
                final trip = trips[index - 1];
                final selected = selectedTripNumber == trip.number;
                return ListTile(
                  dense: true,
                  selected: selected,
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor:
                        selected
                            ? colorScheme.primary
                            : colorScheme.secondaryContainer,
                    foregroundColor:
                        selected
                            ? colorScheme.onPrimary
                            : colorScheme.onSecondaryContainer,
                    child: Text(
                      Utils.toGujaratiNumerals('${trip.number}'),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  title: Text(l10n.kiran_map_vicharan_n(trip.number)),
                  subtitle: Text(
                    [
                      _tripDates(trip),
                      _compactRoute(trip),
                      l10n.kiran_map_kiran_count(trip.kirans.length),
                      if (!trip.returnsHome) l10n.kiran_map_open_ended,
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: Icon(
                    Icons.chevron_right,
                    color: colorScheme.outline,
                  ),
                  onTap: () {
                    onSelected(trip.number);
                    openKiranVicharan(context, tripNumber: trip.number);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _tripDates(KiranVicharanTrip trip) {
    final fmt = DateFormat('d MMM yyyy');
    if (trip.start.year == trip.end.year &&
        trip.start.month == trip.end.month &&
        trip.start.day == trip.end.day) {
      return fmt.format(trip.start);
    }
    return '${fmt.format(trip.start)} – ${fmt.format(trip.end)}';
  }

  String _compactRoute(KiranVicharanTrip trip) {
    if (trip.stops.length <= 4) return trip.routeSummary;
    return '${trip.stops.first.displayName} → … → ${trip.stops.last.displayName}';
  }
}

class _YearChips extends StatelessWidget {
  const _YearChips({
    required this.years,
    required this.selectedYear,
    required this.allYearsLabel,
    required this.onSelected,
  });

  final List<int> years;
  final int? selectedYear;
  final String allYearsLabel;
  final ValueChanged<int?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              visualDensity: VisualDensity.compact,
              selected: selectedYear == null,
              label: Text(allYearsLabel),
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final year in years)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                visualDensity: VisualDensity.compact,
                selected: selectedYear == year,
                label: Text(Utils.toGujaratiNumerals('$year')),
                onSelected: (selected) => onSelected(selected ? year : null),
              ),
            ),
        ],
      ),
    );
  }
}
