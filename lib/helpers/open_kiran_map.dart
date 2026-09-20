import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/services/remote_config_service.dart';

class KiranMapArgs {
  final String? village;
  final int? kiranIndex;
  final int? year;

  const KiranMapArgs({this.village, this.kiranIndex, this.year});
}

class KiranVicharanArgs {
  final int tripNumber;

  const KiranVicharanArgs({required this.tripNumber});
}

Future<void> openKiranMap(
  BuildContext context, {
  String? village,
  int? kiranIndex,
  int? year,
}) {
  return Navigator.of(context).pushNamed(
    '/kiran-map',
    arguments: KiranMapArgs(
      village: village,
      kiranIndex: kiranIndex,
      year: year,
    ),
  );
}

Future<void> openKiranVicharan(
  BuildContext context, {
  required int tripNumber,
}) {
  return Navigator.of(context).pushNamed(
    '/kiran-vicharan',
    arguments: KiranVicharanArgs(tripNumber: tripNumber),
  );
}

List<Widget> kiranMapAppBarActions(
  BuildContext context, {
  String? village,
  int? year,
}) {
  if (!RemoteConfigService().enableKiranMap) return const [];
  final l10n = AppLocalizations.of(context)!;
  return [
    IconButton(
      icon: const Icon(Icons.map_outlined),
      tooltip: l10n.kiran_map,
      onPressed: () => openKiranMap(context, village: village, year: year),
    ),
  ];
}
