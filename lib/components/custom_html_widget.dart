import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/services/customtagregistry.dart';
import 'package:saxatsavita_flutter/components/custom_text_selection_controls.dart';

class CustomHtmlWidget extends StatefulWidget {
  CustomHtmlWidget({
    super.key,
    required this.htmlContent,
    this.onAddNote,
    this.hasAddNoteButton = true,
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
  final bool hasAddNoteButton;
  final void Function(String)? onAddNote;

  final CustomTagRegistry customTagRegistry = CustomTagRegistry();

  @override
  State<CustomHtmlWidget> createState() => _CustomHtmlWidgetState();
}

class _CustomHtmlWidgetState extends State<CustomHtmlWidget> {
  String _selectedText = '';

  void _handleAddNote(String selectedText) {
    debugPrint('Add note for selected text: "$selectedText"');
    widget.onAddNote?.call(selectedText);
    // TODO: Implement your note functionality here
    // For example, navigate to note editor or show a dialog
    // Navigator.push(context, MaterialPageRoute(builder: (_) => NoteEditor(text: selectedText)));
  }

  @override
  Widget build(BuildContext context) {
    Color fontColor = Theme.of(context).colorScheme.primary;
    String htmlContent = widget.htmlContent.replaceAll('&nbsp; &nbsp;', '⠀ ');
    return ValueListenableBuilder<AppSettings>(
      valueListenable: appSettingsNotifier,
      builder: (context, settings, child) {
        return SelectionArea(
          selectionControls: CustomTextSelectionControls(
            hasAddNoteButton: widget.hasAddNoteButton,
            onAddNote: () {
              if (_selectedText.isNotEmpty) {
                _handleAddNote(_selectedText);
              }
            },
          ),
          onSelectionChanged: (selection) {
            if (selection != null) {
              _selectedText = selection.plainText;
              debugPrint('Selected text updated: "$_selectedText"');
            } else {
              _selectedText = '';
            }
          },
          child: Html(
            data: htmlContent,
            extensions: [...widget.customTagRegistry.buildExtensions(context)],
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
          ),
        );
      },
    );
  }
}
