import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/saved_suvichar.dart';
import 'package:saxatsavita_flutter/pages/quotes_image_generator_page.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/saved_suvichar_filter.dart';
import 'package:saxatsavita_flutter/services/saved_suvichar_service.dart';

class SavedSuvicharsPage extends StatefulWidget {
  const SavedSuvicharsPage({super.key});

  @override
  State<SavedSuvicharsPage> createState() => _SavedSuvicharsPageState();
}

class _SavedSuvicharsPageState extends State<SavedSuvicharsPage> {
  final SavedSuvicharService _service = SavedSuvicharService();
  final TextEditingController _searchController = TextEditingController();
  List<SavedSuvichar> _items = [];
  SuvicharQuery _query = const SuvicharQuery();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<SavedSuvichar> get _visibleItems => applySuvicharQuery(_items, _query);

  Future<void> _load() async {
    try {
      final items = await _service.load();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)!.error_loading_suvichars(e.toString()),
          ),
        ),
      );
    }
  }

  Future<void> _open(SavedSuvichar item) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuotesImageGeneratorPage(quote: null, saved: item),
      ),
    );
    if (mounted) await _load();
  }

  Future<void> _create() async {
    await Navigator.pushNamed(context, '/quotes_generator');
    if (mounted) await _load();
  }

  Future<bool> _confirmDelete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          title: Text(l10n.delete_suvichar),
          content: Text(l10n.suvichar_delete_confirm),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: colors.error,
                foregroundColor: colors.onError,
              ),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: Text(l10n.delete_suvichar),
            ),
          ],
        );
      },
    );
    return confirmed ?? false;
  }

  Future<void> _persistDelete(SavedSuvichar item) async {
    await _service.delete(item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(AppLocalizations.of(context)!.suvichar_deleted)),
    );
  }

  void _removeFromList(SavedSuvichar item) {
    setState(() {
      _items = _items.where((saved) => saved.id != item.id).toList();
    });
  }

  void _updateQuery(SuvicharQuery next) {
    setState(() => _query = next);
  }

  List<String> get _authorOptions {
    final names = <String>{};
    var hasBlank = false;
    for (final item in _items) {
      final name = item.author.trim();
      if (name.isEmpty) {
        hasBlank = true;
      } else {
        names.add(name);
      }
    }
    final sorted = names.toList()..sort();
    if (hasBlank) sorted.insert(0, '');
    return sorted;
  }

  List<int> get _partOptions {
    return _items.map((item) => item.partNumber).toSet().toList()..sort();
  }

  List<int> get _templateOptions {
    return _items.map((item) => item.templateIndex).toSet().toList()..sort();
  }

  Future<void> _openFilters() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            void update(SuvicharQuery next) {
              _updateQuery(next);
              setSheetState(() {});
            }

            return _SuvicharFilterSheet(
              query: _query,
              authors: _authorOptions,
              parts: _partOptions,
              templates: _templateOptions,
              onQuery: update,
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    final visible = _visibleItems;
    return Scaffold(
      appBar: buildAppBar(context, title: l10n.my_suvichars),
      floatingActionButton:
          _isLoading || _items.isEmpty
              ? null
              : FloatingActionButton.extended(
                onPressed: _create,
                icon: const Icon(Icons.add),
                label: Text(l10n.create_quote_image),
              ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  if (_items.isNotEmpty)
                    _SearchBar(
                      controller: _searchController,
                      filtersActive: _query.hasFilters,
                      onChanged: (value) {
                        _updateQuery(_query.copyWith(text: value));
                      },
                      onClearText: () {
                        _searchController.clear();
                        _updateQuery(_query.copyWith(text: ''));
                      },
                      onOpenFilters: _openFilters,
                    ),
                  if (_query.isActive && _items.isNotEmpty)
                    _ActiveFilters(
                      query: _query,
                      shown: visible.length,
                      total: _items.length,
                      onQuery: _updateQuery,
                    ),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return RefreshIndicator(
                          onRefresh: _load,
                          color: colors.primary,
                          child:
                              visible.isEmpty
                                  ? ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      SizedBox(
                                        height: constraints.maxHeight,
                                        child:
                                            _items.isEmpty
                                                ? _EmptyLibrary(
                                                  title:
                                                      l10n.no_saved_suvichars,
                                                  hint:
                                                      l10n.no_saved_suvichars_hint,
                                                  actionLabel:
                                                      l10n.quotes_image_generator,
                                                  onCreate: _create,
                                                )
                                                : _NoMatches(
                                                  onClear: () {
                                                    _searchController.clear();
                                                    _updateQuery(
                                                      const SuvicharQuery(),
                                                    );
                                                  },
                                                ),
                                      ),
                                    ],
                                  )
                                  : ListView.builder(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    padding: const EdgeInsets.fromLTRB(
                                      16,
                                      8,
                                      16,
                                      96,
                                    ),
                                    itemCount: visible.length,
                                    itemBuilder: (context, index) {
                                      final item = visible[index];
                                      return Padding(
                                        padding: const EdgeInsets.only(
                                          bottom: 14,
                                        ),
                                        child: _SuvicharCard(
                                          item: item,
                                          templateName: suvicharTemplateName(
                                            l10n,
                                            item.templateIndex,
                                          ),
                                          updatedLabel: _formatUpdated(
                                            item.updatedAt,
                                          ),
                                          deleteTooltip: l10n.delete_suvichar,
                                          onOpen: () => _open(item),
                                          onDelete: () async {
                                            if (await _confirmDelete()) {
                                              _removeFromList(item);
                                              await _persistDelete(item);
                                            }
                                          },
                                        ),
                                      );
                                    },
                                  ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  const _SearchBar({
    required this.controller,
    required this.filtersActive,
    required this.onChanged,
    required this.onClearText,
    required this.onOpenFilters,
  });

  final TextEditingController controller;
  final bool filtersActive;
  final ValueChanged<String> onChanged;
  final VoidCallback onClearText;
  final VoidCallback onOpenFilters;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.search_suvichars,
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    controller.text.isEmpty
                        ? null
                        : IconButton(
                          tooltip: l10n.clear,
                          onPressed: onClearText,
                          icon: const Icon(Icons.close),
                        ),
                filled: true,
                fillColor: colors.surfaceContainer,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filledTonal(
            tooltip: l10n.filters,
            onPressed: onOpenFilters,
            style: IconButton.styleFrom(
              backgroundColor:
                  filtersActive ? colors.primary : colors.surfaceContainer,
              foregroundColor:
                  filtersActive ? colors.onPrimary : colors.onSurface,
            ),
            icon: const Icon(Icons.tune),
          ),
        ],
      ),
    );
  }
}

class _ActiveFilters extends StatelessWidget {
  const _ActiveFilters({
    required this.query,
    required this.shown,
    required this.total,
    required this.onQuery,
  });

  final SuvicharQuery query;
  final int shown;
  final int total;
  final ValueChanged<SuvicharQuery> onQuery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.results_filtered(shown, total),
            style: Theme.of(context).textTheme.labelMedium,
          ),
          if (query.hasFilters) ...[
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  if (query.date != SuvicharDateFilter.any)
                    _removableChip(
                      context,
                      _dateChipLabel(context, query),
                      () => onQuery(
                        query.copyWith(
                          date: SuvicharDateFilter.any,
                          clearFrom: true,
                          clearTo: true,
                        ),
                      ),
                    ),
                  for (final author in query.authors)
                    _removableChip(
                      context,
                      author.isEmpty ? l10n.no_author : author,
                      () {
                        final next = {...query.authors}..remove(author);
                        onQuery(query.copyWith(authors: next));
                      },
                    ),
                  for (final part in query.parts)
                    _removableChip(context, _partLabel(context, part), () {
                      final next = {...query.parts}..remove(part);
                      onQuery(query.copyWith(parts: next));
                    }),
                  for (final template in query.templates)
                    _removableChip(
                      context,
                      suvicharTemplateName(l10n, template),
                      () {
                        final next = {...query.templates}..remove(template);
                        onQuery(query.copyWith(templates: next));
                      },
                    ),
                  TextButton(
                    onPressed: () => onQuery(query.clearedFilters()),
                    child: Text(l10n.clear_all_filters),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NoMatches extends StatelessWidget {
  const _NoMatches({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 56, color: colors.primary),
          const SizedBox(height: 16),
          Text(
            l10n.no_filtered_results,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            l10n.adjust_filters,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          TextButton(onPressed: onClear, child: Text(l10n.clear_all_filters)),
        ],
      ),
    );
  }
}

class _SuvicharFilterSheet extends StatelessWidget {
  const _SuvicharFilterSheet({
    required this.query,
    required this.authors,
    required this.parts,
    required this.templates,
    required this.onQuery,
  });

  final SuvicharQuery query;
  final List<String> authors;
  final List<int> parts;
  final List<int> templates;
  final ValueChanged<SuvicharQuery> onQuery;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottom),
        shrinkWrap: true,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.filters,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              TextButton(
                onPressed:
                    query.hasFilters
                        ? () => onQuery(query.clearedFilters())
                        : null,
                child: Text(l10n.clear_all_filters),
              ),
            ],
          ),
          _sectionTitle(context, l10n.filter_date),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in SuvicharDateFilter.values)
                ChoiceChip(
                  label: Text(_dateFilterLabel(l10n, option)),
                  selected: query.date == option,
                  onSelected: (_) {
                    onQuery(
                      query.copyWith(
                        date: option,
                        clearFrom: option != SuvicharDateFilter.custom,
                        clearTo: option != SuvicharDateFilter.custom,
                      ),
                    );
                  },
                ),
            ],
          ),
          if (query.date == SuvicharDateFilter.custom) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(context, isStart: true),
                    icon: const Icon(Icons.event),
                    label: Text(
                      query.from == null
                          ? l10n.from_date
                          : _shortDate(query.from!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickDate(context, isStart: false),
                    icon: const Icon(Icons.event),
                    label: Text(
                      query.to == null ? l10n.to_date : _shortDate(query.to!),
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (authors.isNotEmpty) ...[
            _sectionTitle(context, l10n.author),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final author in authors)
                  FilterChip(
                    label: Text(author.isEmpty ? l10n.no_author : author),
                    selected: query.authors.contains(author),
                    onSelected:
                        (_) => onQuery(
                          query.copyWith(
                            authors: _toggle(query.authors, author),
                          ),
                        ),
                  ),
              ],
            ),
          ],
          if (parts.isNotEmpty) ...[
            _sectionTitle(context, l10n.book_parts),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final part in parts)
                  FilterChip(
                    label: Text(_partLabel(context, part)),
                    selected: query.parts.contains(part),
                    onSelected:
                        (_) => onQuery(
                          query.copyWith(parts: _toggle(query.parts, part)),
                        ),
                  ),
              ],
            ),
          ],
          if (templates.isNotEmpty) ...[
            _sectionTitle(context, l10n.template),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final template in templates)
                  FilterChip(
                    label: Text(suvicharTemplateName(l10n, template)),
                    selected: query.templates.contains(template),
                    onSelected:
                        (_) => onQuery(
                          query.copyWith(
                            templates: _toggle(query.templates, template),
                          ),
                        ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, {required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? query.from : query.to) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    onQuery(
      query.copyWith(
        date: SuvicharDateFilter.custom,
        from: isStart ? picked : query.from,
        to: isStart ? query.to : picked,
      ),
    );
  }
}

Widget _sectionTitle(BuildContext context, String title) {
  return Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 8),
    child: Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
    ),
  );
}

Widget _removableChip(
  BuildContext context,
  String label,
  VoidCallback onDeleted,
) {
  return Padding(
    padding: const EdgeInsets.only(right: 8),
    child: InputChip(label: Text(label), onDeleted: onDeleted),
  );
}

Set<T> _toggle<T>(Set<T> values, T value) {
  final next = {...values};
  if (!next.add(value)) next.remove(value);
  return next;
}

String _dateFilterLabel(AppLocalizations l10n, SuvicharDateFilter filter) {
  return switch (filter) {
    SuvicharDateFilter.any => l10n.any_time,
    SuvicharDateFilter.today => l10n.today,
    SuvicharDateFilter.thisWeek => l10n.this_week,
    SuvicharDateFilter.last30Days => l10n.last_30_days,
    SuvicharDateFilter.custom => l10n.custom_range,
  };
}

String _dateChipLabel(BuildContext context, SuvicharQuery query) {
  final l10n = AppLocalizations.of(context)!;
  if (query.date != SuvicharDateFilter.custom) {
    return _dateFilterLabel(l10n, query.date);
  }
  final from = query.from == null ? l10n.from_date : _shortDate(query.from!);
  final to = query.to == null ? l10n.to_date : _shortDate(query.to!);
  return '$from – $to';
}

String _partLabel(BuildContext context, int part) {
  final l10n = AppLocalizations.of(context)!;
  if (part < 1) return l10n.no_part;
  return Bookservice().getPartTitle(context, part);
}

String _shortDate(DateTime dateTime) {
  final local = dateTime.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  return '$day/$month/${local.year}';
}

class _EmptyLibrary extends StatelessWidget {
  const _EmptyLibrary({
    required this.title,
    required this.hint,
    required this.actionLabel,
    required this.onCreate,
  });

  final String title;
  final String hint;
  final String actionLabel;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 112,
            height: 112,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.primary, colors.tertiary],
              ),
              boxShadow: [
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.28),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.format_quote_rounded,
              size: 52,
              color: colors.onPrimary,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colors.onSurfaceVariant,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 28),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.auto_awesome),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _SuvicharCard extends StatelessWidget {
  const _SuvicharCard({
    required this.item,
    required this.templateName,
    required this.updatedLabel,
    required this.deleteTooltip,
    required this.onOpen,
    required this.onDelete,
  });

  final SavedSuvichar item;
  final String templateName;
  final String updatedLabel;
  final String deleteTooltip;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final gradient = _gradientFor(item);
    final explicit =
        item.quoteTextColor == null
            ? null
            : _colorFromArgb(item.quoteTextColor!);
    final ink =
        explicit ??
        (gradient.first.computeLuminance() > 0.62
            ? const Color(0xFF1C1C1C)
            : Colors.white);
    final authorColor =
        item.authorTextColor == null
            ? ink.withValues(alpha: 0.86)
            : _colorFromArgb(item.authorTextColor!);

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: gradient.first.withValues(alpha: 0.32),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(22),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onOpen,
          child: Ink(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradient,
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -8,
                  bottom: -22,
                  child: Icon(
                    Icons.format_quote_rounded,
                    size: 108,
                    color: ink.withValues(alpha: 0.12),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 8, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _templateIcon(item.templateIndex),
                            size: 18,
                            color: ink.withValues(alpha: 0.9),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              templateName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: ink.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            tooltip: deleteTooltip,
                            onPressed: onDelete,
                            icon: Icon(
                              Icons.delete_outline,
                              color: ink.withValues(alpha: 0.92),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Text(
                          item.quote,
                          maxLines: 4,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: ink,
                            fontFamily: item.fontFamily,
                            fontSize: 18,
                            height: 1.45,
                            fontWeight:
                                item.isQuoteBold
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                            fontStyle:
                                item.isQuoteItalic
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                          ),
                        ),
                      ),
                      if (item.author.trim().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: Text(
                            '— ${item.author}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: authorColor,
                              fontFamily: item.fontFamily,
                              fontSize: 13,
                              fontWeight:
                                  item.isAuthorBold
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                              fontStyle:
                                  item.isAuthorItalic
                                      ? FontStyle.italic
                                      : FontStyle.normal,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: ink.withValues(alpha: 0.8),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              updatedLabel,
                              style: TextStyle(
                                color: ink.withValues(alpha: 0.8),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

List<Color> _gradientFor(SavedSuvichar item) {
  return switch (item.gradientKey) {
    'blue' => const [Color(0xFF1565C0), Color(0xFF42A5F5)],
    'green' => const [Color(0xFF2E7D32), Color(0xFF4CAF50)],
    'purple' => const [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
    'teal' => [Colors.teal.shade700, Colors.teal.shade400],
    'indigo' => [Colors.indigo.shade700, Colors.indigo.shade400],
    'saffron' => const [Color(0xFFFF6F00), Color(0xFFFFB74D)],
    'spiritual' => const [Color(0xFF8E24AA), Color(0xFFBA68C8)],
    'gray' => [Colors.grey.shade700, Colors.grey.shade400],
    'custom' => [
      _colorFromArgb(item.customGradientStart),
      _colorFromArgb(item.customGradientEnd),
    ],
    _ => [Colors.deepOrange.shade700, Colors.orange.shade400],
  };
}

IconData _templateIcon(int index) {
  return switch (index) {
    0 => Icons.notes_rounded,
    3 => Icons.self_improvement_rounded,
    4 => Icons.blur_circular_rounded,
    5 => Icons.auto_awesome_rounded,
    6 => Icons.dashboard_customize_rounded,
    7 => Icons.menu_book_rounded,
    8 => Icons.person_rounded,
    9 => Icons.style_rounded,
    10 => Icons.share_rounded,
    11 => Icons.auto_stories_rounded,
    _ => Icons.format_quote_rounded,
  };
}

Color _colorFromArgb(int argb) {
  return Color.fromARGB(
    (argb >> 24) & 0xFF,
    (argb >> 16) & 0xFF,
    (argb >> 8) & 0xFF,
    argb & 0xFF,
  );
}

String suvicharTemplateName(AppLocalizations l10n, int index) {
  return switch (index) {
    0 => l10n.template_simple,
    3 => l10n.template_spiritual,
    4 => l10n.template_mandala,
    5 => l10n.template_elegant,
    6 => l10n.template_modern,
    7 => l10n.template_classic,
    8 => l10n.template_profile,
    9 => l10n.template_card,
    10 => l10n.template_social,
    11 => l10n.template_story,
    _ => l10n.template,
  };
}

String _formatUpdated(DateTime dateTime) {
  final local = dateTime.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/${local.year} $hour:$minute';
}
