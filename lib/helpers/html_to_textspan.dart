import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:html/dom.dart' as dom;
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/meanings_model.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

/// Converts HTML string to a list of widgets for use with Column
class HtmlToTextSpan {
  // Set to false to disable all debug prints in this file
  static const bool _enableDebugPrint = false;

  static void _debugPrint(String message) {
    if (_enableDebugPrint) {
      // ignore: avoid_print
      print(message);
    }
  }

  /// Converts HTML string to a list of widgets with proper formatting and alignment
  static List<Widget> convertToWidgets(
    String htmlContent,
    TextStyle baseStyle,
    BuildContext context, {
    TextAlign textAlign = TextAlign.justify,
    double? lineHeight,
    Function(String)? onAddNote,
    Function(String)? onCreateQuoteImage,
    VoidCallback? onDoubleTap,
  }) {
    _debugPrint('[HtmlToTextSpan] Starting conversion...');
    final document = html_parser.parse(htmlContent);
    final body = document.body;

    // Debug: print document structure
    if (body != null) {
      _debugPrint(
        '[HtmlToTextSpan] Body has ${body.children.length} direct children:',
      );
      for (var i = 0; i < body.children.length; i++) {
        _debugPrint(
          '[HtmlToTextSpan]   Child $i: <${body.children[i].localName}>',
        );
      }
    }

    // Apply lineHeight to baseStyle if provided
    final effectiveStyle =
        lineHeight != null ? baseStyle.copyWith(height: lineHeight) : baseStyle;

    if (body == null) {
      return [
        SelectableText(
          htmlContent,
          style: effectiveStyle,
          textAlign: textAlign,
        ),
      ];
    }

    List<Widget> widgets = [];
    List<InlineSpan> currentSpans = [];

    void flushCurrentSpans() {
      if (currentSpans.isNotEmpty) {
        _debugPrint(
          '[HtmlToTextSpan] Flushing ${currentSpans.length} spans, creating widget at position ${widgets.length}',
        );

        final textSpan = TextSpan(children: List.from(currentSpans));

        // Get custom colors or use theme defaults
        final Color surfaceColor =
            Theme.of(context).colorScheme.primaryContainer;
        final Color textColor = Theme.of(context).colorScheme.onPrimary;

        // Create SelectableText widget
        Widget selectableWidget = Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              surface: surfaceColor, // Toolbar background
              onSurface: textColor, // Text color
            ),
          ),
          child: SelectableText.rich(
            textSpan,
            style: effectiveStyle,
            textAlign: textAlign,
            contextMenuBuilder:
                (onAddNote != null || onCreateQuoteImage != null)
                    ? (context, editableTextState) {
                      final textEditingValue =
                          editableTextState.textEditingValue;
                      final selection = textEditingValue.selection;
                      final selectedText =
                          selection.isValid && !selection.isCollapsed
                              ? textEditingValue.text.substring(
                                selection.start,
                                selection.end,
                              )
                              : '';

                      if (selectedText.isEmpty) {
                        return const SizedBox.shrink();
                      }

                      return AdaptiveTextSelectionToolbar.buttonItems(
                        anchors: editableTextState.contextMenuAnchors,
                        buttonItems: [
                          if (onAddNote != null)
                            ContextMenuButtonItem(
                              label: AppLocalizations.of(context)!.add_notes,
                              onPressed: () {
                                ContextMenuController.removeAny();
                                onAddNote(selectedText);
                              },
                            ),
                          if (onCreateQuoteImage != null)
                            ContextMenuButtonItem(
                              label:
                                  AppLocalizations.of(
                                    context,
                                  )!.create_quote_image,
                              onPressed: () {
                                ContextMenuController.removeAny();
                                onCreateQuoteImage(selectedText);
                              },
                            ),
                          // add default buttons
                          ...editableTextState.contextMenuButtonItems,
                        ],
                      );
                    }
                    : null,
          ),
        );

        // Wrap with GestureDetector for double-tap if callback provided
        if (onDoubleTap != null) {
          selectableWidget = GestureDetector(
            onDoubleTap: onDoubleTap,
            behavior: HitTestBehavior.translucent,
            child: selectableWidget,
          );
        }

        widgets.add(selectableWidget);
        currentSpans.clear(); // Clear the list instead of reassigning
        _debugPrint(
          '[HtmlToTextSpan] After flush: currentSpans.length = ${currentSpans.length}',
        );
      } else {
        _debugPrint('[HtmlToTextSpan] Flush called but currentSpans is empty');
      }
    }

    int nodeDepth = 0;

    _parseNodeToWidgets(
      nodeDepth,
      body,
      effectiveStyle,
      effectiveStyle,
      currentSpans,
      widgets,
      flushCurrentSpans,
      context,
    );

    flushCurrentSpans();

    _debugPrint('[HtmlToTextSpan] Finished conversion.');
    // print all widgets
    for (var widget in widgets) {
      if (widget is Padding && widget.child is SelectableText) {
        final selectableText = widget.child as SelectableText;
        if (selectableText.data != null) {
          _debugPrint(
            '[HtmlToTextSpan] Widget: SelectableText with data: "${selectableText.data}"',
          );
        } else if (selectableText.textSpan != null) {
          _debugPrint(
            '[HtmlToTextSpan] Widget: SelectableText.rich with TextSpan:',
          );
          _printTextSpan(selectableText.textSpan!, indent: '  ');
        }
      } else if (widget is SelectableText) {
        if (widget.data != null) {
          _debugPrint(
            '[HtmlToTextSpan] Widget: SelectableText with data: "${widget.data}"',
          );
        } else if (widget.textSpan != null) {
          _debugPrint(
            '[HtmlToTextSpan] Widget: SelectableText.rich with TextSpan:',
          );
          _printTextSpan(widget.textSpan!, indent: '  ');
        }
      } else {
        _debugPrint('[HtmlToTextSpan] Widget: ${widget.runtimeType}');
      }
    }

    return widgets;
  }

  static void _printTextSpan(InlineSpan span, {String indent = ''}) {
    if (span is TextSpan) {
      if (span.text != null && span.text!.isNotEmpty) {
        final text =
            span.text!.length > 50
                ? '${span.text!.substring(0, 50)}...'
                : span.text!;
        _debugPrint('[HtmlToTextSpan] $indent- Text: "$text"');
      }
      if (span.children != null && span.children!.isNotEmpty) {
        _debugPrint(
          '[HtmlToTextSpan] $indent- Children (${span.children!.length}):',
        );
        for (var child in span.children!) {
          _printTextSpan(child, indent: '$indent  ');
        }
      } else if (span.text == null || span.text!.isEmpty) {
        _debugPrint('[HtmlToTextSpan] $indent- Empty TextSpan');
      }
    } else {
      _debugPrint('[HtmlToTextSpan] $indent- ${span.runtimeType}');
    }
  }

  /*
  /// Legacy method for backward compatibility - returns TextSpan
  static TextSpan convert(String htmlContent, TextStyle baseStyle) {
    final document = html_parser.parse(htmlContent);
    final body = document.body;

    if (body == null) {
      return TextSpan(text: htmlContent, style: baseStyle);
    }

    return _parseNode(body, baseStyle, baseStyle);
  }*/

  static void _parseNodeToWidgets(
    int nodeDepth,
    dom.Node node,
    TextStyle baseStyle,
    TextStyle currentStyle,
    List<InlineSpan> currentSpans,
    List<Widget> widgets,
    VoidCallback flushCurrentSpans,
    BuildContext context, {
    String? anchorHref,
  }) {
    if (node is dom.Text) {
      String text = node.text;
      text = text
          .replaceAll('&nbsp;', ' ')
          .replaceAll('&amp;', '&')
          .replaceAll('&lt;', '<')
          .replaceAll('&gt;', '>')
          .replaceAll('&quot;', '"')
          .replaceAll('&#8230;', '…');

      if (text.isNotEmpty) {
        _debugPrint(
          '[HtmlToTextSpan] Text node: "${text.length > 50 ? "${text.substring(0, 50)}..." : text}"',
        );

        // Add tap handling if this text is inside an anchor tag
        if (anchorHref != null) {
          currentSpans.add(
            TextSpan(
              text: text,
              style: currentStyle,
              recognizer:
                  TapGestureRecognizer()
                    ..onTap = () {
                      _handleAnchorTap(context, anchorHref);
                    },
            ),
          );
        } else {
          currentSpans.add(TextSpan(text: text, style: currentStyle));
        }
      }
      return;
    }
    _debugPrint(
      '[HtmlToTextSpan] ------ Processing node (depth $nodeDepth): ${node.text}',
    );
    nodeDepth++;

    if (node is dom.Element) {
      _debugPrint('[HtmlToTextSpan] Processing tag: <${node.localName}>');

      // Special handling for body - just process children sequentially
      if (node.localName == 'body') {
        _debugPrint(
          '[HtmlToTextSpan]   -> Body element, processing ${node.children.length} children sequentially',
        );
        int childIndex = 0;
        for (var child in node.nodes) {
          if (child is dom.Element) {
            _debugPrint(
              '[HtmlToTextSpan]   -> Processing body child $childIndex: <${child.localName}>',
            );
          }
          _parseNodeToWidgets(
            nodeDepth,
            child,
            baseStyle,
            currentStyle,
            currentSpans,
            widgets,
            flushCurrentSpans,
            context,
          );
          childIndex++;
        }
        _debugPrint(
          '[HtmlToTextSpan]   -> Body complete. Widgets created: ${widgets.length}',
        );
        return;
      }

      TextStyle newStyle = currentStyle;
      bool isBlock = false;
      bool isCentered = false;
      bool isRightAligned = false;
      double horizontalPadding = 8.0;

      switch (node.localName) {
        case 'b':
        case 'strong':
          _debugPrint('[HtmlToTextSpan]   -> Applying bold style');
          newStyle = currentStyle.copyWith(fontWeight: FontWeight.bold);
          break;
        case 'i':
        case 'em':
          _debugPrint('[HtmlToTextSpan]   -> Applying italic style');
          newStyle = currentStyle.copyWith(fontStyle: FontStyle.italic);
          break;
        case 'u':
          _debugPrint('[HtmlToTextSpan]   -> Applying underline');
          newStyle = currentStyle.copyWith(
            decoration: TextDecoration.underline,
          );
          break;
        case 'mark':
          _debugPrint('[HtmlToTextSpan]   -> Applying highlight/mark style');
          // Check for data-current attribute to determine highlight color
          final isCurrent = node.attributes['data-current'] == 'true';
          final bgColor = isCurrent ? Color(0xFFFF9800) : Color(0xFFFFEB3B);
          newStyle = currentStyle.copyWith(
            backgroundColor: bgColor,
            color: Colors.black,
          );
          break;
        case 'slok':
          _debugPrint(
            '[HtmlToTextSpan]   -> Block element: SLOK (centered, bold)',
          );
          // Flush current spans and create centered widget
          flushCurrentSpans();
          isBlock = true;
          isCentered = true;
          newStyle = currentStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: currentStyle.fontSize ?? 16,
          );
          break;
        case 'header':
          _debugPrint(
            '[HtmlToTextSpan]   -> Block element: HEADER (centered, bold, 1.2x size)',
          );
          flushCurrentSpans();
          isBlock = true;
          isCentered = true;
          newStyle = currentStyle.copyWith(
            fontWeight: FontWeight.normal,
            fontSize: (currentStyle.fontSize ?? 16) * 0.75,
          );
          break;
        case 'footer':
          _debugPrint(
            '[HtmlToTextSpan]   -> Block element: FOOTER (right-aligned, italic, 0.9x size)',
          );
          flushCurrentSpans();
          isBlock = true;
          isCentered = false;
          isRightAligned = true;
          horizontalPadding = 0.0;
          newStyle = currentStyle.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: currentStyle.fontSize ?? 16,
          );
          break;
        case 'p':
          _debugPrint('[HtmlToTextSpan]   -> Paragraph tag (flushing before)');
          // Flush before processing paragraph content
          flushCurrentSpans();

          // Check if paragraph contains block elements like slok
          bool hasBlockChildren = node.children.any(
            (child) =>
                child.localName == 'slok' ||
                child.localName == 'header' ||
                child.localName == 'footer',
          );
          _debugPrint(
            '[HtmlToTextSpan]   -> Paragraph ${hasBlockChildren ? "(contains block elements)" : "(normal)"}',
          );

          if (hasBlockChildren) {
            // Process children sequentially, flushing and adding blocks as encountered
            for (var child in node.nodes) {
              if (child is dom.Element &&
                  (child.localName == 'slok' ||
                      child.localName == 'header' ||
                      child.localName == 'footer')) {
                // Flush any accumulated inline content before the block
                flushCurrentSpans();
                // Process the block element directly
                _parseNodeToWidgets(
                  nodeDepth,
                  child,
                  baseStyle,
                  newStyle,
                  currentSpans,
                  widgets,
                  flushCurrentSpans,
                  context,
                );
              } else {
                // Process inline content
                _parseNodeToWidgets(
                  nodeDepth,
                  child,
                  baseStyle,
                  newStyle,
                  currentSpans,
                  widgets,
                  flushCurrentSpans,
                  context,
                );
              }
            }
            // Flush after processing all children
            _debugPrint(
              '[HtmlToTextSpan]   -> Paragraph with blocks done, flushing',
            );
            flushCurrentSpans();
            return;
          } else {
            // Normal paragraph - process content then flush
            _debugPrint(
              '[HtmlToTextSpan]   -> Processing normal paragraph children',
            );
            for (var child in node.nodes) {
              _parseNodeToWidgets(
                nodeDepth,
                child,
                baseStyle,
                newStyle,
                currentSpans,
                widgets,
                flushCurrentSpans,
                context,
              );
            }
            // Flush the paragraph content as a separate widget
            _debugPrint(
              '[HtmlToTextSpan]   -> Normal paragraph done, flushing (currentSpans: ${currentSpans.length})',
            );
            flushCurrentSpans();
            return;
          }
        case 'br':
          _debugPrint('[HtmlToTextSpan]   -> Line break');
          currentSpans.add(TextSpan(text: '\n', style: currentStyle));
          return;
        case 'img':
          _debugPrint(
            '[HtmlToTextSpan]   -> Image: ${node.attributes['src'] ?? 'no src'}',
          );
          flushCurrentSpans();
          widgets.add(
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Image.asset(
                node.attributes['src'] ?? 'assets/images/default.png',
              ),
            ),
          );
          return;
        case 'a':
          _debugPrint(
            '[HtmlToTextSpan]   -> Link: ${node.attributes['href'] ?? 'no href'}',
          );
          newStyle = currentStyle.copyWith(
            color: Utils.oppositeColor(currentStyle.color ?? Colors.black),
            fontWeight: FontWeight.bold,
          );
          // Pass href to children for tap handling
          final href = node.attributes['href'];
          for (var child in node.nodes) {
            _parseNodeToWidgets(
              nodeDepth,
              child,
              baseStyle,
              newStyle,
              currentSpans,
              widgets,
              flushCurrentSpans,
              context,
              anchorHref: href,
            );
          }
          return;
      }

      if (isBlock) {
        // For block elements like slok, header, footer
        List<InlineSpan> blockSpans = [];
        for (var child in node.nodes) {
          _parseNodeToWidgets(
            nodeDepth,
            child,
            baseStyle,
            newStyle,
            blockSpans,
            widgets, // Pass the widgets list so nested processing can add to it
            flushCurrentSpans, // Pass the flush function
            context,
          );
        }

        if (blockSpans.isNotEmpty) {
          _debugPrint(
            '[HtmlToTextSpan]   -> Adding ${blockSpans.length} block spans to widget at position ${widgets.length} (isCentered: $isCentered, isRightAligned: $isRightAligned)',
          );

          // Determine text alignment: center, right, or start
          TextAlign alignment;
          if (isCentered) {
            alignment = TextAlign.center;
          } else if (isRightAligned) {
            alignment = TextAlign.right;
          } else {
            alignment = TextAlign.start;
          }

          _debugPrint('[HtmlToTextSpan]   -> Using alignment: $alignment');

          widgets.add(
            Padding(
              padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
              child: SizedBox(
                width: double.infinity, // Take full width for alignment to work
                child: SelectableText.rich(
                  TextSpan(children: blockSpans),
                  style: newStyle,
                  textAlign: alignment,
                ),
              ),
            ),
          );
        }
      } else {
        // Inline elements - but check if they contain block elements
        bool hasBlockChildren = node.children.any(
          (child) =>
              child.localName == 'slok' ||
              child.localName == 'header' ||
              child.localName == 'footer',
        );

        if (hasBlockChildren) {
          _debugPrint(
            '[HtmlToTextSpan]   -> Inline element contains block children, processing sequentially',
          );
          // Process children sequentially like paragraphs do
          for (var child in node.nodes) {
            if (child is dom.Element &&
                (child.localName == 'slok' ||
                    child.localName == 'header' ||
                    child.localName == 'footer')) {
              // Flush any accumulated inline content before the block
              flushCurrentSpans();
              // Process the block element directly
              _parseNodeToWidgets(
                nodeDepth,
                child,
                baseStyle,
                newStyle,
                currentSpans,
                widgets,
                flushCurrentSpans,
                context,
              );
            } else {
              // Process inline content
              _parseNodeToWidgets(
                nodeDepth,
                child,
                baseStyle,
                newStyle,
                currentSpans,
                widgets,
                flushCurrentSpans,
                context,
              );
            }
          }
        } else {
          // Normal inline elements
          for (var child in node.nodes) {
            _parseNodeToWidgets(
              nodeDepth,
              child,
              baseStyle,
              newStyle,
              currentSpans,
              widgets,
              flushCurrentSpans,
              context,
            );
          }
        }
      }
    }
  }

  /// Handles tap on anchor tags to show dictionary meanings
  static void _handleAnchorTap(BuildContext context, String href) {
    _debugPrint('[HtmlToTextSpan] Anchor tapped: $href');

    // Call Bookservice to get meaning (synchronous)
    final meaning = Bookservice().getMeaning(href);

    if (meaning != null && meaning.index != -1) {
      _showMeaningDialog(context, meaning);
    } else {
      _debugPrint('[HtmlToTextSpan] No meaning found for: $href');
    }
  }

  /// Shows a modal bottom sheet with the word meaning
  static void _showMeaningDialog(BuildContext context, MeaningItem meaning) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    alignment: Alignment.centerLeft,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(15.0),
                      child: Text(
                        meaning.word,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text(
                      meaning.meaning,
                      style: Theme.of(context).textTheme.bodyLarge,
                      overflow: TextOverflow.visible,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
