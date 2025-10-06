import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

class NoteEditorPage extends StatefulWidget {
  const NoteEditorPage({
    super.key,
    required this.kiranUserInfo,
    required this.kiranTitle,
  });

  final KiranUserInfo kiranUserInfo;
  final String kiranTitle;

  @override
  State<NoteEditorPage> createState() => _NoteEditorPageState();
}

class _NoteEditorPageState extends State<NoteEditorPage> {
  late QuillController _controller;
  final FocusNode _focusNode = FocusNode();
  bool _isModified = false;
  late QuillToolbarToggleStyleButtonOptions buttonOptions;

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  void setToolbarTheme() {
    buttonOptions = QuillToolbarToggleStyleButtonOptions(
      iconTheme: QuillIconTheme(
        iconButtonUnselectedData: IconButtonData(
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
            disabledForegroundColor: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        iconButtonSelectedData: IconButtonData(
          style: IconButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            backgroundColor: Theme.of(context).colorScheme.primary,
            disabledForegroundColor: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  void _initializeController() {
    try {
      // Initialize the controller with existing note content or empty document
      Document document = Document();

      if (widget.kiranUserInfo.note != null &&
          widget.kiranUserInfo.note!.isNotEmpty) {
        try {
          // Try to parse existing note as Quill delta JSON
          final dynamic decoded = jsonDecode(widget.kiranUserInfo.note!);
          if (decoded is List) {
            document = Document.fromJson(decoded);
          } else {
            // If not a proper delta format, treat as plain text
            document = Document()..insert(0, widget.kiranUserInfo.note!);
          }
        } catch (e) {
          debugPrint('Error parsing note: $e');
          // If parsing fails, treat as plain text
          document = Document()..insert(0, widget.kiranUserInfo.note!);
        }
      }

      _controller = QuillController(
        document: document,
        selection: const TextSelection.collapsed(offset: 0),
      );

      // Add listener to track changes
      _controller.addListener(_onDocumentChanged);
    } catch (e) {
      debugPrint('Error initializing controller: $e');
      // Fallback to empty document
      _controller = QuillController.basic();
      _controller.addListener(_onDocumentChanged);
    }
  }

  void _onDocumentChanged() {
    if (!_isModified) {
      setState(() {
        _isModified = true;
      });
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onDocumentChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (!_isModified) {
      return true;
    }

    final shouldPop = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              AppLocalizations.of(context)!.menu_four,
            ), // Using "Notes" from existing keys
            content: Text(
              'You have unsaved changes. Do you want to discard them?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text('Discard'),
              ),
            ],
          ),
    );

    return shouldPop ?? false;
  }

  void _saveNote() async {
    try {
      // Convert the document to JSON
      final deltaJson = _controller.document.toDelta().toJson();
      final String noteContent = jsonEncode(deltaJson);

      // Update the KiranUserInfo
      widget.kiranUserInfo.note = noteContent;
      widget.kiranUserInfo.updatedAt = DateTime.now();

      // Save to storage
      Utils.updateKiranUserInfo(widget.kiranUserInfo);

      if (mounted) {
        setState(() {
          _isModified = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Notes saved successfully'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving notes: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving notes: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isModified,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          final shouldPop = await _onWillPop();
          if (shouldPop && mounted) {
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            '${AppLocalizations.of(context)!.menu_four} - ${widget.kiranTitle}',
          ),
          actions: [
            IconButton(
              onPressed: _isModified ? _saveNote : null,
              icon: Icon(Icons.save, color: _isModified ? null : Colors.grey),
              tooltip: 'Save Notes',
            ),
          ],
        ),
        body: Column(
          children: [
            // Toolbar
            Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainer,
                border: Border(
                  bottom: BorderSide(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.0),
                  ),
                ),
              ),
              child: _buildToolbar(),
            ),
            // Editor
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16.0),
                child: _buildEditor(),
              ),
            ),
          ],
        ),
        floatingActionButton:
            _isModified
                ? FloatingActionButton(
                  onPressed: _saveNote,
                  tooltip: 'Save Notes',
                  child: const Icon(Icons.save),
                )
                : null,
      ),
    );
  }

  Widget _buildToolbar() {
    try {
      setToolbarTheme();
      return QuillSimpleToolbar(
        controller: _controller,
        config: QuillSimpleToolbarConfig(
          buttonOptions: QuillSimpleToolbarButtonOptions(
            bold: buttonOptions,
            italic: buttonOptions,
            listBullets: buttonOptions,
            listNumbers: buttonOptions,
            quote: buttonOptions,
          ),
          multiRowsDisplay: true,
          showSubscript: false,
          showSuperscript: false,
          showBackgroundColorButton: false,
          showAlignmentButtons: false,
          showBoldButton: true,
          showClearFormat: false,
          showColorButton: false,
          showCodeBlock: false,
          showDirection: false,
          showFontFamily: false,
          showFontSize: false,
          showHeaderStyle: true,
          showIndent: true,
          showInlineCode: false,
          showItalicButton: true,
          showJustifyAlignment: true,
          showLeftAlignment: true,
          showLink: false,
          showListBullets: true,
          showListCheck: true,
          showListNumbers: true,
          showQuote: true,
          showRightAlignment: true,
          showSearchButton: false,
          showStrikeThrough: false,
          showUnderLineButton: false,
          showUndo: true,
          showRedo: true,
        ),
      );
    } catch (e) {
      debugPrint('Error building toolbar: $e');
      return Container(
        height: 50,
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.format_bold),
              onPressed: () {
                try {
                  _controller.formatSelection(Attribute.bold);
                } catch (e) {
                  debugPrint('Error formatting: $e');
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.format_italic),
              onPressed: () {
                try {
                  _controller.formatSelection(Attribute.italic);
                } catch (e) {
                  debugPrint('Error formatting: $e');
                }
              },
            ),
          ],
        ),
      );
    }
  }

  Widget _buildEditor() {
    try {
      return SafeArea(
        child: Container(
          margin: EdgeInsets.zero,
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.outline.withValues(alpha: 0.5),
            ),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Scrollbar(
            child: QuillEditor.basic(
              controller: _controller,
              focusNode: _focusNode,
              config: QuillEditorConfig(
                autoFocus: true,
                expands: true,
                padding: EdgeInsets.zero,
                scrollable: true,
                placeholder: 'Add your notes here...',
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building editor: $e');
      // Fallback to a simple text field
      return TextField(
        controller: TextEditingController(
          text: widget.kiranUserInfo.note ?? '',
        ),
        decoration: const InputDecoration(
          hintText: 'Add your notes here...',
          border: InputBorder.none,
        ),
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        onChanged: (text) {
          widget.kiranUserInfo.note = text;
          if (!_isModified) {
            setState(() {
              _isModified = true;
            });
          }
        },
      );
    }
  }
}
