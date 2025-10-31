import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';

enum ActionOptions {
  info,
  settings,
  notes,
  search,
  favorite,
  aashirvachan,
  preface,
}

AppBar buildAppBar(
  BuildContext context, {
  String title = '',
  List<ActionOptions>? actionItems,
  List<Widget>? extraActions,
  PreferredSizeWidget? bottom,
  VoidCallback? onSettingsPressed,
}) {
  return AppBar(
    title: Text(
      title.isEmpty ? AppLocalizations.of(context)!.sakshatSavita : title,
    ),
    elevation: 5,
    actions: [
      if (actionItems?.contains(ActionOptions.aashirvachan) ?? false)
        IconButton(
          icon: const Icon(Icons.volunteer_activism),
          tooltip: AppLocalizations.of(context)!.aashirvachan,
          onPressed: () {
            Navigator.pushNamed(context, '/aashirvachan');
          },
        ),
      if (actionItems?.contains(ActionOptions.preface) ?? false)
        IconButton(
          icon: const Icon(Icons.book),
          tooltip: AppLocalizations.of(context)!.preface,
          onPressed: () {
            Navigator.pushNamed(context, '/preface');
          },
        ),
      if (actionItems?.contains(ActionOptions.info) ?? false)
        IconButton(
          icon: const Icon(Icons.info),
          tooltip: AppLocalizations.of(context)!.information_section,
          onPressed: () {
            Navigator.pushNamed(context, '/info');
          },
        ),
      if (actionItems?.contains(ActionOptions.notes) ?? false)
        IconButton(
          icon: const Icon(Icons.note),
          tooltip: AppLocalizations.of(context)!.notes,
          onPressed: () {
            Navigator.pushNamed(context, '/notes');
          },
        ),
      if (actionItems?.contains(ActionOptions.search) ?? false)
        IconButton(
          icon: const Icon(Icons.search),
          tooltip: AppLocalizations.of(context)!.search_all_kiranas,
          onPressed: () {
            Navigator.pushNamed(context, '/search');
          },
        ),
      if (extraActions != null) ...extraActions,
      if (actionItems?.contains(ActionOptions.settings) ?? false)
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: AppLocalizations.of(context)!.settings,
          onPressed: () {
            onSettingsPressed != null
                ? onSettingsPressed()
                : Navigator.pushNamed(context, '/settings');
          },
        ),
    ],
    bottom: bottom,
  );
}
