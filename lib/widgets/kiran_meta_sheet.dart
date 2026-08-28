import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/appsettings.dart';
import 'package:saxatsavita_flutter/services/remote_config_service.dart';
import 'package:saxatsavita_flutter/widgets/kiran_meta_panel.dart';

Future<Map<String, dynamic>> loadKiranContentJson({
  required String partId,
  required int kiranIndex,
}) async {
  final path = 'assets/book/saxatsavita/$partId/kiran_$kiranIndex.json';
  final jsonString = await rootBundle.loadString(path);
  return json.decode(jsonString) as Map<String, dynamic>;
}

Future<void> showKiranMetaSheetForKiran({
  required BuildContext context,
  required String partId,
  required int kiranIndex,
  Future<void> Function(String selectedText)? onAddNote,
  Future<void> Function(String selectedText)? onCreateQuoteImage,
}) {
  return showKiranMetaSheet(
    context: context,
    content: loadKiranContentJson(partId: partId, kiranIndex: kiranIndex),
    onAddNote: onAddNote,
    onCreateQuoteImage: onCreateQuoteImage,
  );
}

Future<void> showKiranMetaSheet({
  required BuildContext context,
  required Future<Map<String, dynamic>> content,
  Future<void> Function(String selectedText)? onAddNote,
  Future<void> Function(String selectedText)? onCreateQuoteImage,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    clipBehavior: Clip.none,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        builder: (_, controller) {
          return Scaffold(
            primary: false,
            backgroundColor: Theme.of(sheetContext).colorScheme.surface,
            body: Column(
              children: [
                const SizedBox(height: 8),
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.kiran_info,
                          style: Theme.of(
                            context,
                          ).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          AppLocalizations.of(context)!.kiran_info_ai_generated,
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: content,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState != ConnectionState.done) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError || snapshot.data == null) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              AppLocalizations.of(context)!.kiran_info,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        );
                      }
                      return SingleChildScrollView(
                        controller: controller,
                        padding: EdgeInsets.only(
                          left: 16 + appSettingsNotifier.value.edgePadding,
                          right: 16 + appSettingsNotifier.value.edgePadding,
                          top: 16,
                          bottom: 16,
                        ),
                        child: SafeArea(
                          child: _SelectableKiranMeta(
                            contentData: snapshot.data!,
                            onAddNote: onAddNote,
                            onCreateQuoteImage: onCreateQuoteImage,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      );
    },
  );
}

class _SelectableKiranMeta extends StatefulWidget {
  const _SelectableKiranMeta({
    required this.contentData,
    this.onAddNote,
    this.onCreateQuoteImage,
  });

  final Map<String, dynamic> contentData;
  final Future<void> Function(String selectedText)? onAddNote;
  final Future<void> Function(String selectedText)? onCreateQuoteImage;

  @override
  State<_SelectableKiranMeta> createState() => _SelectableKiranMetaState();
}

class _SelectableKiranMetaState extends State<_SelectableKiranMeta> {
  String _selectedText = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final panel = KiranMetaPanel.fromContent(
      widget.contentData,
      onAddNote: widget.onAddNote,
      onCreateQuoteImage: widget.onCreateQuoteImage,
    );

    if (!RemoteConfigService().useCustomHtmlWidget) return panel;

    return Theme(
      data: theme.copyWith(
        colorScheme: colorScheme.copyWith(
          surface: colorScheme.primaryContainer,
          onSurface: colorScheme.onPrimary,
        ),
      ),
      child: SelectionArea(
        onSelectionChanged: (selection) {
          _selectedText = selection?.plainText.trim() ?? '';
        },
        contextMenuBuilder: (menuContext, selectableRegionState) {
          final l10nMenu = AppLocalizations.of(menuContext)!;
          return AdaptiveTextSelectionToolbar.buttonItems(
            anchors: selectableRegionState.contextMenuAnchors,
            buttonItems: [
              if (widget.onAddNote != null)
                ContextMenuButtonItem(
                  label: l10nMenu.add_notes,
                  onPressed: () {
                    ContextMenuController.removeAny();
                    final text = _selectedText;
                    if (text.isEmpty) return;
                    widget.onAddNote!(text);
                  },
                ),
              if (widget.onCreateQuoteImage != null)
                ContextMenuButtonItem(
                  label: l10nMenu.create_quote_image,
                  onPressed: () {
                    ContextMenuController.removeAny();
                    final text = _selectedText;
                    if (text.isEmpty) return;
                    widget.onCreateQuoteImage!(text);
                  },
                ),
              ...selectableRegionState.contextMenuButtonItems,
            ],
          );
        },
        child: Theme(data: theme, child: panel),
      ),
    );
  }
}
