import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/daily_quiz_leaderboard_model.dart';
import 'package:saxatsavita_flutter/services/analytics_service.dart';
import 'package:saxatsavita_flutter/services/daily_quiz_leaderboard_service.dart';
import 'package:saxatsavita_flutter/widgets/daily_quiz_leaderboard_tile.dart';

enum DailyQuizLeaderboardPeriod { daily, weekly }

class DailyQuizLeaderboardPage extends StatefulWidget {
  const DailyQuizLeaderboardPage({super.key});

  @override
  State<DailyQuizLeaderboardPage> createState() =>
      _DailyQuizLeaderboardPageState();
}

class _DailyQuizLeaderboardPageState extends State<DailyQuizLeaderboardPage> {
  final DailyQuizLeaderboardService _service = DailyQuizLeaderboardService();
  DailyQuizLeaderboardPeriod _period = DailyQuizLeaderboardPeriod.daily;
  DailyQuizLeaderboardSnapshot? _daily;
  DailyQuizLeaderboardSnapshot? _weekly;
  bool _loadingDaily = true;
  bool _loadingWeekly = false;

  DailyQuizLeaderboardSnapshot? get _snapshot =>
      _period == DailyQuizLeaderboardPeriod.daily ? _daily : _weekly;

  bool get _loading =>
      _period == DailyQuizLeaderboardPeriod.daily
          ? _loadingDaily
          : _loadingWeekly;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'daily_quiz_leaderboard_page');
    _loadDaily();
  }

  Future<void> _loadDaily({bool refresh = false}) async {
    if (!refresh && _daily != null) {
      if (mounted) setState(() => _loadingDaily = false);
      return;
    }
    if (mounted) setState(() => _loadingDaily = true);
    final snapshot = await _service.loadDaily();
    if (!mounted) return;
    setState(() {
      _daily = snapshot;
      _loadingDaily = false;
    });
  }

  Future<void> _loadWeekly({bool refresh = false}) async {
    if (!refresh && _weekly != null) {
      if (mounted) setState(() => _loadingWeekly = false);
      return;
    }
    if (mounted) setState(() => _loadingWeekly = true);
    final snapshot = await _service.loadWeekly();
    if (!mounted) return;
    setState(() {
      _weekly = snapshot;
      _loadingWeekly = false;
    });
  }

  Future<void> _refresh() {
    if (_period == DailyQuizLeaderboardPeriod.daily) {
      return _loadDaily(refresh: true);
    }
    return _loadWeekly(refresh: true);
  }

  void _selectPeriod(DailyQuizLeaderboardPeriod period) {
    if (_period == period) return;
    setState(() => _period = period);
    if (period == DailyQuizLeaderboardPeriod.weekly) {
      _loadWeekly();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: l10n.daily_quiz_leaderboard,
        titleIcon: Icons.emoji_events,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<DailyQuizLeaderboardPeriod>(
                segments: [
                  ButtonSegment(
                    value: DailyQuizLeaderboardPeriod.daily,
                    label: Text(l10n.daily_quiz_leaderboard_daily),
                  ),
                  ButtonSegment(
                    value: DailyQuizLeaderboardPeriod.weekly,
                    label: Text(l10n.daily_quiz_leaderboard_weekly),
                  ),
                ],
                selected: {_period},
                onSelectionChanged: (selected) => _selectPeriod(selected.first),
              ),
            ),
          ),
          Expanded(child: _buildBody(l10n)),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loading && _snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final snapshot = _snapshot;
    if (snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (!snapshot.isAuthenticated) {
      return _MessageView(
        text: l10n.daily_quiz_leaderboard_sign_in,
        actionLabel: l10n.login,
        onAction: () => Navigator.of(context).pushNamed('/login'),
      );
    }

    if (snapshot.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 120),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  _period == DailyQuizLeaderboardPeriod.weekly
                      ? l10n.daily_quiz_leaderboard_empty_week
                      : l10n.daily_quiz_leaderboard_empty,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
        itemCount: snapshot.entries.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: Text(
                localizeLeaderboardDigits(
                  context,
                  l10n.daily_quiz_leaderboard_participants(
                    snapshot.entries.length,
                  ),
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            );
          }
          final entry = snapshot.entries[index - 1];
          final rank = index;
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DailyQuizLeaderboardTile(
              rank: rank,
              entry: entry,
              isCurrentUser: entry.uid == snapshot.currentUser?.uid,
            ),
          );
        },
      ),
    );
  }
}

class _MessageView extends StatelessWidget {
  const _MessageView({
    required this.text,
    required this.actionLabel,
    required this.onAction,
  });

  final String text;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(text, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}
