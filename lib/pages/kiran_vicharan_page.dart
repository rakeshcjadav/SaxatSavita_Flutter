import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/helpers/open_kiran.dart';
import 'package:saxatsavita_flutter/helpers/open_kiran_map.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/place_geo_model.dart';
import 'package:saxatsavita_flutter/services/analytics_service.dart';
import 'package:saxatsavita_flutter/services/kiran_map_service.dart';
import 'package:saxatsavita_flutter/services/utils.dart';
import 'package:saxatsavita_flutter/widgets/kiran_place_line.dart';

class KiranVicharanPage extends StatefulWidget {
  const KiranVicharanPage({super.key, required this.tripNumber});

  final int tripNumber;

  factory KiranVicharanPage.fromRoute(RouteSettings settings) {
    final args = settings.arguments;
    if (args is KiranVicharanArgs) {
      return KiranVicharanPage(tripNumber: args.tripNumber);
    }
    if (args is int) {
      return KiranVicharanPage(tripNumber: args);
    }
    return const KiranVicharanPage(tripNumber: 0);
  }

  @override
  State<KiranVicharanPage> createState() => _KiranVicharanPageState();
}

class _KiranVicharanPageState extends State<KiranVicharanPage> {
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
  KiranVicharanTrip? _trip;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'kiran_vicharan_page');
    _load();
  }

  @override
  void dispose() {
    _mapReady = false;
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      await _service.load();
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _trip = _service.snapshot.tripForNumber(widget.tripNumber);
      _loading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitTrip());
  }

  void _keepNorthUp(MapCamera camera) {
    if (!mounted || !_mapReady) return;
    if (camera.rotation.abs() > 0.01) {
      _mapController.rotate(0);
    }
  }

  void _fitTrip() {
    final trip = _trip;
    if (!_mapReady || !mounted || trip == null || trip.stops.isEmpty) return;
    final coords = [for (final stop in trip.stops) LatLng(stop.lat, stop.lng)];
    if (coords.length == 1) {
      _mapController.move(coords.first, 12);
      return;
    }
    _mapController.fitCamera(
      CameraFit.coordinates(
        coordinates: coords,
        padding: const EdgeInsets.all(40),
        maxZoom: 12,
      ),
    );
  }

  Future<void> _openKiran(KiranMapKiran kiran) async {
    if (!mounted) return;
    await openKiran(
      context,
      kiranIndex: kiran.kiranInfo.index,
      partNumber: kiran.partNumber,
    );
  }

  Future<void> _openStopKirans(PlaceGeo stop) async {
    final trip = _trip;
    if (trip == null) return;
    final kirans = trip.kiransAt(stop);
    if (kirans.isEmpty) return;

    final l10n = AppLocalizations.of(context)!;
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
                  title: Text(l10n.kiran_map_kirans_at(stop.displayName)),
                  subtitle: Text(l10n.kiran_map_kiran_count(kirans.length)),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.separated(
                    controller: scrollController,
                    itemCount: kirans.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      return _TripKiranTile(
                        kiran: kirans[index],
                        onTap: () {
                          Navigator.pop(sheetContext);
                          _openKiran(kirans[index]);
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
    final trip = _trip;
    return Scaffold(
      appBar: buildAppBar(
        context,
        title:
            trip == null
                ? l10n.kiran_map_vicharan
                : l10n.kiran_map_vicharan_n(trip.number),
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : trip == null
              ? Center(child: Text(l10n.kiran_map_vicharan_missing))
              : Column(
                children: [
                  SizedBox(
                    height: 220,
                    child:
                        trip.stops.isEmpty
                            ? const SizedBox.shrink()
                            : _buildMap(context, l10n, trip),
                  ),
                  Expanded(child: _buildDetails(context, l10n, trip)),
                ],
              ),
    );
  }

  Widget _buildMap(
    BuildContext context,
    AppLocalizations l10n,
    KiranVicharanTrip trip,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final routeLines = _service.snapshot.vicharanRouteLines(
      tripNumber: trip.number,
    );
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: LatLng(trip.stops.first.lat, trip.stops.first.lng),
        initialZoom: 10,
        initialRotation: 0,
        interactionOptions: _northUpInteraction,
        onMapReady: () {
          if (!mounted) return;
          _mapReady = true;
          _keepNorthUp(_mapController.camera);
          _fitTrip();
        },
        onPositionChanged: (camera, _) {
          if (!mounted) return;
          _keepNorthUp(camera);
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
        if (routeLines.any((line) => line.arrows.isNotEmpty))
          MarkerLayer(
            rotate: false,
            markers: [
              for (final line in routeLines)
                for (final arrow in line.arrows)
                  Marker(
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
                          color: _routeColor(line.kind, colorScheme),
                          shadows: const [
                            Shadow(color: Color(0xCCFFFFFF), blurRadius: 3),
                          ],
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        MarkerLayer(
          rotate: false,
          markers: [
            for (final stop in trip.stops)
              Marker(
                point: LatLng(stop.lat, stop.lng),
                width: 32,
                height: 32,
                alignment: Alignment.bottomCenter,
                rotate: false,
                child: GestureDetector(
                  onTap: () => _openStopKirans(stop),
                  child: Icon(
                    _isHome(stop) ? Icons.home : Icons.location_on,
                    color: _stopColor(stop, colorScheme),
                    size: 32,
                  ),
                ),
              ),
          ],
        ),
        MarkerLayer(
          rotate: false,
          markers: [
            for (final stop in trip.stops)
              Marker(
                point: LatLng(stop.lat, stop.lng),
                width: 128,
                height: 56,
                alignment: Alignment.bottomCenter,
                rotate: false,
                child: GestureDetector(
                  onTap: () => _openStopKirans(stop),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.94),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: _stopColor(
                              stop,
                              colorScheme,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          stop.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight:
                                _isHome(stop)
                                    ? FontWeight.w800
                                    : FontWeight.w600,
                            height: 1.15,
                            color: colorScheme.onSurface,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
          ],
        ),
        RichAttributionWidget(
          attributions: [TextSourceAttribution(l10n.kiran_map_osm_attribution)],
        ),
      ],
    );
  }

  Widget _buildDetails(
    BuildContext context,
    AppLocalizations l10n,
    KiranVicharanTrip trip,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _tripDates(trip),
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                trip.routeSummary,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.place_outlined, size: 16),
                    label: Text(l10n.kiran_map_place_count(trip.stops.length)),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: const Icon(Icons.menu_book_outlined, size: 16),
                    label: Text(l10n.kiran_map_kiran_count(trip.kirans.length)),
                  ),
                  Chip(
                    visualDensity: VisualDensity.compact,
                    avatar: Icon(
                      trip.returnsHome
                          ? Icons.home_outlined
                          : Icons.flag_outlined,
                      size: 16,
                    ),
                    label: Text(
                      trip.returnsHome
                          ? l10n.kiran_map_returned_home
                          : l10n.kiran_map_open_ended,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        _SectionHeader(
          icon: Icons.route,
          label:
              '${l10n.kiran_map_locations} · ${Utils.toGujaratiNumerals('${trip.stops.length}')}',
        ),
        for (var i = 0; i < trip.stops.length; i++)
          _StopTile(
            index: i + 1,
            stop: trip.stops[i],
            isHome: _isHome(trip.stops[i]),
            kiranCount: trip.kiransAt(trip.stops[i]).length,
            showConnector: i < trip.stops.length - 1,
            onTap: () => _openStopKirans(trip.stops[i]),
          ),
        _SectionHeader(
          icon: Icons.menu_book_outlined,
          label:
              '${l10n.kiran_map_kirans} · ${Utils.toGujaratiNumerals('${trip.kirans.length}')}',
        ),
        for (var i = 0; i < trip.kirans.length; i++) ...[
          _TripKiranTile(
            kiran: trip.kirans[i],
            onTap: () => _openKiran(trip.kirans[i]),
          ),
          if (i < trip.kirans.length - 1) const Divider(height: 1),
        ],
        const SizedBox(height: 24),
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

  bool _isHome(PlaceGeo place) => place.id == KiranMapSnapshot.homePlaceId;

  Color _stopColor(PlaceGeo stop, ColorScheme colorScheme) {
    if (_isHome(stop)) return _homeColor(colorScheme);
    return colorScheme.primary;
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
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colorScheme.primary),
          const SizedBox(width: 8),
          Text(label, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _StopTile extends StatelessWidget {
  const _StopTile({
    required this.index,
    required this.stop,
    required this.isHome,
    required this.kiranCount,
    required this.showConnector,
    required this.onTap,
  });

  final int index;
  final PlaceGeo stop;
  final bool isHome;
  final int kiranCount;
  final bool showConnector;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final subtitleParts = [
      if (isHome) l10n.kiran_map_home,
      if (stop.district.isNotEmpty) stop.district,
      if (kiranCount > 0) l10n.kiran_map_kiran_count(kiranCount),
    ];
    return InkWell(
      onTap: kiranCount > 0 ? onTap : null,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor:
                        isHome
                            ? colorScheme.tertiaryContainer
                            : colorScheme.secondaryContainer,
                    foregroundColor:
                        isHome
                            ? colorScheme.onTertiaryContainer
                            : colorScheme.onSecondaryContainer,
                    child: Text(
                      Utils.toGujaratiNumerals('$index'),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (showConnector)
                    Container(
                      width: 2,
                      height: 28,
                      margin: const EdgeInsets.only(top: 2),
                      color: colorScheme.outlineVariant,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (isHome) ...[
                          Icon(
                            Icons.home,
                            size: 16,
                            color: colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Expanded(
                          child: Text(
                            stop.displayName,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (kiranCount > 0)
                          Icon(
                            Icons.chevron_right,
                            size: 18,
                            color: colorScheme.outline,
                          ),
                      ],
                    ),
                    if (subtitleParts.isNotEmpty)
                      Text(
                        subtitleParts.join(' · '),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.outline,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripKiranTile extends StatelessWidget {
  const _TripKiranTile({required this.kiran, required this.onTap});

  final KiranMapKiran kiran;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final partAccent = Utils.getPartAccentColor(kiran.partNumber, context);
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('d MMM yyyy').format(kiran.date),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colorScheme.outline),
          ),
          KiranPlaceLine(kiranInfo: kiran.kiranInfo, enableMapTap: false),
        ],
      ),
      trailing: Icon(Icons.chevron_right, size: 18, color: colorScheme.outline),
      onTap: onTap,
    );
  }
}
