import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';

/// Marketing showcase page for Play Store screenshots
/// Displays app features in a beautiful scrollable layout
class MarketingShowcasePage extends StatefulWidget {
  const MarketingShowcasePage({super.key});

  @override
  State<MarketingShowcasePage> createState() => _MarketingShowcasePageState();
}

class _MarketingShowcasePageState extends State<MarketingShowcasePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final loc = AppLocalizations.of(context)!;

    final features = [
      FeatureSlide(
        icon: Icons.auto_stories,
        iconColor: Colors.deepOrange.shade800,
        title: loc.sakshatSavita,
        description: loc.welcome_spiritual_reading,
        imagePath: 'assets/saxat_savita/1_home_screen.png',
        backgroundColor: Colors.orange.shade50,
      ),
      FeatureSlide(
        icon: Icons.description_outlined,
        iconColor: Colors.blue.shade800,
        title: loc.aashirvachan,
        description: loc.welcome_aashirvachan_desc,
        imagePath: 'assets/saxat_savita/3_aashirvachan.png',
        backgroundColor: Colors.blue.shade50,
      ),
      FeatureSlide(
        icon: Icons.description_outlined,
        iconColor: Colors.amber.shade800,
        title: loc.welcome_book_parts_title,
        description: loc.welcome_book_parts_desc,
        imagePath: 'assets/saxat_savita/2_book_parts.png',
        backgroundColor: Colors.amber.shade50,
      ),
      FeatureSlide(
        icon: Icons.description_outlined,
        iconColor: Colors.green.shade800,
        title: loc.welcome_kiran_list_title,
        description: loc.welcome_kiran_list_desc,
        imagePath: 'assets/saxat_savita/4_kiran_list.png',
        backgroundColor: Colors.green.shade50,
      ),
      FeatureSlide(
        icon: Icons.description_outlined,
        iconColor: Colors.purple.shade800,
        title: loc.welcome_kiran_reading_title,
        description: loc.welcome_kiran_reading_desc,
        imagePath: 'assets/saxat_savita/5_kiran_details.png',
        backgroundColor: Colors.purple.shade50,
      ),
      FeatureSlide(
        icon: Icons.calendar_today,
        iconColor: Colors.teal,
        title: loc.reading_plans,
        description: loc.welcome_kiran_reading_plan_desc,
        imagePath: 'assets/saxat_savita/7_reading_plans.png',
        backgroundColor: Colors.teal.shade50,
      ),
      FeatureSlide(
        icon: Icons.history,
        iconColor: Colors.indigo.shade800,
        title: loc.reading_history,
        description: loc.welcome_reading_history_desc,
        imagePath: 'assets/saxat_savita/6_reading_history.png',
        backgroundColor: Colors.indigo.shade50,
      ),
      FeatureSlide(
        icon: Icons.search,
        iconColor: Colors.pink.shade800,
        title: loc.search,
        description: loc.welcome_search_desc,
        imagePath: 'assets/saxat_savita/10_search.png',
        backgroundColor: Colors.pink.shade50,
      ),
      FeatureSlide(
        icon: Icons.note_add,
        iconColor: Colors.brown.shade800,
        title: loc.notes,
        description: loc.welcome_notes_desc,
        imagePath: 'assets/saxat_savita/9_personal_notes.png',
        backgroundColor: Colors.brown.shade50,
      ),
      FeatureSlide(
        icon: Icons.bookmark,
        iconColor: Colors.amber.shade800,
        title: loc.bookmark,
        description: loc.welcome_kiran_favorites_desc,
        imagePath: 'assets/saxat_savita/2_book_parts.png',
        backgroundColor: Colors.amber.shade50,
      ),
      FeatureSlide(
        icon: Icons.format_quote,
        iconColor: Colors.indigo,
        title: loc.create_quote_image,
        description: loc.welcome_quotes_generator_desc,
        imagePath: 'assets/saxat_savita/8_quotes_creator.png',
        backgroundColor: Colors.indigo.shade50,
      ),
      FeatureSlide(
        icon: Icons.feedback_outlined,
        iconColor: Colors.pink.shade800,
        title: loc.settings,
        description: loc.welcome_kiran_settings_desc,
        imagePath: 'assets/saxat_savita/11_settings.png',
        backgroundColor: Colors.pink.shade50,
      ),
    ];

    return Scaffold(
      body: PageView.builder(
        controller: _pageController,
        itemCount: features.length,
        onPageChanged: (index) {
          setState(() {
            _currentPage = index;
          });
        },
        itemBuilder: (context, index) {
          return _buildFeatureSlide(features[index]);
        },
      ),
    );
  }

  Widget _buildFeatureSlide(FeatureSlide feature) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 30),
          // Icon with gradient background
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: feature.backgroundColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: feature.iconColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(feature.icon, size: 25, color: feature.iconColor),
              ),
              const SizedBox(width: 16),
              // Title
              Text(
                feature.title,
                style: TextStyle(
                  fontSize: 32,
                  color: feature.iconColor,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                  shadows: [
                    Shadow(
                      color: feature.iconColor.withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Description
          Text(
            feature.description,
            style: TextStyle(
              fontSize: 18,
              color: feature.iconColor,
              //color: Colors.brown,
              //color: Colors.grey.shade700,
              height: 1.5,
              shadows: [
                Shadow(
                  color: feature.iconColor.withOpacity(0.3),
                  blurRadius: 20,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            textAlign: TextAlign.center,
            maxLines: 4,
          ),
          const SizedBox(height: 16),

          // Screenshot with rounded corners
          ClipRRect(
            child: Image.asset(
              feature.imagePath,
              fit: BoxFit.fitWidth,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(color: feature.backgroundColor),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        feature.icon,
                        size: 100,
                        color: feature.iconColor.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Screenshot Placeholder',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int pageCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        pageCount,
        (index) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 32 : 8,
          height: 8,
          decoration: BoxDecoration(
            color:
                _currentPage == index
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

class FeatureSlide {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String imagePath;
  final Color backgroundColor;

  FeatureSlide({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.backgroundColor,
  });
}
