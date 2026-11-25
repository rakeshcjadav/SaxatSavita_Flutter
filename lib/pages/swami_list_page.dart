import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/reading_event_model.dart';
import 'package:saxatsavita_flutter/models/swami_model.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';
import 'package:saxatsavita_flutter/services/kiranuser_service.dart';
import 'package:saxatsavita_flutter/services/reading_event_service.dart';
import 'package:saxatsavita_flutter/services/swami_service.dart';
import 'package:saxatsavita_flutter/services/utils.dart';
import 'package:saxatsavita_flutter/widgets/kiran_place_line.dart';

void openSwamiDetail(BuildContext context, String name) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => SwamiDetailPage(name: name)),
  );
}

String formatSwamiCount(BuildContext context, int count) {
  final digits = count.toString();
  return Localizations.localeOf(context).languageCode == 'gu'
      ? Utils.toGujaratiNumerals(digits)
      : digits;
}

enum _RoleFilter { all, question, mentioned }

enum _SortMode { count, name }

class SwamiListPage extends StatefulWidget {
  const SwamiListPage({super.key});

  @override
  State<SwamiListPage> createState() => _SwamiListPageState();
}

class _SwamiListPageState extends State<SwamiListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<SwamiItem> _all = const [];
  bool _loading = true;
  _RoleFilter _roleFilter = _RoleFilter.all;
  _SortMode _sortMode = _SortMode.count;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  Future<void> _load() async {
    await SwamiService().load();
    if (!mounted) return;
    setState(() {
      _all = SwamiService().list;
      _loading = false;
    });
  }

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  List<SwamiItem> get _visible {
    var items = SwamiService().searchNames(_searchController.text);
    switch (_roleFilter) {
      case _RoleFilter.question:
        items = items.where((item) => item.hasQuestion).toList();
      case _RoleFilter.mentioned:
        items = items.where((item) => item.hasMentioned).toList();
      case _RoleFilter.all:
        items = List<SwamiItem>.from(items);
    }
    if (!_isSearching) {
      items.sort((a, b) {
        if (_sortMode == _SortMode.count) {
          final byCount = b.count.compareTo(a.count);
          if (byCount != 0) return byCount;
        }
        return a.name.compareTo(b.name);
      });
    }
    return items;
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: buildAppBar(context, title: l10n.swamis),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.swami_search_hint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon:
                            _isSearching
                                ? IconButton(
                                  onPressed: _searchController.clear,
                                  icon: const Icon(Icons.close),
                                )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                FilterChip(
                                  label: Text(l10n.haribhakt_filter_all),
                                  selected: _roleFilter == _RoleFilter.all,
                                  onSelected:
                                      (_) => setState(
                                        () => _roleFilter = _RoleFilter.all,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                FilterChip(
                                  label: Text(l10n.haribhakt_role_question),
                                  selected: _roleFilter == _RoleFilter.question,
                                  onSelected:
                                      (_) => setState(
                                        () =>
                                            _roleFilter = _RoleFilter.question,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                FilterChip(
                                  label: Text(l10n.haribhakt_role_mentioned),
                                  selected:
                                      _roleFilter == _RoleFilter.mentioned,
                                  onSelected:
                                      (_) => setState(
                                        () =>
                                            _roleFilter = _RoleFilter.mentioned,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.haribhakt_sort_count,
                          onPressed:
                              _sortMode == _SortMode.count
                                  ? null
                                  : () => setState(
                                    () => _sortMode = _SortMode.count,
                                  ),
                          icon: Icon(
                            Icons.sort,
                            color:
                                _sortMode == _SortMode.count
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                          ),
                        ),
                        IconButton(
                          tooltip: l10n.haribhakt_sort_name,
                          onPressed:
                              _sortMode == _SortMode.name
                                  ? null
                                  : () => setState(
                                    () => _sortMode = _SortMode.name,
                                  ),
                          icon: Icon(
                            Icons.sort_by_alpha,
                            color:
                                _sortMode == _SortMode.name
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(child: _buildList(l10n, colorScheme)),
                ],
              ),
    );
  }

  Widget _buildList(AppLocalizations l10n, ColorScheme colorScheme) {
    if (_all.isEmpty) {
      return _EmptyState(
        icon: Icons.auto_stories_outlined,
        title: l10n.swami_empty,
      );
    }
    final visible = _visible;
    if (visible.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off,
        title: l10n.swami_no_matches,
        subtitle: l10n.haribhakt_try_different_name,
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              _isSearching || _roleFilter != _RoleFilter.all
                  ? l10n.results_filtered(visible.length, _all.length)
                  : l10n.swami_people_count(visible.length),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
            ),
          ),
        ),
        Expanded(
          child: Scrollbar(
            controller: _scrollController,
            child: ListView.separated(
              controller: _scrollController,
              itemCount: visible.length,
              separatorBuilder: (_, _) => const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final item = visible[index];
                return _SwamiListTile(item: item);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _SwamiListTile extends StatelessWidget {
  const _SwamiListTile({required this.item});

  final SwamiItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Semantics(
      button: true,
      label: item.name,
      child: InkWell(
        onTap: () => openSwamiDetail(context, item.name),
        child: SizedBox(
          height: 72,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    formatSwamiCount(context, item.count),
                    textAlign: TextAlign.center,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.hasQuestion
                            ? '${l10n.haribhakt_mentioned_count(item.mentionedCount)} · ${l10n.haribhakt_question_count(item.questionCount)}'
                            : l10n.haribhakt_kiran_count(item.count),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: colorScheme.outline,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class SwamiDetailPage extends StatefulWidget {
  const SwamiDetailPage({super.key, required this.name});

  final String name;

  @override
  State<SwamiDetailPage> createState() => _SwamiDetailPageState();
}

class _SwamiAppearance {
  final SwamiKiranRef ref;
  final int partNumber;
  final KiranInfo kiranInfo;
  final DateTime? date;

  const _SwamiAppearance({
    required this.ref,
    required this.partNumber,
    required this.kiranInfo,
    required this.date,
  });
}

class _SwamiDetailPageState extends State<SwamiDetailPage> {
  SwamiItem? _item;
  List<_SwamiAppearance> _appearances = const [];
  bool _loading = true;
  _RoleFilter _roleFilter = _RoleFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await SwamiService().load();
    if (!mounted) return;
    final item = SwamiService().findByName(widget.name);
    final appearances = <_SwamiAppearance>[];
    if (item != null) {
      for (final ref in item.kirans) {
        final partNumber = SwamiService().partNumberFor(ref.index);
        if (partNumber == null) continue;
        final kiranInfo = KiranListService().getKiranInfo(
          partNumber,
          ref.index,
        );
        if (kiranInfo.index == 0) continue;
        appearances.add(
          _SwamiAppearance(
            ref: ref,
            partNumber: partNumber,
            kiranInfo: kiranInfo,
            date: Utils.parseKiranDate(kiranInfo.date),
          ),
        );
      }
      appearances.sort((a, b) {
        final aKey = a.date?.millisecondsSinceEpoch ?? 1 << 62;
        final bKey = b.date?.millisecondsSinceEpoch ?? 1 << 62;
        final byDate = aKey.compareTo(bKey);
        if (byDate != 0) return byDate;
        return a.kiranInfo.index.compareTo(b.kiranInfo.index);
      });
    }
    setState(() {
      _item = item;
      _appearances = appearances;
      _loading = false;
    });
  }

  List<_SwamiAppearance> get _visible {
    switch (_roleFilter) {
      case _RoleFilter.question:
        return _appearances.where((row) => row.ref.role == 'question').toList();
      case _RoleFilter.mentioned:
        return _appearances
            .where((row) => row.ref.role == 'mentioned')
            .toList();
      case _RoleFilter.all:
        return _appearances;
    }
  }

  List<({_SwamiAppearance row, String question})> get _questionRows {
    if (_roleFilter != _RoleFilter.all && _roleFilter != _RoleFilter.question) {
      return const [];
    }
    return [
      for (final row in _appearances)
        for (final question in row.ref.questions)
          (row: row, question: question),
    ];
  }

  Future<void> _openKiran(int partNumber, KiranInfo kiranInfo) async {
    final kiranUserInfo = KiranUserService().getKiranUserInfo(kiranInfo.index);
    final existingEvent = await ReadingEventService.getReadingEventForKiran(
      kiranInfo.index,
    );
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => KiranReadPage(
              partNumber: 'part$partNumber',
              kiranInfo: kiranInfo,
              kiranUserInfo: kiranUserInfo,
              highlightSwami: widget.name,
              readingMode: ReadingMode.reading,
              existingEvent: existingEvent,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: buildAppBar(context, title: widget.name),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _item == null
              ? _EmptyState(
                icon: Icons.auto_stories_outlined,
                title: l10n.swami_empty,
              )
              : _buildBody(l10n),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    final item = _item!;
    final colorScheme = Theme.of(context).colorScheme;
    final visible = _visible;
    final showRoleFilter = item.roleTypeCount > 1;
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMMMd(locale);
    final questions = _questionRows;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _StatCell(
                      value: formatSwamiCount(context, item.count),
                      label: l10n.kirans,
                    ),
                  ),
                  Expanded(
                    child: _StatCell(
                      value: formatSwamiCount(context, item.questionCount),
                      label: l10n.haribhakt_role_question,
                      muted: !item.hasQuestion,
                    ),
                  ),
                  Expanded(
                    child: _StatCell(
                      value: formatSwamiCount(context, item.mentionedCount),
                      label: l10n.haribhakt_role_mentioned,
                      muted: !item.hasMentioned,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (showRoleFilter)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: Text(l10n.haribhakt_filter_all),
                    selected: _roleFilter == _RoleFilter.all,
                    onSelected:
                        (_) => setState(() => _roleFilter = _RoleFilter.all),
                  ),
                  FilterChip(
                    label: Text(l10n.haribhakt_role_question),
                    selected: _roleFilter == _RoleFilter.question,
                    onSelected:
                        (_) =>
                            setState(() => _roleFilter = _RoleFilter.question),
                  ),
                  FilterChip(
                    label: Text(l10n.haribhakt_role_mentioned),
                    selected: _roleFilter == _RoleFilter.mentioned,
                    onSelected:
                        (_) =>
                            setState(() => _roleFilter = _RoleFilter.mentioned),
                  ),
                ],
              ),
            ),
          ),
        if (questions.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text(
                l10n.haribhakt_questions,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        if (questions.isNotEmpty)
          SliverList.separated(
            itemCount: questions.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final entry = questions[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Material(
                  color: colorScheme.secondaryContainer.withValues(alpha: 0.55),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap:
                        () => _openKiran(
                          entry.row.partNumber,
                          entry.row.kiranInfo,
                        ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(entry.question),
                    ),
                  ),
                ),
              );
            },
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          sliver: SliverList.separated(
            itemCount: visible.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final row = visible[index];
              final date = row.date == null ? '' : dateFormat.format(row.date!);
              return Material(
                color: colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _openKiran(row.partNumber, row.kiranInfo),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${row.kiranInfo.number} ${row.kiranInfo.title}',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (date.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              date,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: colorScheme.outline),
                            ),
                          ),
                        KiranPlaceLine(kiranInfo: row.kiranInfo),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.value,
    required this.label,
    this.muted = false,
  });

  final String value;
  final String label;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: muted ? 0.4 : 1,
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.icon, required this.title, this.subtitle});

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 40, color: colorScheme.outline),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colorScheme.outline),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
