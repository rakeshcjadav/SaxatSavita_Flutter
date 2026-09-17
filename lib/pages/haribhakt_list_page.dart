import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/haribhakt_model.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/reading_event_model.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
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
  return role == 'host' ? l10n.haribhakt_role_host : l10n.haribhakt_role_reader;
}

class HaribhaktListPage extends StatefulWidget {
  const HaribhaktListPage({super.key});

  @override
  State<HaribhaktListPage> createState() => _HaribhaktListPageState();
}

class _HaribhaktListPageState extends State<HaribhaktListPage> {
  final TextEditingController _searchController = TextEditingController();
  List<HaribhaktItem> _all = const [];
  List<HaribhaktItem> _filtered = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_applyFilter);
    _load();
  }

  Future<void> _load() async {
    await HaribhaktService().load();
    if (!mounted) return;
    setState(() {
      _all = HaribhaktService().list;
      _filtered = _all;
      _loading = false;
    });
  }

  void _applyFilter() {
    setState(() {
      _filtered = HaribhaktService().searchNames(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: buildAppBar(context, title: l10n.haribhakts),
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
                        hintText: l10n.haribhakt_search_hint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon:
                            _searchController.text.isEmpty
                                ? null
                                : IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: _searchController.clear,
                                ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  Expanded(child: _buildList(l10n)),
                ],
              ),
    );
  }

  Widget _buildList(AppLocalizations l10n) {
    if (_all.isEmpty) {
      return Center(child: Text(l10n.haribhakt_empty));
    }
    if (_filtered.isEmpty) {
      return Center(child: Text(l10n.haribhakt_no_matches));
    }
    return ListView.separated(
      itemCount: _filtered.length,
      separatorBuilder: (_, _) => const Divider(height: 1, indent: 16),
      itemBuilder: (context, index) {
        final item = _filtered[index];
        return ListTile(
          leading: CircleAvatar(
            child: Icon(
              Icons.person_outline,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
          title: Text(item.name),
          subtitle: Text(l10n.haribhakt_kiran_count(item.count)),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
          onTap: () => openHaribhaktDetail(context, item.name),
        );
      },
    );
  }
}

class HaribhaktDetailPage extends StatefulWidget {
  const HaribhaktDetailPage({super.key, required this.name});

  final String name;

  @override
  State<HaribhaktDetailPage> createState() => _HaribhaktDetailPageState();
}

class _HaribhaktDetailPageState extends State<HaribhaktDetailPage> {
  HaribhaktItem? _item;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await HaribhaktService().load();
    if (!mounted) return;
    setState(() {
      _item = HaribhaktService().findByName(widget.name);
      _loading = false;
    });
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
              ? Center(child: Text(l10n.haribhakt_empty))
              : ListView.separated(
                itemCount: _item!.kirans.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final ref = _item!.kirans[index];
                  final partNumber = _partNumberFor(ref.index);
                  final kiranInfo = KiranListService().getKiranInfo(
                    partNumber,
                    ref.index,
                  );
                  if (kiranInfo.index == 0) {
                    return const SizedBox.shrink();
                  }
                  final accent = Utils.getPartAccentColor(partNumber, context);
                  return ListTile(
                    tileColor: Utils.getPartColor(partNumber, context),
                    leading: Text(
                      kiranInfo.number.replaceAll('.', ''),
                      style: TextStyle(
                        fontSize: 22,
                        color: accent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    title: Text(kiranInfo.title),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          haribhaktRoleLabel(l10n, ref.role),
                          style: Theme.of(
                            context,
                          ).textTheme.labelSmall?.copyWith(color: accent),
                        ),
                        KiranPlaceLine(kiranInfo: kiranInfo),
                      ],
                    ),
                    trailing: Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    onTap: () => _openKiran(partNumber, kiranInfo),
                  );
                },
              ),
    );
  }

  int _partNumberFor(int kiranIndex) {
    for (int partNumber = 1; partNumber <= 5; partNumber++) {
      final list = KiranListService().getKiranListFromPartNumber(partNumber);
      if (list == null) continue;
      if (list.list.any((kiran) => kiran.index == kiranIndex)) {
        return partNumber;
      }
    }
    return 1;
  }
}
