import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/pages/main_navigation.dart';
import 'package:saxatsavita_flutter/services/first_time_user_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<WelcomeFeature> _features = [];

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeFeatures();
  }

  void _initializeFeatures() {
    _features.clear();
    _features.addAll([
      WelcomeFeature(
        icon: Icons.book_outlined,
        title: AppLocalizations.of(context)!.sakshatSavita,
        description: AppLocalizations.of(context)!.welcome_spiritual_reading,
        gradient: [Colors.deepOrange.shade700, Colors.orange.shade400],
      ),
      WelcomeFeature(
        icon: Icons.description_outlined,
        title: AppLocalizations.of(context)!.aashirvachan,
        description: AppLocalizations.of(context)!.welcome_aashirvachan_desc,
        gradient: [Colors.blue.shade700, Colors.blue.shade400],
      ),
      WelcomeFeature(
        icon: Icons.search_outlined,
        title: AppLocalizations.of(context)!.search,
        description: AppLocalizations.of(context)!.welcome_search_desc,
        gradient: [Colors.green.shade700, Colors.green.shade400],
      ),
      WelcomeFeature(
        icon: Icons.note_outlined,
        title: AppLocalizations.of(context)!.notes,
        description: AppLocalizations.of(context)!.welcome_notes_desc,
        gradient: [Colors.purple.shade700, Colors.purple.shade400],
      ),
      WelcomeFeature(
        icon: Icons.schedule_outlined,
        title: AppLocalizations.of(context)!.reading_plans,
        description: AppLocalizations.of(context)!.welcome_reading_plans_desc,
        gradient: [Colors.teal.shade700, Colors.teal.shade400],
      ),
      WelcomeFeature(
        icon: Icons.history_outlined,
        title: AppLocalizations.of(context)!.reading_history,
        description: AppLocalizations.of(context)!.welcome_reading_history_desc,
        gradient: [Colors.indigo.shade700, Colors.indigo.shade400],
      ),
      WelcomeFeature(
        icon: Icons.format_quote_outlined,
        title: AppLocalizations.of(context)!.quotes_image_generator,
        description:
            AppLocalizations.of(context)!.welcome_quotes_generator_desc,
        gradient: [Colors.pink.shade700, Colors.pink.shade400],
      ),
      WelcomeFeature(
        icon: Icons.info_outline,
        title: AppLocalizations.of(context)!.information,
        description: AppLocalizations.of(context)!.welcome_information_desc,
        gradient: [Colors.amber.shade700, Colors.amber.shade400],
      ),
    ]);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _features.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _navigateToHome();
    }
  }

  void _navigateToHome() async {
    // Mark onboarding as completed
    await FirstTimeUserService.markOnboardingCompleted();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    }
  }

  void _skipToHome() {
    _navigateToHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header with logo and skip button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [
                                Colors.deepOrange.shade700,
                                Colors.orange.shade400,
                              ],
                            ),
                          ),
                          child: const Icon(
                            Icons.auto_stories,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)!.sakshatSavita,
                          style: Theme.of(
                            context,
                          ).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _skipToHome,
                      child: Text(
                        AppLocalizations.of(context)!.skip,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Page indicators
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _features.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color:
                            _currentPage == index
                                ? Theme.of(context).colorScheme.primary
                                : Colors.grey.shade300,
                      ),
                    ),
                  ),
                ),
              ),

              // PageView with features
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentPage = index;
                    });
                  },
                  itemCount: _features.length,
                  itemBuilder: (context, index) {
                    return _buildFeaturePage(_features[index]);
                  },
                ),
              ),

              // Navigation buttons
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentPage > 0)
                      TextButton(
                        onPressed: () {
                          _pageController.previousPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        },
                        child: Text(
                          AppLocalizations.of(context)!.previous,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      )
                    else
                      const SizedBox(width: 80),

                    ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: Text(
                        _currentPage == _features.length - 1
                            ? AppLocalizations.of(context)!.get_started
                            : AppLocalizations.of(context)!.next,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePage(WelcomeFeature feature) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Feature icon with gradient background
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(colors: feature.gradient),
              boxShadow: [
                BoxShadow(
                  color: feature.gradient[0].withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(feature.icon, size: 60, color: Colors.white),
          ),

          const SizedBox(height: 40),

          // Feature title
          Text(
            feature.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Feature description
          Text(
            feature.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.7),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 40),

          // Feature highlights (if any)
          _buildFeatureHighlights(feature),
        ],
      ),
    );
  }

  Widget _buildFeatureHighlights(WelcomeFeature feature) {
    // Add specific highlights based on feature
    switch (feature.icon) {
      case Icons.book_outlined:
        return _buildHighlightsList([
          AppLocalizations.of(context)!.welcome_feature_spiritual_texts,
          AppLocalizations.of(context)!.welcome_feature_five_parts,
          AppLocalizations.of(context)!.welcome_feature_gujarati_english,
        ]);
      case Icons.description_outlined:
        return _buildHighlightsList([
          AppLocalizations.of(context)!.welcome_feature_divine_blessings,
          AppLocalizations.of(context)!.welcome_feature_spiritual_guidance,
        ]);
      case Icons.search_outlined:
        return _buildHighlightsList([
          AppLocalizations.of(context)!.welcome_feature_advanced_search,
          AppLocalizations.of(context)!.welcome_feature_instant_results,
        ]);
      case Icons.note_outlined:
        return _buildHighlightsList([
          AppLocalizations.of(context)!.welcome_feature_personal_notes,
          AppLocalizations.of(context)!.welcome_feature_sync_across_devices,
        ]);
      case Icons.schedule_outlined:
        return _buildHighlightsList([
          AppLocalizations.of(context)!.welcome_feature_custom_reading_goals,
          AppLocalizations.of(context)!.welcome_feature_progress_tracking,
        ]);
      case Icons.format_quote_outlined:
        return _buildHighlightsList([
          AppLocalizations.of(context)!.welcome_feature_beautiful_quotes,
          AppLocalizations.of(context)!.welcome_feature_share_inspiration,
        ]);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildHighlightsList(List<String> highlights) {
    return Column(
      children:
          highlights.map((highlight) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4.0),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      highlight,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.8),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}

class WelcomeFeature {
  final IconData icon;
  final String title;
  final String description;
  final List<Color> gradient;

  WelcomeFeature({
    required this.icon,
    required this.title,
    required this.description,
    required this.gradient,
  });
}
