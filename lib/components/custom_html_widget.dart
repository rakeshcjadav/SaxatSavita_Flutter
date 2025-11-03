import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/services/customtagregistry.dart';

class CustomHtmlWidget extends StatefulWidget {
  CustomHtmlWidget({
    super.key,
    required this.htmlContent,
    this.onAddNote,
    this.onCreateQuoteImage,
    this.onSingleTap,
  }) {
    // Initialize the custom tag registry if needed
    // This can be used to register custom HTML tags for rendering
    // For example, you can register a custom tag for <slok> or <dq>
    // to style them differently in the HTML content.
    // Here, we are just creating an instance of CustomTagRegistry.
    // You can expand this as per your requirements.
    customTagRegistry.registerCustomTags();
  }

  final String htmlContent;
  final void Function(String)? onAddNote;
  final void Function(String)? onCreateQuoteImage;
  final void Function()? onSingleTap;

  final CustomTagRegistry customTagRegistry = CustomTagRegistry();

  @override
  State<CustomHtmlWidget> createState() => _CustomHtmlWidgetState();
}

class _CustomHtmlWidgetState extends State<CustomHtmlWidget> {
  String _selectedText = '';
  bool _isTextSelected = false;

  void _handleAddNote(String selectedText) {
    debugPrint('Add note for selected text: "$selectedText"');
    widget.onAddNote?.call(selectedText);
  }

  void _handleCreateQuoteImage(String selectedText) {
    debugPrint('Create quote image for selected text: "$selectedText"');
    widget.onCreateQuoteImage?.call(selectedText);
  }

  @override
  Widget build(BuildContext context) {
    Color fontColor = Theme.of(context).colorScheme.primary;
    String htmlContent = widget.htmlContent.replaceAll('&nbsp; &nbsp;', '⠀ ');
    return SelectionArea(
      onSelectionChanged: (selection) {
        if (selection != null) {
          _selectedText = selection.plainText;
          _isTextSelected = _selectedText.isNotEmpty;
          debugPrint('Selected text updated: "$_selectedText"');
        } else {
          _selectedText = '';
          _isTextSelected = false;
        }
      },
      contextMenuBuilder: (
        context,
        SelectableRegionState selectableRegionState,
      ) {
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: selectableRegionState.contextMenuAnchors,
          buttonItems: [
            if (widget.onAddNote != null)
              ContextMenuButtonItem(
                onPressed: () {
                  if (_selectedText.isNotEmpty) {
                    _handleAddNote(_selectedText);
                  }
                },
                label: AppLocalizations.of(context)!.add_notes,
              ),
            if (widget.onCreateQuoteImage != null)
              ContextMenuButtonItem(
                onPressed: () {
                  if (_selectedText.isNotEmpty) {
                    _handleCreateQuoteImage(_selectedText);
                  }
                },
                label: AppLocalizations.of(context)!.create_quote_image,
              ),
            ...selectableRegionState.contextMenuButtonItems,
          ],
        );
      },
      child: GestureDetector(
        behavior: _isTextSelected ? null : HitTestBehavior.translucent,
        onDoubleTap: () {
          if (_isTextSelected) {
            // Clear selection by rebuilding the widget
            setState(() {
              _selectedText = '';
              _isTextSelected = false;
            });
            return;
          }

          debugPrint('CustomHtmlWidget tapped');
          widget.onSingleTap?.call();
        },
        child: ValueListenableBuilder<AppSettings>(
          valueListenable: appSettingsNotifier,
          builder: (context, settings, child) {
            return Html(
              data: htmlContent,
              extensions: [
                ...widget.customTagRegistry.buildExtensions(context),
              ],
              style: {
                "body": Style(
                  color: fontColor,
                  fontSize: FontSize(
                    Theme.of(context).textTheme.bodyLarge!.fontSize!,
                  ),
                  textAlign: TextAlign.justify,
                  lineHeight: LineHeight(appSettingsNotifier.value.lineHeight),
                ),
              },
            );
          },
        ),
      ),
    );
  }
}
