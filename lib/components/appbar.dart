import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';

enum ActionOptions { info, settings, search, favorite, bookmark }

AppBar buildAppBar(
  BuildContext context, {
  String title = '',
  List<ActionOptions>? actionItems,
  List<Widget>? extraActions,
}) {
  return AppBar(
    title: Text(
      title.isEmpty ? AppLocalizations.of(context)!.sakshatSavita : title,
    ),
    elevation: 5,
    actions: [
      if (actionItems?.contains(ActionOptions.info) ?? false)
        IconButton(
          icon: const Icon(Icons.info),
          tooltip: AppLocalizations.of(context)!.information_section,
          onPressed: () {
            Navigator.pushNamed(context, '/info');
          },
        ),
      if (extraActions != null) ...extraActions,
      if (actionItems?.contains(ActionOptions.settings) ?? false)
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: AppLocalizations.of(context)!.settings,
          onPressed: () {
            Navigator.pushNamed(context, '/settings');
          },
        ),
    ],
  );
}
