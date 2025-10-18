import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';

class Navigationbar extends StatefulWidget {
  const Navigationbar({super.key});

  @override
  State<Navigationbar> createState() => NavigationbarState();
}

class NavigationbarState extends State<Navigationbar> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.edit_document),
          label: AppLocalizations.of(context)!.notes,
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: AppLocalizations.of(context)!.reading_history,
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor:
          Colors.amber[800], //Theme.of(context).colorScheme.primary,
      onTap: _onItemTapped,
    );
  }
}
