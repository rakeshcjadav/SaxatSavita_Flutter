import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';

/// Returns `null` if dismissed, `''` to clear, or a village name to filter.
Future<String?> showVillageFilterSheet({
  required BuildContext context,
  required List<String> villages,
  String? selected,
}) {
  final l10n = AppLocalizations.of(context)!;
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.9,
        builder: (_, controller) {
          return Column(
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
                  child: Text(
                    l10n.filter_by_village,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: ListView.builder(
                  controller: controller,
                  itemCount: villages.length + 1,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      final isAll = selected == null || selected.isEmpty;
                      return ListTile(
                        leading: Icon(
                          isAll
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color:
                              isAll
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outline,
                        ),
                        title: Text(l10n.all_villages),
                        onTap: () => Navigator.pop(sheetContext, ''),
                      );
                    }
                    final village = villages[index - 1];
                    final isSelected = village == selected;
                    return ListTile(
                      leading: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.location_on_outlined,
                        color:
                            isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.outline,
                      ),
                      title: Text(village),
                      onTap: () => Navigator.pop(sheetContext, village),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

Widget villageFilterChip({
  required BuildContext context,
  required String village,
  required VoidCallback onCleared,
}) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
    child: Align(
      alignment: Alignment.centerLeft,
      child: FilterChip(
        avatar: const Icon(Icons.location_on, size: 16),
        label: Text(village),
        selected: true,
        onSelected: (_) => onCleared(),
        onDeleted: onCleared,
      ),
    ),
  );
}
