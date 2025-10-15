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
import 'package:share_plus/share_plus.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/inspirational_quote_model.dart';
import 'package:gal/gal.dart';

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
  double _imageHeight = 300.0;
  double _imageWidth = 300.0;
  int _selectedTemplate = 0;
  String _selectedGradient = 'green';

  // Current quote reference
  InspirationalQuote? _currentSelectedQuote;

  bool hasEnableEditing = false;

  // Predefined inspirational quotes
  final List<InspirationalQuote> _predefinedQuotes = [
    InspirationalQuote(
      quote: '🙏 આત્મા સાથે જોડાવું એ જીવનની સૌથી મોટી સિદ્ધિ છે.',
      author: '',
      partNumber: -1,
      kiranIndex: -1,
    ),
    InspirationalQuote(
      quote: '📖 દરરોજ અધ્યાત્મિક વાંચન તમારા જીવનમાં પ્રકાશ લાવે છે.',
      author: '',
      partNumber: -1,
      kiranIndex: -1,
    ),
    InspirationalQuote(
      quote: '✨ શાંતિ બહારથી નહીં, અંદરથી આવે છે.',
      author: '',
      partNumber: -1,
      kiranIndex: -1,
    ),
    InspirationalQuote(
      quote: '🌅 દરેક નવો દિવસ આત્મિક વૃદ્ધિની તક છે.',
      author: '',
      partNumber: -1,
      kiranIndex: -1,
    ),
    InspirationalQuote(
      quote: '💫 સત્ય, પ્રેમ અને કરુણા - આ ત્રણે જીવનના આધાર છે.',
      author: '',
      partNumber: -1,
      kiranIndex: -1,
    ),
  ];

  // Color gradients
  final Map<String, List<Color>> _gradients = {
    'green': [const Color(0xFF2E7D32), const Color(0xFF4CAF50)],
    'blue': [const Color(0xFF1565C0), const Color(0xFF42A5F5)],
    'purple': [const Color(0xFF6A1B9A), const Color(0xFFAB47BC)],
    'orange': [Colors.deepOrange.shade700, Colors.orange.shade400],
    'teal': [Colors.teal.shade700, Colors.teal.shade400],
    'indigo': [Colors.indigo.shade700, Colors.indigo.shade400],
    'saffron': [const Color(0xFFFF6F00), const Color(0xFFFFB74D)],
    'spiritual': [const Color(0xFF8E24AA), const Color(0xFFBA68C8)],
  };

  @override
  void initState() {
    super.initState();
    _customizationTabController = TabController(length: 3, vsync: this);
    // Set first predefined quote as default
    if (widget.quote != null) {
      _currentSelectedQuote = widget.quote;
      _quoteController.text = widget.quote!.quote;
      _authorController.text = widget.quote!.author;
      hasEnableEditing = false;
    } else {
      hasEnableEditing = true;
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
          author.isEmpty
              ? (FirebaseAuth.instance.currentUser?.displayName ?? '')
              : author;
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
            icon: const Icon(Icons.share),
            onPressed: _shareImage,
            tooltip: AppLocalizations.of(context)!.share_quote,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _saveImage,
            tooltip: AppLocalizations.of(context)!.save_quote,
          ),
        ],
        bottom: TabBar(
          controller: _customizationTabController,
          tabs: const [
            Tab(icon: Icon(Icons.palette), text: 'Colors'),
            Tab(icon: Icon(Icons.text_fields), text: 'Font Size'),
            Tab(icon: Icon(Icons.photo_size_select_large), text: 'Image Size'),
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
              _buildPreviewSection(),
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

  Widget _buildPreviewSection() {
    final templates = [
      {'name': 'Profile', 'index': 8},
      {'name': 'Card', 'index': 9},
      {'name': 'Simple', 'index': 0},
      {'name': 'Geometric', 'index': 1},
      {'name': 'Floral', 'index': 2},
      {'name': 'Spiritual', 'index': 3},
      {'name': 'Mandala', 'index': 4},
      {'name': 'Elegant', 'index': 5},
      {'name': 'Modern', 'index': 6},
      {'name': 'Classic', 'index': 7},
      {'name': 'Social', 'index': 10},
      {'name': 'Story', 'index': 11},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Preview', style: Theme.of(context).textTheme.titleLarge),
              Text(
                'Swipe to see all templates →',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: _imageHeight + 60,
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
                    children: [
                      // Template preview
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color:
                                isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey.shade300,
                            width: isSelected ? 3 : 0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  isSelected
                                      ? Theme.of(
                                        context,
                                      ).colorScheme.primary.withOpacity(0.3)
                                      : Colors.black.withOpacity(0.1),
                              blurRadius: isSelected ? 12 : 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: RepaintBoundary(
                          key: isSelected ? _repaintBoundaryKey : GlobalKey(),
                          child: _buildQuoteImageForTemplate(templateIndex),
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
          if (templateIndex == 2) _buildFloralPattern(),
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
          // Quote mark
          Row(
            children: [
              Transform.flip(
                flipY: false,
                flipX: true,
                child: Icon(
                  Icons.format_quote,
                  size: 48,
                  color: _textColor.withOpacity(0.3),
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
                color: _textColor.withOpacity(0.3),
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
            color: _textColor.withOpacity(0.8),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: _textColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _textColor.withOpacity(0.2),
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
            color: _textColor.withOpacity(0.05),
            border: Border.all(color: _textColor.withOpacity(0.3), width: 2),
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
              color: _textColor.withOpacity(0.3),
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
          Container(width: 100, height: 1, color: _textColor.withOpacity(0.4)),

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
        border: Border.all(color: _textColor.withOpacity(0.3), width: 2),
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
                color: _textColor.withOpacity(0.6),
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
        color: _textColor.withOpacity(0.4),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }

  Widget _buildProfileLayout() {
    final user = FirebaseAuth.instance.currentUser;
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        children: [
          // User Profile Section
          Row(
            children: [
              // User Avatar
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _textColor.withOpacity(0.3),
                    width: 2,
                  ),
                  color: _textColor.withOpacity(0.1),
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
                                    _buildDefaultAvatar(),
                          ),
                        )
                        : _buildDefaultAvatar(),
              ),
              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Spiritual Seeker',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        fontFamily: _selectedFont,
                      ),
                    ),
                    Text(
                      'Devotee of ${AppLocalizations.of(context)!.sakshatSavita}',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.7),
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
                    color: _textColor.withOpacity(0.6),
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
        color: _textColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _textColor.withOpacity(0.2), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with avatar and name
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _textColor.withOpacity(0.3),
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
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Spiritual Seeker',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: _selectedFont,
                      ),
                    ),
                    Text(
                      'Sharing Spiritual Wisdom',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.6),
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
          // Social media header
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      _textColor.withOpacity(0.2),
                      _textColor.withOpacity(0.1),
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
              const SizedBox(width: 12),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.displayName ?? 'Spiritual Seeker',
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: _selectedFont,
                      ),
                    ),
                    Text(
                      'shared a spiritual thought',
                      style: TextStyle(
                        color: _textColor.withOpacity(0.6),
                        fontSize: 11,
                        fontFamily: _selectedFont,
                      ),
                    ),
                  ],
                ),
              ),

              Icon(
                Icons.more_horiz,
                color: _textColor.withOpacity(0.5),
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
                color: _textColor.withOpacity(0.03),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _textColor.withOpacity(0.1),
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
                  Colors.black.withOpacity(0.3),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withOpacity(0.5),
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
                    const SizedBox(width: 8),

                    Text(
                      user?.displayName ?? 'Spiritual Seeker',
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
                              color: Colors.white.withOpacity(0.9),
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
                ? Colors.white.withOpacity(0.2)
                : _textColor.withOpacity(0.1),
      ),
      child: Icon(
        Icons.person,
        size: size * 0.6,
        color:
            isStory
                ? Colors.white.withOpacity(0.8)
                : _textColor.withOpacity(0.6),
      ),
    );
  }

  Widget _buildSocialAction(IconData icon, String label) {
    return Column(
      children: [
        Icon(icon, color: _textColor.withOpacity(0.7), size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: _textColor.withOpacity(0.6),
            fontSize: 10,
            fontFamily: _selectedFont,
          ),
        ),
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
              color: _textColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _textColor.withOpacity(0.3), width: 1),
            ),
            child: Text(
              'કિરણ ${KiranListService().getKiranTitle(_currentSelectedQuote!.partNumber, _currentSelectedQuote!.kiranIndex)}',
              style: TextStyle(
                color: _textColor.withOpacity(0.8),
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
                color: _textColor.withOpacity(0.7),
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                '${AppLocalizations.of(context)!.sakshatSavita} : ${Bookservice().getPartTitle(context, _currentSelectedQuote!.partNumber)}',
                style: TextStyle(
                  color: _textColor.withOpacity(0.7),
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
      painter: GeometricPatternPainter(_textColor.withOpacity(0.1)),
      child: Container(),
    );
  }

  Widget _buildFloralPattern() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.1,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: const DecorationImage(
              image: AssetImage('assets/res/pattern_floral.png'),
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpiritualPattern() {
    return CustomPaint(
      painter: SpiritualPatternPainter(_textColor.withOpacity(0.08)),
      child: Container(),
    );
  }

  Widget _buildMandalaPattern() {
    return CustomPaint(
      painter: MandalaPatternPainter(_textColor.withOpacity(0.1)),
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
          colors: [_textColor.withOpacity(0.05), Colors.transparent],
        ),
      ),
      child: CustomPaint(
        painter: ElegantBorderPainter(_textColor.withOpacity(0.2)),
        child: Container(),
      ),
    );
  }

  Widget _buildModernPattern() {
    return CustomPaint(
      painter: ModernPatternPainter(_textColor.withOpacity(0.06)),
      child: Container(),
    );
  }

  Widget _buildClassicPattern() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _textColor.withOpacity(0.3), width: 2),
      ),
      margin: const EdgeInsets.all(16),
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _textColor.withOpacity(0.2), width: 1),
        ),
      ),
    );
  }

  Widget _buildProfilePattern() {
    return CustomPaint(
      painter: ProfilePatternPainter(_textColor.withOpacity(0.05)),
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
          colors: [_textColor.withOpacity(0.08), Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildSocialPattern() {
    return CustomPaint(
      painter: SocialPatternPainter(_textColor.withOpacity(0.04)),
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
            _textColor.withOpacity(0.1),
            Colors.transparent,
            _textColor.withOpacity(0.05),
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
      height: 112, // Fixed height for tab content
      child: TabBarView(
        controller: _customizationTabController,
        children: [_buildColorTab(), _buildFontSizeTab(), _buildImageSizeTab()],
      ),
    );
  }

  Widget _buildColorTab() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        spacing: 4.0,
        children:
            _gradients.keys.map((key) => _buildGradientOption(key)).toList(),
      ),
    );
  }

  Widget _buildFontSizeTab() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quote: ${_fontSize.round()}px'),
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
              Text('Author: ${_authorFontSize.round()}px'),
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
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Height: ${_imageHeight.round()}px'),
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
              Text('Width: ${_imageWidth.round()}px'),
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
              'Predefined Spiritual Quotes',
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
                          'Part ${quote.partNumber}, Kiran ${quote.kiranIndex}',
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
        ], text: 'Inspirational quote generated with Sakshat Savita app');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error sharing image: $e')));
      }
    }
  }

  Future<void> _saveImage() async {
    try {
      final imageBytes = await _captureImage();
      if (imageBytes != null) {
        // Save directly to the device gallery
        await Gal.putImageBytes(imageBytes, album: 'Sakshat Savita Quotes');

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
            content: Text('Error saving image: $e'),
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
