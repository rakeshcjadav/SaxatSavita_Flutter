import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CustomTextSelectionControls extends MaterialTextSelectionControls {
  final VoidCallback? onAddNote;
  final bool hasAddNoteButton;

  CustomTextSelectionControls({this.onAddNote, this.hasAddNoteButton = true});

  /// Custom copy action that can include additional functionality
  @override
  void handleCopy(TextSelectionDelegate delegate) {
    final TextEditingValue value = delegate.textEditingValue;
    final String selectedText = value.selection.textInside(value.text);

    if (selectedText.isNotEmpty) {
      // Copy to clipboard
      Clipboard.setData(ClipboardData(text: selectedText));

      // Optional: Add custom behavior here
      // For example, you could show a custom snackbar or analytics tracking
      debugPrint('Text copied: $selectedText');
    }

    // Hide the selection overlay
    delegate.hideToolbar();
  }

  /// Custom select all action
  @override
  void handleSelectAll(TextSelectionDelegate delegate) {
    super.handleSelectAll(delegate);
    // Optional: Add custom behavior after select all
    debugPrint('Select all triggered');
  }

  /// Customize which actions are available
  @override
  bool canCopy(TextSelectionDelegate delegate) {
    // You can add custom logic to determine when copy should be available
    return super.canCopy(delegate);
  }

  @override
  bool canSelectAll(TextSelectionDelegate delegate) {
    // You can add custom logic to determine when select all should be available
    return super.canSelectAll(delegate);
  }

  /// Custom toolbar builder with additional options
  @override
  Widget buildToolbar(
    BuildContext context,
    Rect globalEditableRegion,
    double textLineHeight,
    Offset selectionMidpoint,
    List<TextSelectionPoint> endpoints,
    TextSelectionDelegate delegate,
    ValueListenable<ClipboardStatus>? clipboardStatus,
    Offset? lastSecondaryTapDownPosition,
  ) {
    return _CustomTextSelectionToolbar(
      globalEditableRegion: globalEditableRegion,
      textLineHeight: textLineHeight,
      selectionMidpoint: selectionMidpoint,
      endpoints: endpoints,
      delegate: delegate,
      clipboardStatus: clipboardStatus,
      handleCopy: canCopy(delegate) ? () => handleCopy(delegate) : null,
      handleSelectAll:
          canSelectAll(delegate) ? () => handleSelectAll(delegate) : null,
      // Add custom actions here
      handleShare: canCopy(delegate) ? () => _handleShare(delegate) : null,

      handleNote:
          (onAddNote != null && hasAddNoteButton)
              ? () => _handleAddNote(delegate)
              : null,
    );
  }

  /// Custom share functionality
  void _handleShare(TextSelectionDelegate delegate) {
    final TextEditingValue value = delegate.textEditingValue;
    final String selectedText = value.selection.textInside(value.text);

    if (selectedText.isNotEmpty) {
      // Implement sharing functionality
      debugPrint('Share text: $selectedText');
      // You can integrate with share_plus package or other sharing methods
    }

    delegate.hideToolbar();
  }

  /// Custom add note functionality
  void _handleAddNote(TextSelectionDelegate delegate) {
    if (onAddNote != null) {
      onAddNote!();
    }
    delegate.hideToolbar();
  }
}

// Custom toolbar widget with additional buttons
class _CustomTextSelectionToolbar extends StatefulWidget {
  const _CustomTextSelectionToolbar({
    required this.clipboardStatus,
    required this.delegate,
    required this.endpoints,
    required this.globalEditableRegion,
    required this.handleCopy,
    required this.handleSelectAll,
    required this.handleShare,
    required this.handleNote,
    required this.selectionMidpoint,
    required this.textLineHeight,
  });

  final ValueListenable<ClipboardStatus>? clipboardStatus;
  final TextSelectionDelegate delegate;
  final List<TextSelectionPoint> endpoints;
  final Rect globalEditableRegion;
  final VoidCallback? handleCopy;
  final VoidCallback? handleSelectAll;
  final VoidCallback? handleShare;
  final VoidCallback? handleNote;
  final Offset selectionMidpoint;
  final double textLineHeight;

  @override
  State<_CustomTextSelectionToolbar> createState() =>
      _CustomTextSelectionToolbarState();
}

class _CustomTextSelectionToolbarState
    extends State<_CustomTextSelectionToolbar> {
  void _onChangedClipboardStatus() {
    setState(() {
      // Inform the widget that the value of clipboardStatus has changed.
    });
  }

  @override
  void initState() {
    super.initState();
    widget.clipboardStatus?.addListener(_onChangedClipboardStatus);
  }

  @override
  void didUpdateWidget(_CustomTextSelectionToolbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.clipboardStatus != oldWidget.clipboardStatus) {
      widget.clipboardStatus?.addListener(_onChangedClipboardStatus);
      oldWidget.clipboardStatus?.removeListener(_onChangedClipboardStatus);
    }
  }

  @override
  void dispose() {
    widget.clipboardStatus?.removeListener(_onChangedClipboardStatus);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> children = [];

    // Copy button
    if (widget.handleCopy != null) {
      children.add(
        ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: TextButton.icon(
            onPressed: widget.handleCopy,
            icon: Icon(Icons.copy, size: 18),
            label: Text('Copy'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    /*
    // Share button
    if (widget.handleShare != null) {
      children.add(
        ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: TextButton.icon(
            onPressed: widget.handleShare,
            icon: Icon(Icons.share, size: 18),
            label: Text('Share'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      );
    }*/

    // Add Note button
    if (widget.handleNote != null) {
      children.add(
        ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: TextButton.icon(
            onPressed: widget.handleNote,
            icon: Icon(Icons.note_add, size: 18),
            label: Text('Note'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    // Select All button
    if (widget.handleSelectAll != null) {
      children.add(
        ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainer,
          child: TextButton.icon(
            onPressed: widget.handleSelectAll,
            icon: Icon(Icons.select_all, size: 18),
            label: Text('Select All'),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      );
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate positioning
    final TextSelectionPoint startTextSelectionPoint = widget.endpoints[0];
    final TextSelectionPoint endTextSelectionPoint =
        widget.endpoints.length > 1 ? widget.endpoints[1] : widget.endpoints[0];

    final double anchorTop =
        math.max(
          startTextSelectionPoint.point.dy - widget.textLineHeight - 8.0,
          0,
        ) +
        widget.globalEditableRegion.top;

    final Offset anchorAbove = Offset(
      widget.globalEditableRegion.left + widget.selectionMidpoint.dx,
      anchorTop,
    );

    final Offset anchorBelow = Offset(
      widget.globalEditableRegion.left + widget.selectionMidpoint.dx,
      widget.globalEditableRegion.top + endTextSelectionPoint.point.dy + 30.0,
    );

    return TextSelectionToolbar(
      anchorAbove: anchorAbove,
      anchorBelow: anchorBelow,
      children: children,
    );
  }
}
