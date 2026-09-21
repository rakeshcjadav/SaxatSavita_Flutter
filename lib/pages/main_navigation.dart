import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/components/drawer.dart';
import 'package:saxatsavita_flutter/services/in_app_update_service.dart';
import 'package:saxatsavita_flutter/services/notification_service.dart';

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
  int _selectedIndex = 1;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    InAppUpdateService().scheduleStartupCheck(context);
    if (!kIsWeb) {
      unawaited(_initDailyQuizNotifications());
    }
  }

  Future<void> _initDailyQuizNotifications() async {
    await NotificationService().ensureDailyQuizReminderScheduled();
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(NotificationService().consumePendingLaunchRoute());
    });
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final barColor = colorScheme.surfaceContainer;

    return Scaffold(
      drawer:
          _selectedIndex == 1
              ? MyDrawer(
                items: [
                  DrawerItem.aashirvachan,
                  DrawerItem.notes,
                  DrawerItem.search,
                  DrawerItem.dailyQuiz,
                  DrawerItem.haribhakts,
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
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: barColor,
          boxShadow: [
            BoxShadow(
              color: colorScheme.shadow.withValues(
                alpha:
                    Theme.of(context).brightness == Brightness.dark
                        ? 0.55
                        : 0.16,
              ),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          elevation: 0,
          backgroundColor: barColor,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor: colorScheme.onSurfaceVariant,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            height: 1.15,
          ),
          landscapeLayout: BottomNavigationBarLandscapeLayout.centered,
          items: [
            BottomNavigationBarItem(
              icon: _NavIcon(Icons.dashboard_outlined),
              activeIcon: _NavIcon(Icons.dashboard, highlighted: true),
              label: AppLocalizations.of(context)!.dashboard,
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(Icons.home_outlined),
              activeIcon: _NavIcon(Icons.home, highlighted: true),
              label: AppLocalizations.of(context)!.sakshatSavita,
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(Icons.edit_note_outlined),
              activeIcon: _NavIcon(Icons.edit_note, highlighted: true),
              label: AppLocalizations.of(context)!.notes,
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(Icons.history_outlined),
              activeIcon: _NavIcon(Icons.history, highlighted: true),
              label: AppLocalizations.of(context)!.reading_history,
            ),
            BottomNavigationBarItem(
              icon: _NavIcon(Icons.person_outline),
              activeIcon: _NavIcon(Icons.person, highlighted: true),
              label: AppLocalizations.of(context)!.profile,
            ),
          ],
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  const _NavIcon(this.icon, {this.highlighted = false});

  final IconData icon;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color:
              highlighted
                  ? colors.primary.withValues(alpha: 0.16)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Icon(icon, size: 24),
        ),
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
