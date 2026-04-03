import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/reading_event_model.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
import 'package:saxatsavita_flutter/services/kiranuser_service.dart';
import 'package:saxatsavita_flutter/services/reading_event_service.dart';
import 'package:saxatsavita_flutter/services/utils.dart';

// ---------------------------------------------------------------------------
// Data models
// ---------------------------------------------------------------------------

class _ChronoEntry {
  final int partNumber;
  final KiranInfo kiranInfo;
  final DateTime? date;

  const _ChronoEntry({
    required this.partNumber,
    required this.kiranInfo,
    required this.date,
  });
}

// Sealed-style discriminated union for list rows
sealed class _ListRow {}

class _YearRow extends _ListRow {
  final int year;
  _YearRow(this.year);
}

class _EntryRow extends _ListRow {
  final _ChronoEntry entry;
  _EntryRow(this.entry);
}

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

class KiranChronologicalPage extends StatefulWidget {
  const KiranChronologicalPage({super.key});

  @override
  State<KiranChronologicalPage> createState() => _KiranChronologicalPageState();
}

class _KiranChronologicalPageState extends State<KiranChronologicalPage> {
  List<_ListRow> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final String raw = await rootBundle.loadString(
      'assets/book/saxatsavita/_all_kirans_.json',
    );
    final Map<String, dynamic> json = jsonDecode(raw);
    final List<dynamic> list = json['list'] as List<dynamic>;

    final List<_ChronoEntry> entries =
        list.map((item) {
          final map = item as Map<String, dynamic>;
          return _ChronoEntry(
            partNumber: map['part'] as int,
            kiranInfo: KiranInfo.fromMap(map),
            date: Utils.parseKiranDate(map['date'] as String? ?? ''),
          );
        }).toList();

    // Build flat list with year section headers
    final List<_ListRow> rows = [];
    int? currentYear;
    for (final entry in entries) {
      final year = entry.date?.year;
      if (year != null && year != currentYear) {
        rows.add(_YearRow(year));
        currentYear = year;
      }
      rows.add(_EntryRow(entry));
    }
    // Undated entries are already at the end (sorted by sort_kirans_by_date.py)
    // They have no year header — they fall under the last year group or
    // get a dedicated header if there was no dated entry before them.

    if (mounted) {
      setState(() {
        _rows = rows;
        _loading = false;
      });
    }
  }

  // ── Navigation ─────────────────────────────────────────────────────────────

  Future<void> _openKiran(_ChronoEntry entry) async {
    final kiranUserInfo = KiranUserService().getKiranUserInfo(
      entry.kiranInfo.index,
    );

    final existingEvent = await ReadingEventService.getReadingEventForKiran(
      entry.kiranInfo.index,
    );

    ReadingEvent? eventToResume;

    if (existingEvent != null && mounted) {
      final choice = await _showResumeDialog(existingEvent);
      if (choice == null) return;
      if (choice == 'resume') {
        eventToResume = existingEvent;
      } else {
        await ReadingEventService.deleteReadingEvent(existingEvent.id);
      }
    }

    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (_) => KiranReadPage(
              partNumber: 'part${entry.partNumber}',
              kiranInfo: entry.kiranInfo,
              kiranUserInfo: kiranUserInfo,
              readingMode: ReadingMode.reading,
              existingEvent: eventToResume,
            ),
      ),
    );
  }

  Future<String?> _showResumeDialog(ReadingEvent event) {
    final l10n = AppLocalizations.of(context)!;
    return showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text(l10n.resume_reading),
            content: Text(l10n.resume_reading_message(event.formattedDuration)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, null),
                child: Text(l10n.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'new'),
                child: Text(l10n.start_new),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, 'resume'),
                child: Text(l10n.resume),
              ),
            ],
          ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: buildAppBar(context, title: l10n.kirans_by_date),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Scrollbar(
                controller: _scrollController,
                thumbVisibility: true,
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _rows.length,
                  itemBuilder: (context, index) {
                    final row = _rows[index];
                    if (row is _YearRow) {
                      return _buildYearHeader(row.year, context);
                    }
                    final entry = (row as _EntryRow).entry;
                    // Show divider between consecutive entry tiles
                    final showDivider =
                        index + 1 < _rows.length &&
                        _rows[index + 1] is _EntryRow;
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildEntryTile(entry, context, l10n),
                        if (showDivider) const Divider(height: 1, indent: 0),
                      ],
                    );
                  },
                ),
              ),
    );
  }

  Widget _buildYearHeader(int year, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: Row(
        children: [
          Text(
            Utils.toGujaratiNumerals(year.toString()),
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Divider(color: colorScheme.outlineVariant, height: 1),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryTile(
    _ChronoEntry entry,
    BuildContext context,
    AppLocalizations l10n,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final partBg = Utils.getPartColor(entry.partNumber, context);
    final partAccent = Utils.getPartAccentColor(entry.partNumber, context);
    final progress =
        KiranUserService().getKiranUserInfo(entry.kiranInfo.index).progress;

    final String fullDate =
        entry.date != null ? DateFormat('d MMM yyyy').format(entry.date!) : '';

    return ListTile(
      tileColor: partBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      leading: Text(
        entry.kiranInfo.number.replaceAll('.', ''),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 22,
          color: partAccent,
          fontWeight: FontWeight.bold,
        ),
      ),
      title: Text(
        entry.kiranInfo.title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Row(
        children: [
          _PartChip(
            partNumber: entry.partNumber,
            accentColor: partAccent,
            l10n: l10n,
          ),
          if (fullDate.isNotEmpty) ...[
            const SizedBox(width: 6),
            Text(
              fullDate,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colorScheme.outline),
            ),
          ],
          if (progress > 0) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: LinearProgressIndicator(
                value: progress / 100.0,
                minHeight: 4,
                borderRadius: BorderRadius.circular(2),
                backgroundColor: colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(
                  partAccent.withValues(alpha: 0.6),
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '${Utils.toGujaratiNumerals(progress.toString())}%',
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colorScheme.outline),
            ),
          ],
        ],
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 14,
        color: colorScheme.outline,
      ),
      onTap: () => _openKiran(entry),
    );
  }
}

// ---------------------------------------------------------------------------
// Part chip widget
// ---------------------------------------------------------------------------

class _PartChip extends StatelessWidget {
  const _PartChip({
    required this.partNumber,
    required this.accentColor,
    required this.l10n,
  });

  final int partNumber;
  final Color accentColor;
  final AppLocalizations l10n;

  String get _label {
    switch (partNumber) {
      case 1:
        return l10n.part1;
      case 2:
        return l10n.part2;
      case 3:
        return l10n.part3;
      case 4:
        return l10n.part4;
      case 5:
        return l10n.part5;
      default:
        return 'Part $partNumber';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          color: accentColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
