/* Example integrations of Firebase Remote Config into existing pages
// Copy these snippets into your actual pages

// ============================================================
// HOMEPAGE INTEGRATION
// ============================================================
// File: lib/pages/homepage.dart

import 'package:saxatsavita_flutter/components/remote_config_widgets.dart';
import 'package:saxatsavita_flutter/services/remote_config_service.dart';

class HomePage extends StatefulWidget {
  // ... existing code
}

class _HomePageState extends State<HomePage> 
    with RemoteConfigVersionCheck { // Add this mixin
  
  @override
  void initState() {
    super.initState();
    
    // Check for updates on app start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAppVersion(context);
    });
  }

  @override
  Widget build(BuildContext context) {
    final remoteConfig = RemoteConfigService();
    
    // Check for maintenance mode
    if (remoteConfig.isMaintenanceMode) {
      return const MaintenanceModeScreen();
    }
    
    return Scaffold(
      // ... existing app bar
      body: Column(
        children: [
          // Add announcement banner at the top
          const AnnouncementBanner(),
          
          // ... rest of your existing content
        ],
      ),
    );
  }
}

// ============================================================
// KIRAN READ PAGE INTEGRATION
// ============================================================
// File: lib/pages/kiranreadpage.dart

import 'package:saxatsavita_flutter/services/remote_config_service.dart';
import 'package:saxatsavita_flutter/components/remote_config_widgets.dart';

class _KiranReadPageState extends State<KiranReadPage> {
  
  @override
  Widget build(BuildContext context) {
    final remoteConfig = RemoteConfigService();
    
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: '${AppLocalizations.of(context)!.kiran} ${widget.kiranInfo.number}',
        actionItems: [ActionOptions.settings],
        extraActions: [
          // Conditionally show favorite button
          if (remoteConfig.enableFavorites)
            IconButton(
              icon: Icon(
                widget.kiranUserInfo.isFavourite == 0
                    ? Icons.favorite_border
                    : Icons.favorite,
              ),
              onPressed: () {
                // ... existing favorite logic
              },
            ),
          
          // Conditionally show bookmark button
          if (remoteConfig.enableBookmarks)
            IconButton(
              icon: Icon(
                Utils.isBookmarked(widget.kiranUserInfo)
                    ? Icons.bookmark
                    : Icons.bookmark_add,
              ),
              onPressed: () {
                // ... existing bookmark logic
              },
            ),
          
          // Conditionally show search button
          if (remoteConfig.enableSearch)
            IconButton(
              icon: Icon(_isSearchMode ? Icons.close : Icons.search),
              onPressed: () {
                // ... existing search logic
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Conditionally show auto-scroll controls
          if (remoteConfig.enableAutoScroll)
            displayExtraInfos(context),
          
          // ... rest of content
        ],
      ),
      floatingActionButton: remoteConfig.enableNotes
          ? FloatingActionButton(
              onPressed: () async {
                _pauseTimer();
                await _openNoteEditor();
                _resumeTimer();
              },
              child: const Icon(Icons.note_add),
            )
          : null,
    );
  }
  
  // In the HTML widget rendering section:
  Widget _buildKiranContentWidget(Map<String, dynamic> contentData, BuildContext context) {
    final remoteConfig = RemoteConfigService();
    
    // Use Remote Config to toggle between implementations (A/B testing)
    final useCustomHtml = remoteConfig.useCustomHtmlWidget;
    
    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            if (!useCustomHtml)
              ...HtmlToTextSpan.convertToWidgets(
                // ... existing params
                onCreateQuoteImage: remoteConfig.enableQuotes
                    ? (selectedText) async {
                        // Quote creation logic
                      }
                    : null, // Disable if quotes feature is off
              ),
            if (useCustomHtml)
              CustomHtmlWidget(
                // ... existing params
              ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// SETTINGS PAGE INTEGRATION
// ============================================================
// File: lib/pages/settingspage.dart

import 'package:saxatsavita_flutter/services/remote_config_service.dart';

class SettingsPage extends StatefulWidget {
  // ... existing code
}

class _SettingsPageState extends State<SettingsPage> {
  
  @override
  Widget build(BuildContext context) {
    final remoteConfig = RemoteConfigService();
    
    return Scaffold(
      // ... existing scaffold
      body: ListView(
        children: [
          // Reading Settings Section
          // ... existing settings
          
          // Conditionally show auto-scroll setting
          if (remoteConfig.enableAutoScroll)
            SwitchListTile(
              title: const Text('Keep Screen On'),
              subtitle: const Text('Prevent screen from sleeping while reading'),
              value: appSettingsNotifier.value.keepScreenOn,
              onChanged: (value) {
                // ... existing logic
              },
            ),
          
          // Remote Config Debug Section (show in debug mode)
          if (kDebugMode) ...[
            const Divider(),
            ListTile(
              title: const Text('Remote Config'),
              subtitle: const Text('Firebase Remote Config Settings'),
              trailing: const Icon(Icons.cloud),
            ),
            ListTile(
              title: const Text('Refresh Config'),
              subtitle: Text(
                'Last fetch: ${remoteConfig.isInitialized ? "Initialized" : "Not initialized"}',
              ),
              trailing: const Icon(Icons.refresh),
              onTap: () async {
                final success = await remoteConfig.fetchConfig();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        success ? 'Config refreshed!' : 'Failed to refresh config',
                      ),
                    ),
                  );
                }
              },
            ),
            // Show current feature flags
            ExpansionTile(
              title: const Text('Feature Flags'),
              children: [
                _buildFeatureTile('Search', remoteConfig.enableSearch),
                _buildFeatureTile('Notes', remoteConfig.enableNotes),
                _buildFeatureTile('Quotes', remoteConfig.enableQuotes),
                _buildFeatureTile('Auto Scroll', remoteConfig.enableAutoScroll),
                _buildFeatureTile('Bookmarks', remoteConfig.enableBookmarks),
                _buildFeatureTile('Favorites', remoteConfig.enableFavorites),
                _buildFeatureTile('Reading History', remoteConfig.enableReadingHistory),
                _buildFeatureTile('Reading Plans', remoteConfig.enableReadingPlans),
              ],
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildFeatureTile(String name, bool enabled) {
    return ListTile(
      dense: true,
      title: Text(name),
      trailing: Icon(
        enabled ? Icons.check_circle : Icons.cancel,
        color: enabled ? Colors.green : Colors.red,
      ),
    );
  }
}

// ============================================================
// DRAWER/NAVIGATION MENU INTEGRATION
// ============================================================
// File: lib/components/appbar.dart or wherever your drawer is

import 'package:saxatsavita_flutter/services/remote_config_service.dart';

Widget buildDrawer(BuildContext context) {
  final remoteConfig = RemoteConfigService();
  
  return Drawer(
    child: ListView(
      children: [
        // ... existing drawer items
        
        // Conditionally show menu items
        if (remoteConfig.enableSearch)
          ListTile(
            leading: const Icon(Icons.search),
            title: const Text('Search'),
            onTap: () {
              Navigator.pushNamed(context, '/search');
            },
          ),
        
        if (remoteConfig.enableNotes)
          ListTile(
            leading: const Icon(Icons.note),
            title: const Text('My Notes'),
            onTap: () {
              Navigator.pushNamed(context, '/notes');
            },
          ),
        
        if (remoteConfig.enableReadingHistory)
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('Reading History'),
            onTap: () {
              Navigator.pushNamed(context, '/readinghistory');
            },
          ),
        
        if (remoteConfig.enableReadingPlans)
          ListTile(
            leading: const Icon(Icons.calendar_today),
            title: const Text('Reading Plans'),
            onTap: () {
              Navigator.pushNamed(context, '/reading_plans');
            },
          ),
      ],
    ),
  );
}

// ============================================================
// SPLASH PAGE INTEGRATION
// ============================================================
// File: lib/pages/splashpage.dart

import 'package:saxatsavita_flutter/services/remote_config_service.dart';

class SplashPage extends StatefulWidget {
  // ... existing code
}

class _SplashPageState extends State<SplashPage> {
  
  @override
  void initState() {
    super.initState();
    _initialize();
  }
  
  Future<void> _initialize() async {
    // Wait for Remote Config to initialize
    final remoteConfig = RemoteConfigService();
    
    // Check for maintenance mode
    if (remoteConfig.isMaintenanceMode) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const MaintenanceModeScreen(),
          ),
        );
      }
      return;
    }
    
    // ... rest of your initialization
    
    // Navigate based on welcome screen setting
    if (mounted) {
      if (remoteConfig.showWelcomeScreen && isFirstLaunch) {
        Navigator.pushReplacementNamed(context, '/welcome');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    }
  }
}

// ============================================================
// QUOTE GENERATOR INTEGRATION
// ============================================================
// File: lib/pages/quotes_image_generator_page.dart

import 'package:saxatsavita_flutter/services/remote_config_service.dart';

class QuotesImageGeneratorPage extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    final remoteConfig = RemoteConfigService();
    
    // Check if feature is enabled
    if (!remoteConfig.enableQuotes) {
      return Scaffold(
        body: Center(
          child: Text('Quotes feature is temporarily unavailable'),
        ),
      );
    }
    
    return Scaffold(
      // ... existing quote generator UI
      
      // Conditionally show share button
      actions: [
        if (remoteConfig.enableSocialSharing)
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Share logic
            },
          ),
      ],
    );
  }
}

// ============================================================
// READING HISTORY INTEGRATION
// ============================================================
// File: lib/pages/reading_history_page.dart

import 'package:saxatsavita_flutter/services/remote_config_service.dart';
import 'package:saxatsavita_flutter/components/remote_config_widgets.dart';

class ReadingHistoryPage extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    // Use ConditionalFeature widget
    return ConditionalFeature(
      featureKey: 'enable_reading_history',
      child: Scaffold(
        // ... your normal reading history page
      ),
      fallback: Scaffold(
        body: Center(
          child: Text('Reading History is temporarily unavailable'),
        ),
      ),
    );
  }
}

// ============================================================
// BOOK MAIN PAGE INTEGRATION
// ============================================================
// File: lib/pages/bookmainpage.dart

import 'package:saxatsavita_flutter/services/remote_config_service.dart';

class BookMainpage extends StatelessWidget {
  
  @override
  Widget build(BuildContext context) {
    final remoteConfig = RemoteConfigService();
    
    return Scaffold(
      body: Column(
        children: [
          // Show featured Kiran from Remote Config
          if (remoteConfig.featuredKiranPart > 0)
            Card(
              child: ListTile(
                leading: const Icon(Icons.star),
                title: Text('Featured: Kiran ${remoteConfig.featuredKiranIndex}'),
                subtitle: Text('Part ${remoteConfig.featuredKiranPart}'),
                onTap: () {
                  // Navigate to featured Kiran
                },
              ),
            ),
          
          // ... rest of your book list
        ],
      ),
    );
  }
}

// ============================================================
// USAGE NOTES
// ============================================================

//
INTEGRATION CHECKLIST:

1. ✅ Add imports to pages that need Remote Config
2. ✅ Wrap features with conditional checks
3. ✅ Add ConditionalFeature widgets where appropriate
4. ✅ Add AnnouncementBanner to main screens
5. ✅ Add MaintenanceModeScreen check in key entry points
6. ✅ Add version check mixin to important pages
7. ✅ Test with different Remote Config values

TESTING:
1. Set parameters in Firebase Console
2. Publish changes
3. Force close and restart app (or wait for fetch interval)
4. Verify features show/hide based on config
5. Test maintenance mode
6. Test announcements
7. Test version checking

DEPLOYMENT:
1. Set production values in Firebase Console
2. Use conditions for gradual rollout
3. Monitor analytics for fetch success
4. Be ready to quickly toggle features if issues arise
*/
