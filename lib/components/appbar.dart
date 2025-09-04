import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

AppBar buildAppBar(BuildContext context) {
  return AppBar(
    backgroundColor: Theme.of(context).colorScheme.inversePrimary,
    title: Text(AppLocalizations.of(context)!.sakshatSavita),
    surfaceTintColor: Colors.transparent,
    elevation: 20,
    actions: [
      IconButton(
        icon: const Icon(Icons.info, size: 24),
        tooltip: AppLocalizations.of(context)!.menu_three,
        onPressed: () {},
      ),
      IconButton(
        icon: const Icon(Icons.search, size: 24),
        tooltip: AppLocalizations.of(context)!.menu_five,
        onPressed: () {},
      ),
    ],
  );
}
