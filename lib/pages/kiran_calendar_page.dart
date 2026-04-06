import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/services/utils.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/reading_event_model.dart';
import 'package:saxatsavita_flutter/pages/kiranreadpage.dart';
import 'package:saxatsavita_flutter/services/kiran_calendar_service.dart';
import 'package:saxatsavita_flutter/services/kiranuser_service.dart';
import 'package:saxatsavita_flutter/services/reading_event_service.dart';
import 'package:table_calendar/table_calendar.dart';

class KiranCalendarPage extends StatefulWidget {
  const KiranCalendarPage({super.key});

  @override
  State<KiranCalendarPage> createState() => _KiranCalendarPageState();
}

class _KiranCalendarPageState extends State<KiranCalendarPage> {
  final KiranCalendarService _service = KiranCalendarService();

  bool _loading = true;
  // Use year 2000 as the fixed display year; map today's month/day into it
  static DateTime _todayIn2000() {
    final now = DateTime.now();
    return DateTime.utc(2000, now.month, now.day);
  }

  DateTime _focusedDay = _todayIn2000();
  DateTime? _selectedDay = _todayIn2000();
  List<KiranCalendarEntry> _selectedEntries = [];

  @override
  void initState() {
    super.initState();
    _loadCalendar();
  }

  Future<void> _loadCalendar() async {
    await _service.load();
    if (mounted) {
      setState(() {
        _loading = false;
        _onDaySelected(_selectedDay!, _focusedDay);
      });
    }
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
      _selectedEntries = _service.entriesFor(selectedDay);
    });
  }

  List<KiranCalendarEntry> _eventLoader(DateTime day) =>
      _service.entriesFor(day);

  Future<void> _openKiran(KiranCalendarEntry entry) async {
    final kiranUserInfo = KiranUserService().getKiranUserInfo(
      entry.kiranInfo.index,
    );

    final existingEvent = await ReadingEventService.getReadingEventForKiran(
      entry.kiranInfo.index,
    );

    ReadingMode selectedMode = ReadingMode.reading;
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
              readingMode: selectedMode,
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

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: buildAppBar(
        context,
        title: l10n.kiran_calendar,
        extraActions: [
          IconButton(
            icon: const Icon(Icons.format_list_numbered_outlined),
            tooltip: l10n.kirans_by_date,
            onPressed:
                () => Navigator.pushNamed(context, '/kiran-chronological'),
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildCalendar(colorScheme),
                  const Divider(height: 1),
                  Expanded(child: _buildDayPanel(colorScheme, l10n)),
                ],
              ),
    );
  }

  Widget _buildCalendar(ColorScheme colorScheme) {
    return TableCalendar<KiranCalendarEntry>(
      firstDay: DateTime.utc(2000, 1, 1),
      lastDay: DateTime.utc(2000, 12, 31),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(day, _selectedDay),
      eventLoader: _eventLoader,
      onDaySelected: _onDaySelected,
      onPageChanged: (focusedDay) => _focusedDay = focusedDay,
      startingDayOfWeek: StartingDayOfWeek.monday,
      rowHeight: 46,
      daysOfWeekHeight: 24,
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleCentered: true,
        headerPadding: const EdgeInsets.symmetric(vertical: 6),
        // Show only month name — the year (2000) is just a display artefact
        titleTextFormatter:
            (date, locale) =>
                DateFormat('MMMM', locale?.toString()).format(date),
        titleTextStyle: Theme.of(context).textTheme.titleMedium!.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
          color: colorScheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        weekendStyle: Theme.of(context).textTheme.labelSmall!.copyWith(
          color: colorScheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
      calendarStyle: CalendarStyle(
        selectedDecoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        todayDecoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(color: colorScheme.onPrimaryContainer),
        markersMaxCount: 0,
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, events) {
          if (events.isEmpty) return const SizedBox.shrink();
          const int maxDots = 5;
          final displayed = events.take(maxDots).toList();
          final hasMore = events.length > maxDots;
          return Positioned(
            bottom: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ...displayed.map(
                  (entry) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Utils.getPartAccentColor(
                        entry.partNumber,
                        context,
                      ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
                if (hasMore)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 1),
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.outline,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDayPanel(ColorScheme colorScheme, AppLocalizations l10n) {
    if (_selectedDay == null) {
      return Center(
        child: Text(
          l10n.select_date_to_view_kirans,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
        ),
      );
    }

    if (_selectedEntries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.event_busy_outlined,
              size: 48,
              color: colorScheme.outlineVariant,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.no_kirans_on_this_date,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: colorScheme.outline),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      itemCount: _selectedEntries.length,
      separatorBuilder: (_, _) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final entry = _selectedEntries[index];
        return _buildKiranTile(entry, colorScheme, l10n);
      },
    );
  }

  Widget _buildKiranTile(
    KiranCalendarEntry entry,
    ColorScheme colorScheme,
    AppLocalizations l10n,
  ) {
    final partBg = Utils.getPartColor(entry.partNumber, context);
    final partAccent = Utils.getPartAccentColor(entry.partNumber, context);
    final progress =
        KiranUserService().getKiranUserInfo(entry.kiranInfo.index).progress;
    final fullDate = DateFormat('d MMM yyyy').format(entry.date);

    return ListTile(
      tileColor: partBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Text(
        entry.kiranInfo.number.replaceAll('.', ''),
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
          _PartBadge(partNumber: entry.partNumber, accentColor: partAccent),
          const SizedBox(width: 6),
          Text(
            fullDate,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: colorScheme.outline),
          ),
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
              '$progress%',
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

class _PartBadge extends StatelessWidget {
  const _PartBadge({required this.partNumber, required this.accentColor});

  final int partNumber;
  final Color accentColor;

  String _partLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
        _partLabel(context),
        style: TextStyle(
          fontSize: 11,
          color: accentColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
