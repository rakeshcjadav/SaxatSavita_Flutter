import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/kiranuserinfo_model.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

class SimpleNoteEditorPage extends StatefulWidget {
  const SimpleNoteEditorPage({
    super.key,
    required this.kiranUserInfo,
    required this.kiranTitle,
  });

  final KiranUserInfo kiranUserInfo;
  final String kiranTitle;

  @override
  State<SimpleNoteEditorPage> createState() => _SimpleNoteEditorPageState();
}

class _SimpleNoteEditorPageState extends State<SimpleNoteEditorPage> {
  late TextEditingController _textController;
  final FocusNode _focusNode = FocusNode();
  bool _isModified = false;
  String _originalNote = '';

  @override
  void initState() {
    super.initState();
    _originalNote = widget.kiranUserInfo.note ?? '';
    _textController = TextEditingController(text: _originalNote);
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_isModified && _textController.text != _originalNote) {
      setState(() {
        _isModified = true;
      });
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
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
            title: Text(AppLocalizations.of(context)!.menu_four),
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

  void _saveNote() {
    try {
      // Update the KiranUserInfo
      widget.kiranUserInfo.note = _textController.text.trim();
      widget.kiranUserInfo.updatedAt = DateTime.now();

      // Save to storage
      Utils.updateKiranUserInfo(widget.kiranUserInfo);

      setState(() {
        _isModified = false;
        _originalNote = _textController.text;
      });

      if (mounted) {
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
            Navigator.of(context).pop(true);
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
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Simple formatting toolbar
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                padding: const EdgeInsets.all(8.0),
                margin: const EdgeInsets.only(bottom: 16.0),
                child: Row(
                  children: [
                    Icon(Icons.edit_note, size: 20, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      'Personal Notes',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    if (_isModified)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Modified',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Text editor
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.outline.withValues(alpha: 0.2),
                    ),
                  ),
                  child: TextField(
                    controller: _textController,
                    focusNode: _focusNode,
                    decoration: InputDecoration(
                      hintText:
                          'Add your personal notes here...\n\n• Key insights\n• Important points\n• Questions to explore\n• Personal reflections',
                      hintStyle: TextStyle(
                        color: Colors.grey[500],
                        fontSize: 16,
                        height: 1.5,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(16.0),
                    ),
                    style: const TextStyle(fontSize: 16, height: 1.5),
                    maxLines: null,
                    expands: true,
                    textAlignVertical: TextAlignVertical.top,
                    textInputAction: TextInputAction.newline,
                  ),
                ),
              ),
            ],
          ),
        ),
        floatingActionButton:
            _isModified
                ? FloatingActionButton.extended(
                  onPressed: _saveNote,
                  icon: const Icon(Icons.save),
                  label: const Text('Save'),
                  tooltip: 'Save Notes',
                )
                : null,
      ),
    );
  }
}
