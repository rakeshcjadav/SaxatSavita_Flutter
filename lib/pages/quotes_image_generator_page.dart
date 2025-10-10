import 'dart:io';
import 'dart:ui' as ui;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
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

class _QuotesImageGeneratorPageState extends State<QuotesImageGeneratorPage> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  final TextEditingController _quoteController = TextEditingController();
  final TextEditingController _authorController = TextEditingController();

  // Customization options
  Color _textColor = Colors.white;
  Color _authorColor = Colors.white70;
  String _selectedFont = 'NotoSansGujarati';
  double _fontSize = 24.0;
  double _authorFontSize = 16.0;
  double _imageHeight = 600.0;
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
  };

  @override
  void initState() {
    super.initState();
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
    /*if (_predefinedQuotes.isNotEmpty) {
      _currentSelectedQuote = _predefinedQuotes[0];
      _quoteController.text = _predefinedQuotes[0].quote;
      _authorController.text = _predefinedQuotes[0].author;
    }*/
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
    _quoteController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.quotes_image_generator),
        elevation: 0,
        actions: [
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
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Customization Section
              _buildCustomizationSection(),
              const SizedBox(height: 12),

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
    return Card(
      elevation: 8,
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text('  Preview', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Center(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: RepaintBoundary(
                  key: _repaintBoundaryKey,
                  child: _buildQuoteImage(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuoteImage() {
    return Container(
      width: 400,
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
          if (_selectedTemplate == 1) _buildGeometricPattern(),
          if (_selectedTemplate == 2) _buildFloralPattern(),

          // Main content
          Padding(
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
                Expanded(
                  child: Center(
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _textColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _textColor.withOpacity(0.3),
                        width: 1,
                      ),
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
            ),
          ),
        ],
      ),
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.customization,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Template selection
            Text(
              '${AppLocalizations.of(context)!.template_style}:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildTemplateOption('Simple', 0),
                const SizedBox(width: 8),
                _buildTemplateOption('Geometric', 1),
                const SizedBox(width: 8),
                _buildTemplateOption('Floral', 2),
              ],
            ),
            const SizedBox(height: 16),

            // Color gradient selection
            Text(
              AppLocalizations.of(context)!.background,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children:
                  _gradients.keys
                      .map((key) => _buildGradientOption(key))
                      .toList(),
            ),
            const SizedBox(height: 16),

            // Font size sliders
            Text(
              '${AppLocalizations.of(context)!.quote_font_size}:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text('Quote: ${_fontSize.round()}px'),
            Slider(
              value: _fontSize,
              min: 16.0,
              max: 32.0,
              divisions: 16,
              onChanged: (value) => setState(() => _fontSize = value),
            ),
            Text('Author: ${_authorFontSize.round()}px'),
            Slider(
              value: _authorFontSize,
              min: 12.0,
              max: 20.0,
              divisions: 8,
              onChanged: (value) => setState(() => _authorFontSize = value),
            ),
            const SizedBox(height: 16),

            // Image height slider
            Text('Image Height: ${_imageHeight.round()}px'),
            Slider(
              value: _imageHeight,
              min: 300.0,
              max: 800.0,
              divisions: 50,
              onChanged: (value) => setState(() => _imageHeight = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateOption(String title, int index) {
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTemplate = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
          decoration: BoxDecoration(
            color:
                _selectedTemplate == index
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color:
                  _selectedTemplate == index
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade400,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              color:
                  _selectedTemplate == index
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade700,
              fontWeight:
                  _selectedTemplate == index
                      ? FontWeight.bold
                      : FontWeight.normal,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildGradientOption(String key) {
    return InkWell(
      onTap: () => setState(() => _selectedGradient = key),
      child: Container(
        width: 50,
        height: 50,
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
