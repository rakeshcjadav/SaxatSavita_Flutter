import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';

AppBar buildAppBar(BuildContext context, {String title = ''}) {
  return AppBar(
    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    title: Text(
      title.isEmpty ? AppLocalizations.of(context)!.sakshatSavita : title,
    ),
    surfaceTintColor: Colors.transparent,
    elevation: 20,
    actions: [
      IconButton(
        icon: const Icon(Icons.info, size: 24),
        tooltip: AppLocalizations.of(context)!.menu_three,
        onPressed: () {
          Navigator.pushNamed(context, '/info');
        },
      ),
      IconButton(
        icon: const Icon(Icons.search, size: 24),
        tooltip: AppLocalizations.of(context)!.menu_five,
        onPressed: () {},
      ),
    ],
  );
}
