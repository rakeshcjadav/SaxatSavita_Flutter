import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/components/drawer.dart';

// Import full pages (they will be rendered without their scaffold)
import 'package:saxatsavita_flutter/pages/dashboard_page.dart';
import 'package:saxatsavita_flutter/pages/homepage.dart';
import 'package:saxatsavita_flutter/pages/notelistpage.dart';
import 'package:saxatsavita_flutter/pages/reading_history_page.dart';
import 'package:saxatsavita_flutter/pages/profile_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  String _getAppBarTitle() {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return AppLocalizations.of(context)!.sakshatSavita;
      case 2:
        return AppLocalizations.of(context)!.notes;
      case 3:
        return AppLocalizations.of(context)!.reading_history;
      case 4:
        return AppLocalizations.of(context)!.profile;
      default:
        return 'Dashboard';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer:
          _selectedIndex == 1
              ? MyDrawer(
                items: [
                  DrawerItem.aashirvachan,
                  DrawerItem.notes,
                  DrawerItem.search,
                  DrawerItem.readingPlans,
                  DrawerItem.readingHistory,
                  DrawerItem.quotesImageGenerator,
                  DrawerItem.profile,
                  DrawerItem.welcomeTour,
                  DrawerItem.marketingShowcase,
                  DrawerItem.migration,
                  DrawerItem.adminpanel,
                  DrawerItem.logout,
                ],
              )
              : null,
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        physics:
            const NeverScrollableScrollPhysics(), // Disable swipe navigation
        children: const [
          _DashboardPageContent(),
          _HomePageContent(),
          _NoteListPageContent(),
          _ReadingHistoryPageContent(),
          _ProfilePageContent(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppLocalizations.of(context)!.sakshatSavita,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.edit_note),
            label: AppLocalizations.of(context)!.notes,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.history),
            label: AppLocalizations.of(context)!.reading_history,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppLocalizations.of(context)!.profile,
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        selectedFontSize: 12,
        unselectedFontSize: 12,
      ),
    );
  }
}

// Content-only wrapper widgets (just the body, no Scaffold)
class _DashboardPageContent extends StatelessWidget {
  const _DashboardPageContent();

  @override
  Widget build(BuildContext context) {
    return const DashboardPage();
  }
}

class _HomePageContent extends StatelessWidget {
  const _HomePageContent();

  @override
  Widget build(BuildContext context) {
    return const HomePage();
  }
}

class _NoteListPageContent extends StatelessWidget {
  const _NoteListPageContent();

  @override
  Widget build(BuildContext context) {
    return const NoteListPage();
  }
}

class _ReadingHistoryPageContent extends StatelessWidget {
  const _ReadingHistoryPageContent();

  @override
  Widget build(BuildContext context) {
    return const ReadingHistoryPage();
  }
}

class _ProfilePageContent extends StatelessWidget {
  const _ProfilePageContent();

  @override
  Widget build(BuildContext context) {
    return const ProfilePage(continueAfterProfile: false);
  }
}
