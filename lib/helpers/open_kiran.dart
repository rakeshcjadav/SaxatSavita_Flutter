import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/models/reading_event_model.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';
import 'package:saxatsavita_flutter/services/kiranuser_service.dart';

Future<void> openKiran(
  BuildContext context, {
  required int kiranIndex,
  int? partNumber,
}) async {
  final part = partNumber ?? Bookservice().partNumberForKiranIndex(kiranIndex);
  final listService = KiranListService();
  await listService.loadPart('saxatsavita', 'part$part');
  if (!context.mounted) return;

  final kiranInfo = listService.getKiranInfo(part, kiranIndex);
  if (kiranInfo.index == 0) return;

  final kiranUserInfo = KiranUserService().getKiranUserInfo(kiranIndex);
  await Navigator.of(context).push(
    MaterialPageRoute(
      builder:
          (_) => KiranReadPage(
            partNumber: 'part$part',
            kiranInfo: kiranInfo,
            kiranUserInfo: kiranUserInfo,
            readingMode: ReadingMode.reading,
          ),
    ),
  );
}
