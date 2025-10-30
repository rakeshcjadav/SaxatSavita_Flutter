import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';
import 'package:saxatsavita_flutter/services/utils.dart';
import 'package:saxatsavita_flutter/services/user_profile_service.dart';
import 'package:saxatsavita_flutter/models/user_profile_model.dart';
import 'package:share_plus/share_plus.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/inspirational_quote_model.dart';
import 'package:gal/gal.dart';

// Model class for sticker data
class StickerData {
  String assetPath;
  Offset position;
  double size;
  double rotation;

  StickerData({
    required this.assetPath,
    required this.position,
    this.size = 60.0,
    this.rotation = 0.0,
  });
}

class QuotesImageGeneratorPage extends StatefulWidget {
  const QuotesImageGeneratorPage({super.key, required this.quote});

  final InspirationalQuote? quote;

  @override
  State<QuotesImageGeneratorPage> createState() =>
      _QuotesImageGeneratorPageState();
}

class _QuotesImageGeneratorPageState extends State<QuotesImageGeneratorPage>
    with TickerProviderStateMixin {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final TextEditingController _quoteController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();
  late TabController _customizationTabController;

  // Customization options
  final Color _textColor = Colors.white;
  final Color _authorColor = Colors.white70;
  final String _selectedFont = 'NotoSansGujarati';
  double _fontSize = 24.0;
  double _authorFontSize = 16.0;
  double _imageHeight = 370.0;
  double _imageWidth = 370.0;
  int _selectedTemplate = 8;
  String _selectedGradient = 'orange';

  // User info options (optional)
  bool _showUserAvatar = false;
  bool _showUserName = false;

  // Sticker options
  List<StickerData> _stickers = [];
  String? _selectedStickerPath;

  // Predefined sticker paths
  final List<String> _availableStickers = [
    'assets/stickers/om.png',
    'assets/stickers/lotus.png',
    'assets/stickers/diya.png',
    'assets/stickers/mandala.png',
    'assets/stickers/flower.png',
  ];

  // Profile service and data
  UserProfile? _userProfile;
  final UserProfileService _profileService = UserProfileService();

  // Current quote reference
  InspirationalQuote? _currentSelectedQuote;

  bool hasEnableEditing = false;

  // Predefined inspirational quotes
  List<InspirationalQuote> get _predefinedQuotes => [
    InspirationalQuote(
      quote: AppLocalizations.of(context)!.predefined_quote_1,
      author: '',
      partNumber: -1,
      kiranIndex: -1,
    ),
    InspirationalQuote(
      quote: AppLocalizations.of(context)!.predefined_quote_2,
      author: '',
      partNumber: -1,
      kiranIndex: -1,
    ),
    InspirationalQuote(
      quote: AppLocalizations.of(context)!.predefined_quote_3,
      author: '',
      partNumber: -1,
      kiranIndex: -1,
    ),
    InspirationalQuote(
      quote: AppLocalizations.of(context)!.predefined_quote_4,
      author: '',
      partNumber: -1,
      kiranIndex: -1,
    ),
    InspirationalQuote(
      quote: AppLocalizations.of(context)!.predefined_quote_5,
      author: '',
      partNumber: -1,
      kiranIndex: -1,
    ),
  ];

  // Color gradients
  final Map<String, List<Color>> _gradients = {
    'orange': [Colors.deepOrange.shade700, Colors.orange.shade400],
    'blue': [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
    'green': [const Color(0xFF2E7D32), const Color(0xFF4CAF50)],
    'purple': [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)],
    'teal': [Colors.teal.shade700, Colors.teal.shade400],
    'indigo': [Colors.indigo.shade700, Colors.indigo.shade400],
    'saffron': [const Color(0xFFFF6F00), const Color(0xFFFFB74D)],
    'spiritual': [const Color(0xFF8E24AA), const Color(0xFFBA68C8)],
  };

  @override
  void initState() {
    super.initState();
    _customizationTabController = TabController(length: 6, vsync: this);
    _loadUserProfile();
    // Set first predefined quote as default
    if (widget.quote != null) {
      _currentSelectedQuote = widget.quote;
      _quoteController.text = widget.quote!.quote;
      _authorController.text = widget.quote!.author;
      hasEnableEditing = false;
    } else {
      hasEnableEditing = true;
      // Don't call _getRandomQuote() here since localization isn't ready yet
    }
  }

  Future<void> _loadUserProfile() async {
    if (FirebaseAuth.instance.currentUser != null) {
      try {
        final profile = await _profileService.getUserProfile();
        if (mounted) {
          setState(() {
            _userProfile = profile;
          });
        }
      } catch (e) {
        // Handle error silently, will fall back to Firebase Auth display name
      }
    }
  }

  String _getDisplayName() {
    // Prioritize profile data if available and both names are filled
    if (_userProfile != null &&
        _userProfile!.firstName.isNotEmpty &&
        _userProfile!.lastName.isNotEmpty) {
      return _userProfile!.fullName;
    }

    // Fall back to Firebase Auth display name
    return FirebaseAuth.instance.currentUser?.displayName ??
        AppLocalizations.of(context)!.spiritual_seeker;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Call this here where localization is available
    if (widget.quote == null &&
        hasEnableEditing &&
        _quoteController.text.isEmpty) {
      _getRandomQuote();
    }
  }

  void _getRandomQuote() {
    if (_predefinedQuotes.isNotEmpty) {
      final random =
          DateTime.now().millisecondsSinceEpoch % _predefinedQuotes.length;
      InspirationalQuote randomQuote = _predefinedQuotes[random];
      String author = _authorController.text;
      _currentSelectedQuote = randomQuote;
      _currentSelectedQuote!.setAuthor =
          author.isEmpty ? _getDisplayName() : author;
      _quoteController.text = randomQuote.quote;
      _authorController.text = _currentSelectedQuote!.author;
      setState(() {});
    }
  }

  @override
  void dispose() {
    _customizationTabController.dispose();
    _quoteController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: AppLocalizations.of(context)!.quotes_image_generator,
        extraActions: [
          if (hasEnableEditing) ...[
            IconButton(
              icon: const Icon(Icons.shuffle),
              onPressed: _getRandomQuote,
              tooltip: AppLocalizations.of(context)!.random_quote,
            ),
          ],
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.share),
                if (FirebaseAuth.instance.currentUser == null) ...[
                  // Lock icon
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Icon(Icons.lock, size: 15, color: Colors.red),
                  ),
                ],
              ],
            ),
            tooltip: AppLocalizations.of(context)!.share_quote,
            onPressed: _shareImage,
          ),
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.download),
                if (FirebaseAuth.instance.currentUser == null) ...[
                  // Lock icon
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Icon(Icons.lock, size: 15, color: Colors.red),
                  ),
                ],
              ],
            ),
            onPressed: _saveImage,
            tooltip: AppLocalizations.of(context)!.save_quote,
          ),
        ],
        bottom: TabBar(
          controller: _customizationTabController,
          tabs: [
            Tab(
              icon: Icon(Icons.dashboard_customize),
              text: AppLocalizations.of(context)!.tab_templates,
            ),
            Tab(
              icon: Icon(Icons.palette),
              text: AppLocalizations.of(context)!.tab_colors,
            ),
            Tab(
              icon: Icon(Icons.text_fields),
              text: AppLocalizations.of(context)!.tab_font_size,
            ),
            Tab(
              icon: Icon(Icons.photo_size_select_large),
              text: AppLocalizations.of(context)!.tab_image_size,
            ),
            Tab(
              icon: Icon(Icons.person),
              text: AppLocalizations.of(context)!.tab_user_info,
            ),
            Tab(
              icon: Icon(Icons.add_photo_alternate),
              text: AppLocalizations.of(context)!.tab_stickers,
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customization Section
              _buildCustomizationSection(),

              // Preview Section
              _buildPreviewSectionSimplified(),
              const SizedBox(height: 12),

              if (hasEnableEditing) ...[
                // Text Input Section
                _buildTextInputSection(),
                const SizedBox(height: 12),

                // Predefined Quotes Section
                _buildPredefinedQuotesSection(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTemplatesTab() {
    final templates = [
      {'name': AppLocalizations.of(context)!.template_profile, 'index': 8},
      {'name': AppLocalizations.of(context)!.template_card, 'index': 9},
      {'name': AppLocalizations.of(context)!.template_simple, 'index': 0},
      {'name': AppLocalizations.of(context)!.template_geometric, 'index': 1},
      {'name': AppLocalizations.of(context)!.template_spiritual, 'index': 3},
      {'name': AppLocalizations.of(context)!.template_mandala, 'index': 4},
      {'name': AppLocalizations.of(context)!.template_elegant, 'index': 5},
      {'name': AppLocalizations.of(context)!.template_modern, 'index': 6},
      {'name': AppLocalizations.of(context)!.template_classic, 'index': 7},
      {'name': AppLocalizations.of(context)!.template_social, 'index': 10},
      {'name': AppLocalizations.of(context)!.template_story, 'index': 11},
    ];

    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
        bottom: 8.0,
        left: 0.0,
        right: 0.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: templates.length,
              itemBuilder: (context, index) {
                final template = templates[index];
                final templateIndex = template['index'] as int;
                final templateName = template['name'] as String;
                final isSelected = _selectedTemplate == templateIndex;

                return Padding(
                  padding: EdgeInsets.only(
                    left: index == 0 ? 16 : 8,
                    right: index == templates.length - 1 ? 16 : 8,
                  ),
                  child: GestureDetector(
                    onTap:
                        () => setState(() => _selectedTemplate = templateIndex),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Template preview (static image)
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.grey.shade300,
                              width: isSelected ? 3 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    isSelected
                                        ? Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.3)
                                        : Colors.black.withValues(alpha: 0.1),
                                blurRadius: isSelected ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.asset(
                              'assets/template_previews/template_$templateIndex.png',
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                // Fallback to rendered widget if image doesn't exist
                                return Transform.scale(
                                  scale: 80 / _imageWidth,
                                  alignment: Alignment.center,
                                  child: SizedBox(
                                    width: _imageWidth,
                                    height: _imageHeight,
                                    child: _buildQuoteImageForTemplate(
                                      templateIndex,
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Template name
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            templateName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color:
                                  isSelected
                                      ? Colors.white
                                      : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // New simplified preview section - shows only selected template
  Widget _buildPreviewSectionSimplified() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalizations.of(context)!.quote_preview,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  spreadRadius: 0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: RepaintBoundary(
              key: _repaintBoundaryKey,
              child: _buildQuoteImageForTemplate(_selectedTemplate),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuoteImageForTemplate(int templateIndex) {
    return Container(
      width: _imageWidth,
      height: _imageHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: _gradients[_selectedGradient]!,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          // Background pattern (optional)
          if (templateIndex == 1) _buildGeometricPattern(),
          if (templateIndex == 3) _buildSpiritualPattern(),
          if (templateIndex == 4) _buildMandalaPattern(),
          if (templateIndex == 5) _buildElegantPattern(),
          if (templateIndex == 6) _buildModernPattern(),
          if (templateIndex == 7) _buildClassicPattern(),
          if (templateIndex == 8) _buildProfilePattern(),
          if (templateIndex == 9) _buildCardPattern(),
          if (templateIndex == 10) _buildSocialPattern(),
          if (templateIndex == 11) _buildStoryPattern(),

          // Main content - different layouts based on template
          _buildQuoteContentForTemplate(templateIndex),

          // Stickers overlay
          ..._stickers.asMap().entries.map((entry) {
            final index = entry.key;
            final sticker = entry.value;
            return Positioned(
              left: sticker.position.dx,
              top: sticker.position.dy,
              child: GestureDetector(
                onPanUpdate: (details) {
                  setState(() {
                    _stickers[index].position = Offset(
                      (_stickers[index].position.dx + details.delta.dx).clamp(
                        0.0,
                        _imageWidth - sticker.size,
                      ),
                      (_stickers[index].position.dy + details.delta.dy).clamp(
                        0.0,
                        _imageHeight - sticker.size,
                      ),
                    );
                  });
                },
                child: Transform.rotate(
                  angle: sticker.rotation,
                  child: Stack(
                    children: [
                      FutureBuilder(
                        future: _checkAssetExists(sticker.assetPath),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data == true) {
                            return Image.asset(
                              sticker.assetPath,
                              width: sticker.size,
                              height: sticker.size,
                              fit: BoxFit.contain,
                            );
                          } else {
                            return Container(
                              width: sticker.size,
                              height: sticker.size,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.image,
                                color: Colors.grey.shade600,
                                size: sticker.size * 0.5,
                              ),
                            );
                          }
                        },
                      ),
                      // Control buttons
                      Positioned(
                        right: -5,
                        top: -5,
                        child: GestureDetector(
                          onTap: () => _removeSticker(index),
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      // Resize handle
                      Positioned(
                        right: -5,
                        bottom: -5,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              final newSize = (_stickers[index].size +
                                      details.delta.dx)
                                  .clamp(30.0, 150.0);
                              _stickers[index].size = newSize;
                            });
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Theme.of(context).primaryColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.open_in_full,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                      // Rotate handle
                      Positioned(
                        left: -5,
                        bottom: -5,
                        child: GestureDetector(
                          onPanUpdate: (details) {
                            setState(() {
                              _stickers[index].rotation +=
                                  details.delta.dx * 0.02;
                            });
                          },
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.rotate_right,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildQuoteContentForTemplate(int templateIndex) {
    switch (templateIndex) {
      case 3: // Spiritual - center focused with Om symbol
        return _buildSpiritualLayout();
      case 4: // Mandala - circular layout
        return _buildMandalaLayout();
      case 5: // Elegant - side layout with decorative elements
        return _buildElegantLayout();
      case 6: // Modern - minimalist layout
        return _buildModernLayout();
      case 7: // Classic - traditional layout with borders
        return _buildClassicLayout();
      case 8: // Profile - user avatar and name prominently featured
        return _buildProfileLayout();
      case 9: // Card - business card style with user info
        return _buildCardLayout();
      case 10: // Social - social media style post layout
        return _buildSocialLayout();
      case 11: // Story - Instagram story style vertical layout
        return _buildStoryLayout();
      default: // Simple, Geometric, Floral - default layout
        return _buildDefaultLayout();
    }
  }

  Widget _buildDefaultLayout() {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildUserInfo(),
          // Quote mark
          Row(
            children: [
              Transform.flip(
                flipY: false,
                flipX: true,
                child: Icon(
                  Icons.format_quote,
                  size: 48,
                  color: _textColor.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Quote text
          Center(
            child: Text(
              _quoteController.text.isNotEmpty
                  ? _quoteController.text
                  : '${AppLocalizations.of(context)!.enter_quote}...',
              style: TextStyle(
                color: _textColor,
                fontSize: _fontSize,
                fontWeight: FontWeight.w600,
                fontFamily: _selectedFont,
                height: 1.4,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          const SizedBox(height: 12),
          // Quote mark
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(
                Icons.format_quote,
                size: 48,
                color: _textColor.withValues(alpha: 0.3),
              ),
            ],
          ),
          const SizedBox(height: 12),

          _buildAuthorAndSource(),
        ],
      ),
    );
  }

  Widget _buildSpiritualLayout() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        children: [
          // Om symbol at top
          Icon(
            Icons.self_improvement,
            size: 32,
            color: _textColor.withValues(alpha: 0.8),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: _textColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _textColor.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _quoteController.text.isNotEmpty
                          ? _quoteController.text
                          : '${AppLocalizations.of(context)!.enter_quote}...',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: _fontSize,
                        fontWeight: FontWeight.w500,
                        fontFamily: _selectedFont,
                        height: 1.5,
                        letterSpacing: 0.8,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    _buildAuthorAndSource(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMandalaLayout() {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Center(
        child: Container(
          width: 300,
          height: 300,
          padding: const EdgeInsets.all(32.0),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _textColor.withValues(alpha: 0.05),
            border: Border.all(
              color: _textColor.withValues(alpha: 0.3),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  _quoteController.text.isNotEmpty
                      ? _quoteController.text
                      : '${AppLocalizations.of(context)!.enter_quote}...',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: _fontSize * 0.8,
                    fontWeight: FontWeight.w600,
                    fontFamily: _selectedFont,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              _buildAuthorAndSource(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildElegantLayout() {
    return Padding(
      padding: const EdgeInsets.all(48.0),
      child: Row(
        children: [
          // Left side decoration
          Container(
            width: 4,
            height: _imageHeight * 0.6,
            decoration: BoxDecoration(
              color: _textColor.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 32),

          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _quoteController.text.isNotEmpty
                      ? _quoteController.text
                      : '${AppLocalizations.of(context)!.enter_quote}...',
                  style: TextStyle(
                    color: _textColor,
                    fontSize: _fontSize,
                    fontWeight: FontWeight.w400,
                    fontFamily: _selectedFont,
                    height: 1.6,
                    fontStyle: FontStyle.italic,
                  ),
                  textAlign: TextAlign.left,
                ),
                const SizedBox(height: 24),
                _buildAuthorAndSource(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernLayout() {
    return Padding(
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Minimalist quote
          Text(
            _quoteController.text.isNotEmpty
                ? _quoteController.text
                : '${AppLocalizations.of(context)!.enter_quote}...',
            style: TextStyle(
              color: _textColor,
              fontSize: _fontSize * 1.1,
              fontWeight: FontWeight.w300,
              fontFamily: _selectedFont,
              height: 1.8,
              letterSpacing: 1.2,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Simple line separator
          Container(
            width: 100,
            height: 1,
            color: _textColor.withValues(alpha: 0.4),
          ),

          const SizedBox(height: 24),
          _buildAuthorAndSource(),
        ],
      ),
    );
  }

  Widget _buildClassicLayout() {
    return Container(
      margin: const EdgeInsets.all(40.0),
      padding: const EdgeInsets.all(32.0),
      decoration: BoxDecoration(
        border: Border.all(color: _textColor.withValues(alpha: 0.3), width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Decorative header
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildClassicDecoration(),
              const SizedBox(width: 16),
              Icon(
                Icons.auto_stories,
                size: 24,
                color: _textColor.withValues(alpha: 0.6),
              ),
              const SizedBox(width: 16),
              _buildClassicDecoration(),
            ],
          ),

          const SizedBox(height: 24),

          Text(
            _quoteController.text.isNotEmpty
                ? _quoteController.text
                : '${AppLocalizations.of(context)!.enter_quote}...',
            style: TextStyle(
              color: _textColor,
              fontSize: _fontSize,
              fontWeight: FontWeight.w500,
              fontFamily: _selectedFont,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Decorative footer
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildClassicDecoration(),
              const SizedBox(width: 16),
              _buildAuthorAndSource(),
              const SizedBox(width: 16),
              _buildClassicDecoration(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildClassicDecoration() {
    return Container(
      width: 30,
      height: 2,
      decoration: BoxDecoration(
        color: _textColor.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildProfileLayout() {
    final user = FirebaseAuth.instance.currentUser;

    // For profile layout, show user info unless explicitly disabled
    final showAvatar = _showUserAvatar;
    final showName = _showUserName;

    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          // User Profile Section
          if (showAvatar || showName)
            Row(
              children: [
                // User Avatar
                if (showAvatar)
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _textColor.withValues(alpha: 0.3),
                        width: 2,
                      ),
                      color: _textColor.withValues(alpha: 0.1),
                    ),
                    child:
                        user?.photoURL != null
                            ? ClipOval(
                              child: Image.network(
                                user!.photoURL!,
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        _buildDefaultAvatar(size: 60),
                              ),
                            )
                            : _buildDefaultAvatar(size: 60),
                  ),
                if (showAvatar && showName) const SizedBox(width: 16),
                // User Info
                if (showName)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDisplayName(),
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: _selectedFont,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.devotee_of_sakshat_savita,
                          style: TextStyle(
                            color: _textColor.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontFamily: _selectedFont,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          // Quote Section
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.format_quote,
                    size: 32,
                    color: _textColor.withValues(alpha: 0.6),
                  ),
                  const SizedBox(height: 12),

                  Text(
                    _quoteController.text.isNotEmpty
                        ? _quoteController.text
                        : '${AppLocalizations.of(context)!.enter_quote}...',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w500,
                      fontFamily: _selectedFont,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),
                  _buildAuthorAndSource(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardLayout() {
    final user = FirebaseAuth.instance.currentUser;
    return Container(
      margin: const EdgeInsets.all(24.0),
      padding: const EdgeInsets.all(28.0),
      decoration: BoxDecoration(
        color: _textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _textColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar and name
          Row(
            children: [
              // User Avatar
              if (_showUserAvatar)
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _textColor.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child:
                      user?.photoURL != null
                          ? ClipOval(
                            child: Image.network(
                              user!.photoURL!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (context, error, stackTrace) =>
                                      _buildDefaultAvatar(size: 48),
                            ),
                          )
                          : _buildDefaultAvatar(size: 48),
                ),
              if (_showUserAvatar && _showUserName) const SizedBox(width: 12),
              // User Name
              if (_showUserName)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getDisplayName(),
                        style: TextStyle(
                          color: _textColor,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: _selectedFont,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)!.sharing_spiritual_wisdom,
                        style: TextStyle(
                          color: _textColor.withValues(alpha: 0.6),
                          fontSize: 11,
                          fontFamily: _selectedFont,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),

          const SizedBox(height: 24),

          // Quote content
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _quoteController.text.isNotEmpty
                        ? _quoteController.text
                        : '${AppLocalizations.of(context)!.enter_quote}...',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w400,
                      fontFamily: _selectedFont,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),
                  _buildAuthorAndSource(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLayout() {
    final user = FirebaseAuth.instance.currentUser;
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        children: [
          // Social media header - only show if user info is enabled
          if (_showUserAvatar || _showUserName)
            Row(
              children: [
                if (_showUserAvatar)
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          _textColor.withValues(alpha: 0.2),
                          _textColor.withValues(alpha: 0.1),
                        ],
                      ),
                    ),
                    child:
                        user?.photoURL != null
                            ? ClipOval(
                              child: Image.network(
                                user!.photoURL!,
                                width: 40,
                                height: 40,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (context, error, stackTrace) =>
                                        _buildDefaultAvatar(size: 40),
                              ),
                            )
                            : _buildDefaultAvatar(size: 40),
                  ),
                if (_showUserAvatar && _showUserName) const SizedBox(width: 12),

                if (_showUserName)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getDisplayName(),
                          style: TextStyle(
                            color: _textColor,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            fontFamily: _selectedFont,
                          ),
                        ),
                        Text(
                          AppLocalizations.of(
                            context,
                          )!.shared_spiritual_thought,
                          style: TextStyle(
                            color: _textColor.withValues(alpha: 0.6),
                            fontSize: 11,
                            fontFamily: _selectedFont,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_showUserAvatar && _showUserName)
                  Icon(
                    Icons.more_horiz,
                    color: _textColor.withValues(alpha: 0.5),
                    size: 20,
                  ),
              ],
            ),

          const SizedBox(height: 24),

          // Quote content
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: _textColor.withValues(alpha: 0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _textColor.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _quoteController.text.isNotEmpty
                        ? _quoteController.text
                        : '${AppLocalizations.of(context)!.enter_quote}...',
                    style: TextStyle(
                      color: _textColor,
                      fontSize: _fontSize,
                      fontWeight: FontWeight.w400,
                      fontFamily: _selectedFont,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 20),
                  _buildAuthorAndSource(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Social actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildSocialAction(Icons.favorite_border, 'Like'),
              _buildSocialAction(Icons.comment_outlined, 'Comment'),
              _buildSocialAction(Icons.share_outlined, 'Share'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStoryLayout() {
    final user = FirebaseAuth.instance.currentUser;
    return SizedBox(
      width: _imageWidth,
      height: _imageHeight,
      child: Stack(
        children: [
          // Background overlay for better text readability
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                // Story header
                Row(
                  children: [
                    if (_showUserAvatar)
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child:
                            user?.photoURL != null
                                ? ClipOval(
                                  child: Image.network(
                                    user!.photoURL!,
                                    width: 36,
                                    height: 36,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (context, error, stackTrace) =>
                                            _buildDefaultAvatar(
                                              size: 36,
                                              isStory: true,
                                            ),
                                  ),
                                )
                                : _buildDefaultAvatar(size: 36, isStory: true),
                      ),
                    if (_showUserAvatar && _showUserName)
                      const SizedBox(width: 8),

                    if (_showUserName)
                      Text(
                        _getDisplayName(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          shadows: [
                            Shadow(
                              offset: Offset(0, 1),
                              blurRadius: 3,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                      ),
                  ],
                ),

                // Quote content in center
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _quoteController.text.isNotEmpty
                              ? _quoteController.text
                              : '${AppLocalizations.of(context)!.enter_quote}...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: _fontSize * 1.1,
                            fontWeight: FontWeight.w500,
                            fontFamily: _selectedFont,
                            height: 1.4,
                            shadows: const [
                              Shadow(
                                offset: Offset(0, 2),
                                blurRadius: 4,
                                color: Colors.black54,
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),

                        if (_authorController.text.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            '— ${_authorController.text}',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: _authorFontSize,
                              fontStyle: FontStyle.italic,
                              fontFamily: _selectedFont,
                              shadows: const [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 3,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // Bottom branding
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_stories,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context)!.sakshatSavita,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        shadows: [
                          Shadow(
                            offset: Offset(0, 1),
                            blurRadius: 3,
                            color: Colors.black54,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDefaultAvatar({double size = 60, bool isStory = false}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color:
            isStory
                ? Colors.white.withValues(alpha: 0.2)
                : _textColor.withValues(alpha: 0.1),
      ),
      child: CircleAvatar(
        backgroundImage: AssetImage('assets/res/z_jogi_swami_avatar.png'),
      ),
    );
  }

  Widget _buildSocialAction(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: _textColor.withValues(alpha: 0.7), size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: _textColor.withValues(alpha: 0.6),
            fontSize: 10,
            fontFamily: _selectedFont,
          ),
        ),
      ],
    );
  }

  Widget _buildUserInfo() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null || (!_showUserAvatar && !_showUserName)) {
      return SizedBox.shrink();
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (_showUserName) ...[
          Text(
            _getDisplayName(),
            style: TextStyle(
              color: _authorColor,
              fontSize: _authorFontSize,
              fontWeight: FontWeight.w600,
              fontFamily: _selectedFont,
              height: 1.2,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
        ],
        if (_showUserAvatar)
          user.photoURL != null
              ? ClipOval(
                child: Image.network(
                  user.photoURL!,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (context, error, stackTrace) => _buildDefaultAvatar(),
                ),
              )
              : _buildDefaultAvatar(size: 40),
        const SizedBox(width: 16),
      ],
    );
  }

  Widget _buildAuthorAndSource() {
    return Column(
      children: [
        // Author
        if (_authorController.text.isNotEmpty)
          Text(
            '— ${_authorController.text}',
            style: TextStyle(
              color: _authorColor,
              fontSize: _authorFontSize,
              fontStyle: FontStyle.italic,
              fontFamily: _selectedFont,
            ),
            textAlign: TextAlign.center,
          ),

        // Source reference (Part and Kiran info)
        if (_currentSelectedQuote != null &&
            _currentSelectedQuote!.partNumber != -1 &&
            _currentSelectedQuote!.kiranIndex != -1) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _textColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _textColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Text(
              'કિરણ ${KiranListService().getKiranTitle(_currentSelectedQuote!.partNumber, _currentSelectedQuote!.kiranIndex)}',
              style: TextStyle(
                color: _textColor.withValues(alpha: 0.8),
                fontSize: 11,
                fontFamily: _selectedFont,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],

        if (_currentSelectedQuote != null &&
            _currentSelectedQuote!.partNumber != -1) ...[
          const SizedBox(height: 12),
          // App branding
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.auto_stories,
                color: _textColor.withValues(alpha: 0.7),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${AppLocalizations.of(context)!.sakshatSavita} : ${Bookservice().getPartTitle(context, _currentSelectedQuote!.partNumber)}',
                style: TextStyle(
                  color: _textColor.withValues(alpha: 0.7),
                  fontSize: 12,
                  fontFamily: _selectedFont,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildGeometricPattern() {
    return CustomPaint(
      painter: GeometricPatternPainter(_textColor.withValues(alpha: 0.1)),
      child: Container(),
    );
  }

  Widget _buildSpiritualPattern() {
    return CustomPaint(
      painter: SpiritualPatternPainter(_textColor.withValues(alpha: 0.08)),
      child: Container(),
    );
  }

  Widget _buildMandalaPattern() {
    return CustomPaint(
      painter: MandalaPatternPainter(_textColor.withValues(alpha: 0.1)),
      child: Container(),
    );
  }

  Widget _buildElegantPattern() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: RadialGradient(
          center: Alignment.topRight,
          radius: 1.5,
          colors: [_textColor.withValues(alpha: 0.05), Colors.transparent],
        ),
      ),
      child: CustomPaint(
        painter: ElegantBorderPainter(_textColor.withValues(alpha: 0.2)),
        child: Container(),
      ),
    );
  }

  Widget _buildModernPattern() {
    return CustomPaint(
      painter: ModernPatternPainter(_textColor.withValues(alpha: 0.06)),
      child: Container(),
    );
  }

  Widget _buildClassicPattern() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _textColor.withValues(alpha: 0.3), width: 2),
      ),
      margin: const EdgeInsets.all(16),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _textColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildProfilePattern() {
    return CustomPaint(
      painter: ProfilePatternPainter(_textColor.withValues(alpha: 0.05)),
      child: Container(),
    );
  }

  Widget _buildCardPattern() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: RadialGradient(
          center: Alignment.bottomLeft,
          radius: 1.2,
          colors: [_textColor.withValues(alpha: 0.08), Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildSocialPattern() {
    return CustomPaint(
      painter: SocialPatternPainter(_textColor.withValues(alpha: 0.04)),
      child: Container(),
    );
  }

  Widget _buildStoryPattern() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _textColor.withValues(alpha: 0.1),
            Colors.transparent,
            _textColor.withValues(alpha: 0.05),
          ],
        ),
      ),
    );
  }

  Widget _buildTextInputSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.quote_content,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            TextField(
              enabled: hasEnableEditing,
              controller: _quoteController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.quote_text,
                hintText: AppLocalizations.of(context)!.enter_quote,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Clear current selected quote when manually editing
                _currentSelectedQuote = null;
                setState(() {});
              },
            ),
            const SizedBox(height: 16),

            TextField(
              enabled: hasEnableEditing,
              controller: _authorController,
              decoration: InputDecoration(
                labelText: AppLocalizations.of(context)!.author,
                hintText: AppLocalizations.of(context)!.quote_author_hint,
                border: const OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Clear current selected quote when manually editing
                _currentSelectedQuote = null;
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomizationSection() {
    return SizedBox(
      height: _imageHeight * 0.4, // Dynamic height based on image height
      child: TabBarView(
        controller: _customizationTabController,
        children: [
          _buildTemplatesTab(),
          _buildColorTab(),
          _buildFontSizeTab(),
          _buildImageSizeTab(),
          _buildUserInfoTab(),
          _buildStickersTab(),
        ],
      ),
    );
  }

  Widget _buildColorTab() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
        bottom: 8.0,
        left: 16.0,
        right: 16.0,
      ),
      child: Wrap(
        spacing: 4.0,
        children:
            _gradients.keys.map((key) => _buildGradientOption(key)).toList(),
      ),
    );
  }

  Widget _buildFontSizeTab() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
        bottom: 8.0,
        left: 16.0,
        right: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.format_size, size: 16),
              const SizedBox(width: 8),
              Text(
                '${AppLocalizations.of(context)!.quote_font}: ${_fontSize.round()}px',
              ),
              Expanded(
                child: Slider(
                  value: _fontSize,
                  min: 16.0,
                  max: 32.0,
                  divisions: 16,
                  onChanged: (value) => setState(() => _fontSize = value),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.person, size: 16),
              const SizedBox(width: 8),
              Text(
                '${AppLocalizations.of(context)!.author_font}: ${_authorFontSize.round()}px',
              ),
              Expanded(
                child: Slider(
                  value: _authorFontSize,
                  min: 12.0,
                  max: 20.0,
                  divisions: 8,
                  onChanged: (value) => setState(() => _authorFontSize = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageSizeTab() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
        bottom: 8.0,
        left: 16.0,
        right: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.height, size: 16),
              const SizedBox(width: 8),
              Text(
                '${AppLocalizations.of(context)!.height_label}: ${_imageHeight.round()}px',
              ),
              Expanded(
                child: Slider(
                  value: _imageHeight,
                  min: 300.0,
                  max: 800.0,
                  divisions: 50,
                  onChanged: (value) => setState(() => _imageHeight = value),
                ),
              ),
            ],
          ),
          Row(
            children: [
              RotatedBox(quarterTurns: 1, child: Icon(Icons.height, size: 16)),
              const SizedBox(width: 8),
              Text(
                '${AppLocalizations.of(context)!.width_label}: ${_imageWidth.round()}px',
              ),
              Expanded(
                child: Slider(
                  value: _imageWidth,
                  min: 300.0,
                  max: 800.0,
                  divisions: 50,
                  onChanged: (value) => setState(() => _imageWidth = value),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoTab() {
    final user = FirebaseAuth.instance.currentUser;
    final hasUserData =
        user != null &&
        (user.displayName != null ||
            user.photoURL != null ||
            (_userProfile != null &&
                _userProfile!.firstName.isNotEmpty &&
                _userProfile!.lastName.isNotEmpty));

    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
        bottom: 8.0,
        left: 16.0,
        right: 16.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasUserData)
            Text(
              AppLocalizations.of(context)!.sign_in_to_show_profile,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
            )
          else ...[
            // Show User Avatar option
            Row(
              children: [
                Icon(Icons.account_circle, size: 16),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.show_avatar),
                Spacer(),
                Switch(
                  value: _showUserAvatar,
                  onChanged: (value) => setState(() => _showUserAvatar = value),
                ),
              ],
            ),
            // Show User Name option
            Row(
              children: [
                Icon(Icons.person, size: 16),
                const SizedBox(width: 8),
                Text(AppLocalizations.of(context)!.show_name),
                Spacer(),
                Switch(
                  value: _showUserName,
                  onChanged:
                      hasUserData &&
                              (user.displayName != null ||
                                  (_userProfile != null &&
                                      _userProfile!.firstName.isNotEmpty &&
                                      _userProfile!.lastName.isNotEmpty))
                          ? (value) => setState(() => _showUserName = value)
                          : null,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStickersTab() {
    return Padding(
      padding: const EdgeInsets.only(
        top: 8.0,
        bottom: 8.0,
        left: 8.0,
        right: 8.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _availableStickers.length,
              itemBuilder: (context, index) {
                final stickerPath = _availableStickers[index];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: GestureDetector(
                    onTap: () => _addSticker(stickerPath),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color:
                              _selectedStickerPath == stickerPath
                                  ? Theme.of(context).primaryColor
                                  : Colors.grey.shade300,
                          width: 2,
                        ),
                      ),
                      child: FutureBuilder(
                        future: _checkAssetExists(stickerPath),
                        builder: (context, snapshot) {
                          if (snapshot.hasData && snapshot.data == true) {
                            return Padding(
                              padding: const EdgeInsets.all(4.0),
                              child: Image.asset(
                                stickerPath,
                                fit: BoxFit.contain,
                              ),
                            );
                          } else {
                            // Fallback icon if asset doesn't exist
                            return Icon(
                              Icons.image,
                              color: Colors.grey.shade400,
                              size: 24,
                            );
                          }
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _checkAssetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (e) {
      return false;
    }
  }

  void _addSticker(String stickerPath) {
    setState(() {
      _selectedStickerPath = stickerPath;
      // Add sticker at center of image
      _stickers.add(
        StickerData(
          assetPath: stickerPath,
          position: Offset(_imageWidth / 2 - 30, _imageHeight / 2 - 30),
          size: 60.0,
        ),
      );
    });
  }

  void _removeSticker(int index) {
    setState(() {
      _stickers.removeAt(index);
    });
  }

  Widget _buildGradientOption(String key) {
    return InkWell(
      onTap: () => setState(() => _selectedGradient = key),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _gradients[key]!,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                _selectedGradient == key
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade400,
            width: _selectedGradient == key ? 3 : 1,
          ),
        ),
        child:
            _selectedGradient == key
                ? const Icon(Icons.check, color: Colors.white)
                : null,
      ),
    );
  }

  Widget _buildPredefinedQuotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.predefined_quotes,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _predefinedQuotes.length,
              itemBuilder: (context, index) {
                final quote = _predefinedQuotes[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(
                      quote.quote,
                      style: const TextStyle(fontSize: 14),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('— ${quote.author}'),
                        Text(
                          '${AppLocalizations.of(context)!.part_label} ${quote.partNumber}, ${AppLocalizations.of(context)!.kiran_label} ${quote.kiranIndex}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.arrow_forward),
                      onPressed: () {
                        String author = _authorController.text;
                        _currentSelectedQuote = quote;
                        _currentSelectedQuote!.setAuthor =
                            author.isEmpty
                                ? (FirebaseAuth
                                        .instance
                                        .currentUser
                                        ?.displayName ??
                                    '')
                                : author;
                        _quoteController.text = quote.quote;
                        _authorController.text = _currentSelectedQuote!.author;
                        setState(() {});
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _shareImage() async {
    // If user is not logged in ask to login
    if (FirebaseAuth.instance.currentUser == null) {
      // Show dialog
      Utils.showLoginWarningDialog(context);
      return;
    }

    try {
      final imageBytes = await _captureImage();
      if (imageBytes != null) {
        final directory = await getTemporaryDirectory();
        final imagePath =
            '${directory.path}/quote_${DateTime.now().millisecondsSinceEpoch}.png';
        final imageFile = File(imagePath);
        await imageFile.writeAsBytes(imageBytes);

        await Share.shareXFiles([
          XFile(imagePath),
        ], text: AppLocalizations.of(context)!.share_text);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.error_sharing_image}: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _saveImage() async {
    // If user is not logged in ask to login
    if (FirebaseAuth.instance.currentUser == null) {
      // Show dialog
      Utils.showLoginWarningDialog(context);
      return;
    }

    try {
      final imageBytes = await _captureImage();
      if (imageBytes != null) {
        // Save directly to the device gallery
        await Gal.putImageBytes(
          imageBytes,
          album: AppLocalizations.of(context)!.album_name,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)!.image_saved),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.error_saving_image(e.toString()),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<Uint8List?> _captureImage() async {
    try {
      RenderRepaintBoundary boundary =
          _repaintBoundaryKey.currentContext!.findRenderObject()
              as RenderRepaintBoundary;

      ui.Image image = await boundary.toImage(pixelRatio: 2.0);
      ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing image: $e');
      return null;
    }
  }
}

// Custom painter for geometric pattern
class GeometricPatternPainter extends CustomPainter {
  final Color color;

  GeometricPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    // Draw geometric pattern
    for (int i = 0; i < 10; i++) {
      for (int j = 0; j < 10; j++) {
        final x = (size.width / 10) * i;
        final y = (size.height / 10) * j;
        canvas.drawCircle(Offset(x, y), 20, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for spiritual pattern (Om symbols and lotus)
class SpiritualPatternPainter extends CustomPainter {
  final Color color;

  SpiritualPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    // Draw Om symbols in corners
    _drawOmSymbol(canvas, const Offset(50, 50), paint);
    _drawOmSymbol(canvas, Offset(size.width - 50, 50), paint);
    _drawOmSymbol(canvas, Offset(50, size.height - 50), paint);
    _drawOmSymbol(canvas, Offset(size.width - 50, size.height - 50), paint);

    // Draw lotus petals around the center
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (3.14159 / 180);
      _drawLotusPetal(canvas, center, angle, paint);
    }
  }

  void _drawOmSymbol(Canvas canvas, Offset center, Paint paint) {
    // Simplified Om symbol representation
    final path = Path();
    path.addOval(Rect.fromCircle(center: center, radius: 15));
    path.moveTo(center.dx - 10, center.dy);
    path.lineTo(center.dx + 10, center.dy);
    canvas.drawPath(path, paint);
  }

  void _drawLotusPetal(
    Canvas canvas,
    Offset center,
    double angle,
    Paint paint,
  ) {
    final path = Path();
    final petalLength = 30.0;
    final x = center.dx + (petalLength * 1.5 * cos(angle));
    final y = center.dy + (petalLength * 1.5 * sin(angle));

    path.moveTo(center.dx, center.dy);
    path.quadraticBezierTo(
      x,
      y,
      center.dx + (petalLength * cos(angle + 0.3)),
      center.dy + (petalLength * sin(angle + 0.3)),
    );
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for mandala pattern
class MandalaPatternPainter extends CustomPainter {
  final Color color;

  MandalaPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw concentric circles
    for (int i = 1; i <= 6; i++) {
      canvas.drawCircle(center, i * 30.0, paint);
    }

    // Draw radiating lines
    for (int i = 0; i < 12; i++) {
      final angle = (i * 30) * (3.14159 / 180);
      final x1 = center.dx + (60 * cos(angle));
      final y1 = center.dy + (60 * sin(angle));
      final x2 = center.dx + (180 * cos(angle));
      final y2 = center.dy + (180 * sin(angle));
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }

    // Draw decorative dots
    for (int ring = 0; ring < 3; ring++) {
      final radius = 80.0 + (ring * 40);
      for (int i = 0; i < 8; i++) {
        final angle = (i * 45) * (3.14159 / 180);
        final x = center.dx + (radius * cos(angle));
        final y = center.dy + (radius * sin(angle));
        canvas.drawCircle(Offset(x, y), 3, paint..style = PaintingStyle.fill);
      }
    }
    paint.style = PaintingStyle.stroke;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for elegant border pattern
class ElegantBorderPainter extends CustomPainter {
  final Color color;

  ElegantBorderPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    // Draw corner decorations
    _drawCornerDecoration(canvas, const Offset(20, 20), paint);
    _drawCornerDecoration(
      canvas,
      Offset(size.width - 20, 20),
      paint,
      flipX: true,
    );
    _drawCornerDecoration(
      canvas,
      Offset(20, size.height - 20),
      paint,
      flipY: true,
    );
    _drawCornerDecoration(
      canvas,
      Offset(size.width - 20, size.height - 20),
      paint,
      flipX: true,
      flipY: true,
    );

    // Draw side decorations
    final centerY = size.height / 2;
    final centerX = size.width / 2;

    _drawSideDecoration(canvas, Offset(10, centerY), paint);
    _drawSideDecoration(
      canvas,
      Offset(size.width - 10, centerY),
      paint,
      flipX: true,
    );
    _drawSideDecoration(canvas, Offset(centerX, 10), paint, rotate: true);
    _drawSideDecoration(
      canvas,
      Offset(centerX, size.height - 10),
      paint,
      rotate: true,
      flipY: true,
    );
  }

  void _drawCornerDecoration(
    Canvas canvas,
    Offset center,
    Paint paint, {
    bool flipX = false,
    bool flipY = false,
  }) {
    final path = Path();
    final size = 15.0;

    double x1 = center.dx + (flipX ? -size : size);
    double y1 = center.dy;
    double x2 = center.dx;
    double y2 = center.dy + (flipY ? -size : size);

    path.moveTo(center.dx, center.dy);
    path.lineTo(x1, y1);
    path.moveTo(center.dx, center.dy);
    path.lineTo(x2, y2);

    // Add small decorative curves
    path.addArc(
      Rect.fromCircle(
        center: Offset(x1 + (flipX ? 5 : -5), center.dy),
        radius: 3,
      ),
      0,
      6.28,
    );
    path.addArc(
      Rect.fromCircle(
        center: Offset(center.dx, y2 + (flipY ? 5 : -5)),
        radius: 3,
      ),
      0,
      6.28,
    );

    canvas.drawPath(path, paint);
  }

  void _drawSideDecoration(
    Canvas canvas,
    Offset center,
    Paint paint, {
    bool flipX = false,
    bool flipY = false,
    bool rotate = false,
  }) {
    final path = Path();
    final size = 10.0;

    if (rotate) {
      // Vertical decoration
      path.moveTo(center.dx, center.dy + (flipY ? size : -size));
      path.quadraticBezierTo(
        center.dx + size / 2,
        center.dy,
        center.dx,
        center.dy + (flipY ? -size : size),
      );
    } else {
      // Horizontal decoration
      path.moveTo(center.dx + (flipX ? size : -size), center.dy);
      path.quadraticBezierTo(
        center.dx,
        center.dy + size / 2,
        center.dx + (flipX ? -size : size),
        center.dy,
      );
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for modern pattern
class ModernPatternPainter extends CustomPainter {
  final Color color;

  ModernPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    // Draw modern geometric shapes
    for (int i = 0; i < 15; i++) {
      final x = (i * 50.0) % size.width;
      final y = ((i * 37.0) % size.height);

      // Alternate between different shapes
      switch (i % 4) {
        case 0:
          canvas.drawRect(Rect.fromLTWH(x, y, 20, 20), paint);
          break;
        case 1:
          canvas.drawCircle(Offset(x + 10, y + 10), 8, paint);
          break;
        case 2:
          final path = Path();
          path.moveTo(x + 10, y);
          path.lineTo(x + 20, y + 20);
          path.lineTo(x, y + 20);
          path.close();
          canvas.drawPath(path, paint);
          break;
        case 3:
          final rect = Rect.fromLTWH(x, y, 15, 15);
          canvas.drawArc(
            rect,
            0,
            3.14159,
            false,
            paint..style = PaintingStyle.stroke,
          );
          paint.style = PaintingStyle.fill;
          break;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for profile pattern
class ProfilePatternPainter extends CustomPainter {
  final Color color;

  ProfilePatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;

    // Draw subtle connection lines
    for (int i = 0; i < 5; i++) {
      final startX = (i * size.width / 5) + (size.width * 0.1);
      final startY = size.height * 0.2;
      final endX = ((i + 1) * size.width / 5) + (size.width * 0.05);
      final endY = size.height * 0.8;

      final path = Path();
      path.moveTo(startX, startY);
      path.quadraticBezierTo(size.width * 0.5, size.height * 0.4, endX, endY);
      canvas.drawPath(path, paint);
    }

    // Draw decorative circles
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (pi / 180);
      final radius = size.width * 0.3;
      final x = size.width * 0.5 + (radius * cos(angle));
      final y = size.height * 0.5 + (radius * sin(angle));
      canvas.drawCircle(Offset(x, y), 2, paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Custom painter for social pattern
class SocialPatternPainter extends CustomPainter {
  final Color color;

  SocialPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    // Draw social network nodes
    final nodePositions = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.1, size.height * 0.7),
      Offset(size.width * 0.9, size.height * 0.8),
      Offset(size.width * 0.5, size.height * 0.1),
      Offset(size.width * 0.3, size.height * 0.9),
    ];

    // Draw connections
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.5;
    for (int i = 0; i < nodePositions.length; i++) {
      for (int j = i + 1; j < nodePositions.length; j++) {
        if ((nodePositions[i] - nodePositions[j]).distance < size.width * 0.4) {
          canvas.drawLine(nodePositions[i], nodePositions[j], paint);
        }
      }
    }

    // Draw nodes
    paint.style = PaintingStyle.fill;
    for (final position in nodePositions) {
      canvas.drawCircle(position, 3, paint);
    }

    // Draw hashtag symbols
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    _drawHashtag(canvas, Offset(size.width * 0.15, size.height * 0.15), paint);
    _drawHashtag(canvas, Offset(size.width * 0.85, size.height * 0.85), paint);
  }

  void _drawHashtag(Canvas canvas, Offset center, Paint paint) {
    final size = 8.0;
    // Vertical lines
    canvas.drawLine(
      Offset(center.dx - size / 3, center.dy - size / 2),
      Offset(center.dx - size / 3, center.dy + size / 2),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx + size / 3, center.dy - size / 2),
      Offset(center.dx + size / 3, center.dy + size / 2),
      paint,
    );
    // Horizontal lines
    canvas.drawLine(
      Offset(center.dx - size / 2, center.dy - size / 3),
      Offset(center.dx + size / 2, center.dy - size / 3),
      paint,
    );
    canvas.drawLine(
      Offset(center.dx - size / 2, center.dy + size / 3),
      Offset(center.dx + size / 2, center.dy + size / 3),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Miniature pattern painters for template previews
class MiniGeometricPatternPainter extends CustomPainter {
  final Color color;

  MiniGeometricPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    // Draw simplified geometric pattern
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 4; j++) {
        final x = (size.width / 4) * i;
        final y = (size.height / 4) * j;
        canvas.drawCircle(Offset(x, y), 3, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MiniSpiritualPatternPainter extends CustomPainter {
  final Color color;

  MiniSpiritualPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    // Draw simplified Om symbols in corners
    canvas.drawCircle(const Offset(10, 10), 3, paint);
    canvas.drawCircle(Offset(size.width - 10, 10), 3, paint);
    canvas.drawCircle(Offset(10, size.height - 10), 3, paint);
    canvas.drawCircle(Offset(size.width - 10, size.height - 10), 3, paint);

    // Draw center lotus-like pattern
    final center = Offset(size.width / 2, size.height / 2);
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * (pi / 180);
      final x = center.dx + (8 * cos(angle));
      final y = center.dy + (8 * sin(angle));
      canvas.drawLine(center, Offset(x, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MiniMandalaPatternPainter extends CustomPainter {
  final Color color;

  MiniMandalaPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw concentric circles
    for (int i = 1; i <= 3; i++) {
      canvas.drawCircle(center, i * 8.0, paint);
    }

    // Draw radiating lines
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * (pi / 180);
      final x1 = center.dx + (12 * cos(angle));
      final y1 = center.dy + (12 * sin(angle));
      final x2 = center.dx + (24 * cos(angle));
      final y2 = center.dy + (24 * sin(angle));
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MiniProfilePatternPainter extends CustomPainter {
  final Color color;

  MiniProfilePatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.3;

    // Draw simplified connection lines
    for (int i = 0; i < 3; i++) {
      final startX = (i * size.width / 3) + 5;
      final startY = size.height * 0.3;
      final endX = ((i + 1) * size.width / 3);
      final endY = size.height * 0.7;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }

    // Draw decorative dots
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * (pi / 180);
      final x = size.width * 0.5 + (12 * cos(angle));
      final y = size.height * 0.5 + (12 * sin(angle));
      canvas.drawCircle(Offset(x, y), 1, paint..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class MiniSocialPatternPainter extends CustomPainter {
  final Color color;

  MiniSocialPatternPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = color
          ..style = PaintingStyle.fill;

    // Draw social network nodes
    final nodePositions = [
      Offset(size.width * 0.2, size.height * 0.3),
      Offset(size.width * 0.8, size.height * 0.2),
      Offset(size.width * 0.3, size.height * 0.8),
      Offset(size.width * 0.7, size.height * 0.7),
    ];

    // Draw simplified connections
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.3;
    for (int i = 0; i < nodePositions.length - 1; i++) {
      canvas.drawLine(nodePositions[i], nodePositions[i + 1], paint);
    }

    // Draw nodes
    paint.style = PaintingStyle.fill;
    for (final position in nodePositions) {
      canvas.drawCircle(position, 1.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
