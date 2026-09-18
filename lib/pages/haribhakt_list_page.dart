import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/haribhakt_model.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/reading_event_model.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
import 'package:saxatsavita_flutter/services/bookservice.dart';
import 'package:saxatsavita_flutter/services/haribhakt_service.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';
import 'package:saxatsavita_flutter/services/kiranuser_service.dart';
import 'package:saxatsavita_flutter/services/reading_event_service.dart';
import 'package:saxatsavita_flutter/services/utils.dart';
import 'package:saxatsavita_flutter/widgets/kiran_place_line.dart';

void openHaribhaktDetail(BuildContext context, String name) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => HaribhaktDetailPage(name: name)),
  );
}

String haribhaktRoleLabel(AppLocalizations l10n, String role) {
  switch (role) {
    case 'host':
      return l10n.haribhakt_role_host;
    case 'mentioned':
      return l10n.haribhakt_role_mentioned;
    default:
      return l10n.haribhakt_role_reader;
  }
}

IconData haribhaktRoleIcon(String role) {
  switch (role) {
    case 'host':
      return Icons.home_outlined;
    case 'mentioned':
      return Icons.chat_bubble_outline;
    default:
      return Icons.menu_book_outlined;
  }
}

String formatHaribhaktCount(BuildContext context, int count) {
  final digits = count.toString();
  return Localizations.localeOf(context).languageCode == 'gu'
      ? Utils.toGujaratiNumerals(digits)
      : digits;
}

enum _RoleFilter { all, host, reader, mentioned }

enum _SortMode { count, name }

class HaribhaktListPage extends StatefulWidget {
  const HaribhaktListPage({super.key});

  @override
  State<HaribhaktListPage> createState() => _HaribhaktListPageState();
}

class _HaribhaktListPageState extends State<HaribhaktListPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  List<HaribhaktItem> _all = const [];
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
    await HaribhaktService().load();
    if (!mounted) return;
    setState(() {
      _all = HaribhaktService().list;
      _loading = false;
    });
  }

  bool get _isSearching => _searchController.text.trim().isNotEmpty;

  List<HaribhaktItem> get _visible {
    var items = HaribhaktService().searchNames(_searchController.text);
    switch (_roleFilter) {
      case _RoleFilter.host:
        items = items.where((item) => item.hasHost).toList();
      case _RoleFilter.reader:
        items = items.where((item) => item.hasReader).toList();
      case _RoleFilter.mentioned:
        items = items.where((item) => item.hasMentioned).toList();
      case _RoleFilter.all:
        items = List<HaribhaktItem>.from(items);
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
      appBar: buildAppBar(context, title: l10n.haribhakts),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: TextField(
                      controller: _searchController,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l10n.haribhakt_search_hint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon:
                            _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                  icon: const Icon(Icons.clear),
                                  tooltip: l10n.clear_all_filters,
                                  onPressed: _searchController.clear,
                                ),
                        filled: true,
                        fillColor: colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Row(
                              children: [
                                _RoleFilterChip(
                                  label: l10n.haribhakt_filter_all,
                                  selected: _roleFilter == _RoleFilter.all,
                                  onSelected:
                                      () => setState(
                                        () => _roleFilter = _RoleFilter.all,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                _RoleFilterChip(
                                  label: l10n.haribhakt_role_host,
                                  icon: Icons.home_outlined,
                                  selected: _roleFilter == _RoleFilter.host,
                                  onSelected:
                                      () => setState(
                                        () => _roleFilter = _RoleFilter.host,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                _RoleFilterChip(
                                  label: l10n.haribhakt_role_reader,
                                  icon: Icons.menu_book_outlined,
                                  selected: _roleFilter == _RoleFilter.reader,
                                  onSelected:
                                      () => setState(
                                        () => _roleFilter = _RoleFilter.reader,
                                      ),
                                ),
                                const SizedBox(width: 8),
                                _RoleFilterChip(
                                  label: l10n.haribhakt_role_mentioned,
                                  icon: Icons.chat_bubble_outline,
                                  selected: _roleFilter == _RoleFilter.mentioned,
                                  onSelected:
                                      () => setState(
                                        () =>
                                            _roleFilter = _RoleFilter.mentioned,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.sort),
                          tooltip: l10n.haribhakt_sort_count,
                          color:
                              !_isSearching && _sortMode == _SortMode.count
                                  ? colorScheme.primary
                                  : null,
                          onPressed:
                              _isSearching
                                  ? null
                                  : () => setState(
                                    () => _sortMode = _SortMode.count,
                                  ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.sort_by_alpha),
                          tooltip: l10n.haribhakt_sort_name,
                          color:
                              !_isSearching && _sortMode == _SortMode.name
                                  ? colorScheme.primary
                                  : null,
                          onPressed:
                              _isSearching
                                  ? null
                                  : () => setState(
                                    () => _sortMode = _SortMode.name,
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
        icon: Icons.people_outline,
        title: l10n.haribhakt_empty,
      );
    }
    final visible = _visible;
    if (visible.isEmpty) {
      return _EmptyState(
        icon: Icons.search_off,
        title: l10n.haribhakt_no_matches,
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
                  : l10n.haribhakt_people_count(visible.length),
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
                return _HaribhaktListTile(item: item);
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _HaribhaktListTile extends StatelessWidget {
  const _HaribhaktListTile({required this.item});

  final HaribhaktItem item;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      isThreeLine: item.roleTypeCount > 1,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: SizedBox(
        width: 40,
        child: Text(
          formatHaribhaktCount(context, item.count),
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
      ),
      title: Text(item.name),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Wrap(
          spacing: 6,
          runSpacing: 4,
          children: [
            if (item.hasHost)
              HaribhaktRoleChip(
                role: 'host',
                label: l10n.haribhakt_host_count(item.hostCount),
              ),
            if (item.hasReader)
              HaribhaktRoleChip(
                role: 'reader',
                label: l10n.haribhakt_reader_count(item.readerCount),
              ),
            if (item.hasMentioned)
              HaribhaktRoleChip(
                role: 'mentioned',
                label: l10n.haribhakt_mentioned_count(item.mentionedCount),
              ),
          ],
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: colorScheme.outline,
      ),
      onTap: () => openHaribhaktDetail(context, item.name),
    );
  }
}

class HaribhaktDetailPage extends StatefulWidget {
  const HaribhaktDetailPage({super.key, required this.name});

  final String name;

  @override
  State<HaribhaktDetailPage> createState() => _HaribhaktDetailPageState();
}

class _HaribhaktAppearance {
  final HaribhaktKiranRef ref;
  final int partNumber;
  final KiranInfo kiranInfo;
  final DateTime? date;

  const _HaribhaktAppearance({
    required this.ref,
    required this.partNumber,
    required this.kiranInfo,
    required this.date,
  });
}

class _HaribhaktDetailPageState extends State<HaribhaktDetailPage> {
  HaribhaktItem? _item;
  List<_HaribhaktAppearance> _appearances = const [];
  bool _loading = true;
  _RoleFilter _roleFilter = _RoleFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await HaribhaktService().load();
    if (!mounted) return;
    final item = HaribhaktService().findByName(widget.name);
    final appearances = <_HaribhaktAppearance>[];
    if (item != null) {
      for (final ref in item.kirans) {
        final partNumber = HaribhaktService().partNumberFor(ref.index);
        if (partNumber == null) continue;
        final kiranInfo = KiranListService().getKiranInfo(
          partNumber,
          ref.index,
        );
        if (kiranInfo.index == 0) continue;
        appearances.add(
          _HaribhaktAppearance(
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

  List<_HaribhaktAppearance> get _visible {
    switch (_roleFilter) {
      case _RoleFilter.host:
        return _appearances.where((row) => row.ref.role == 'host').toList();
      case _RoleFilter.reader:
        return _appearances.where((row) => row.ref.role == 'reader').toList();
      case _RoleFilter.mentioned:
        return _appearances
            .where((row) => row.ref.role == 'mentioned')
            .toList();
      case _RoleFilter.all:
        return _appearances;
    }
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
              highlightHaribhakt: widget.name,
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
                icon: Icons.people_outline,
                title: l10n.haribhakt_empty,
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
                      value: formatHaribhaktCount(context, item.count),
                      label: l10n.kirans,
                    ),
                  ),
                  if (item.hasHost)
                    Expanded(
                      child: _StatCell(
                        value: formatHaribhaktCount(context, item.hostCount),
                        label: l10n.haribhakt_role_host,
                        icon: Icons.home_outlined,
                      ),
                    ),
                  if (item.hasReader)
                    Expanded(
                      child: _StatCell(
                        value: formatHaribhaktCount(context, item.readerCount),
                        label: l10n.haribhakt_role_reader,
                        icon: Icons.menu_book_outlined,
                      ),
                    ),
                  if (item.hasMentioned)
                    Expanded(
                      child: _StatCell(
                        value: formatHaribhaktCount(
                          context,
                          item.mentionedCount,
                        ),
                        label: l10n.haribhakt_role_mentioned,
                        icon: Icons.chat_bubble_outline,
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
                  _RoleFilterChip(
                    label: l10n.haribhakt_filter_all,
                    selected: _roleFilter == _RoleFilter.all,
                    onSelected:
                        () => setState(() => _roleFilter = _RoleFilter.all),
                  ),
                  _RoleFilterChip(
                    label: l10n.haribhakt_role_host,
                    icon: Icons.home_outlined,
                    selected: _roleFilter == _RoleFilter.host,
                    onSelected:
                        () => setState(() => _roleFilter = _RoleFilter.host),
                  ),
                  _RoleFilterChip(
                    label: l10n.haribhakt_role_reader,
                    icon: Icons.menu_book_outlined,
                    selected: _roleFilter == _RoleFilter.reader,
                    onSelected:
                        () => setState(() => _roleFilter = _RoleFilter.reader),
                  ),
                  _RoleFilterChip(
                    label: l10n.haribhakt_role_mentioned,
                    icon: Icons.chat_bubble_outline,
                    selected: _roleFilter == _RoleFilter.mentioned,
                    onSelected:
                        () =>
                            setState(() => _roleFilter = _RoleFilter.mentioned),
                  ),
                ],
              ),
            ),
          ),
        SliverList.separated(
          itemCount: visible.length,
          separatorBuilder: (_, _) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final row = visible[index];
            final accent = Utils.getPartAccentColor(row.partNumber, context);
            final dateLabel =
                row.date == null ? '' : dateFormat.format(row.date!);
            return ListTile(
              tileColor: Utils.getPartColor(row.partNumber, context),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 2,
              ),
              leading: Text(
                row.kiranInfo.number.replaceAll('.', ''),
                style: TextStyle(
                  fontSize: 22,
                  color: accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              title: Text(row.kiranInfo.title),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      HaribhaktRoleChip(
                        role: row.ref.role,
                        label: haribhaktRoleLabel(l10n, row.ref.role),
                      ),
                      Text(
                        Bookservice().getPartTitle(context, row.partNumber),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (dateLabel.isNotEmpty)
                        Text(
                          dateLabel,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: colorScheme.outline),
                        ),
                    ],
                  ),
                  KiranPlaceLine(kiranInfo: row.kiranInfo),
                ],
              ),
              trailing: Icon(
                Icons.arrow_forward_ios,
                size: 14,
                color: colorScheme.outline,
              ),
              onTap: () => _openKiran(row.partNumber, row.kiranInfo),
            );
          },
        ),
      ],
    );
  }
}

class HaribhaktRoleChip extends StatelessWidget {
  const HaribhaktRoleChip({super.key, required this.role, required this.label});

  final String role;
  final String label;

  Color _background(ColorScheme colorScheme) {
    switch (role) {
      case 'host':
        return colorScheme.primaryContainer;
      case 'mentioned':
        return colorScheme.tertiaryContainer;
      default:
        return colorScheme.secondaryContainer;
    }
  }

  Color _foreground(ColorScheme colorScheme) {
    switch (role) {
      case 'host':
        return colorScheme.onPrimaryContainer;
      case 'mentioned':
        return colorScheme.onTertiaryContainer;
      default:
        return colorScheme.onSecondaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final background = _background(colorScheme);
    final foreground = _foreground(colorScheme);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(haribhaktRoleIcon(role), size: 14, color: foreground),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleFilterChip extends StatelessWidget {
  const _RoleFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      onSelected: (_) => onSelected(),
      avatar: icon == null ? null : Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      showCheckmark: icon == null,
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.value, required this.label, this.icon});

  final String value;
  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: colorScheme.outline),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.labelSmall?.copyWith(color: colorScheme.outline),
              ),
            ),
          ],
        ),
      ],
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
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 56,
              color: colorScheme.outline.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: colorScheme.outline),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
