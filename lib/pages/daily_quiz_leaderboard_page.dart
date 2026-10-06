import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/daily_quiz_leaderboard_model.dart';
import 'package:saxatsavita_flutter/services/analytics_service.dart';
import 'package:saxatsavita_flutter/services/daily_quiz_leaderboard_service.dart';
import 'package:saxatsavita_flutter/widgets/daily_quiz_leaderboard_tile.dart';

enum DailyQuizLeaderboardPeriod { daily, weekly, monthly, yearly }

class DailyQuizLeaderboardPage extends StatefulWidget {
  const DailyQuizLeaderboardPage({super.key});

  @override
  State<DailyQuizLeaderboardPage> createState() =>
      _DailyQuizLeaderboardPageState();
}

class _DailyQuizLeaderboardPageState extends State<DailyQuizLeaderboardPage> {
  final DailyQuizLeaderboardService _service = DailyQuizLeaderboardService();
  DailyQuizLeaderboardPeriod _period = DailyQuizLeaderboardPeriod.daily;
  final Map<DailyQuizLeaderboardPeriod, DailyQuizLeaderboardSnapshot?>
  _snapshots = {};
  final Map<DailyQuizLeaderboardPeriod, bool> _loading = {
    DailyQuizLeaderboardPeriod.daily: true,
    DailyQuizLeaderboardPeriod.weekly: false,
    DailyQuizLeaderboardPeriod.monthly: false,
    DailyQuizLeaderboardPeriod.yearly: false,
  };
  final Map<DailyQuizLeaderboardPeriod, int> _loadToken = {};

  DailyQuizLeaderboardSnapshot? get _snapshot => _snapshots[_period];

  bool get _loadingCurrent => _loading[_period] ?? false;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'daily_quiz_leaderboard_page');
    _load(_period);
  }

  Future<DailyQuizLeaderboardSnapshot> _fetch(
    DailyQuizLeaderboardPeriod period,
  ) {
    return switch (period) {
      DailyQuizLeaderboardPeriod.daily => _service.loadDaily(),
      DailyQuizLeaderboardPeriod.weekly => _service.loadWeekly(),
      DailyQuizLeaderboardPeriod.monthly => _service.loadMonthly(),
      DailyQuizLeaderboardPeriod.yearly => _service.loadYearly(),
    };
  }

  Future<void> _load(
    DailyQuizLeaderboardPeriod period, {
    bool refresh = false,
  }) async {
    if (!refresh && _snapshots[period] != null) {
      if (mounted) setState(() => _loading[period] = false);
      return;
    }
    final token = (_loadToken[period] ?? 0) + 1;
    _loadToken[period] = token;
    if (mounted) setState(() => _loading[period] = true);
    final snapshot = await _fetch(period);
    if (!mounted || _loadToken[period] != token) return;
    setState(() {
      _snapshots[period] = snapshot;
      _loading[period] = false;
    });
  }

  Future<void> _refresh() => _load(_period, refresh: true);

  void _selectPeriod(DailyQuizLeaderboardPeriod period) {
    if (_period == period) return;
    setState(() => _period = period);
    _load(period);
  }

  String _emptyMessage(AppLocalizations l10n) {
    return switch (_period) {
      DailyQuizLeaderboardPeriod.weekly =>
        l10n.daily_quiz_leaderboard_empty_week,
      DailyQuizLeaderboardPeriod.monthly =>
        l10n.daily_quiz_leaderboard_empty_month,
      DailyQuizLeaderboardPeriod.yearly =>
        l10n.daily_quiz_leaderboard_empty_year,
      DailyQuizLeaderboardPeriod.daily => l10n.daily_quiz_leaderboard_empty,
    };
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
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SegmentedButton<DailyQuizLeaderboardPeriod>(
                  expandedInsets: null,
                  showSelectedIcon: false,
                  style: SegmentedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: [
                    ButtonSegment(
                      value: DailyQuizLeaderboardPeriod.daily,
                      label: Text(l10n.daily_quiz_leaderboard_daily),
                    ),
                    ButtonSegment(
                      value: DailyQuizLeaderboardPeriod.weekly,
                      label: Text(l10n.daily_quiz_leaderboard_weekly),
                    ),
                    ButtonSegment(
                      value: DailyQuizLeaderboardPeriod.monthly,
                      label: Text(l10n.daily_quiz_leaderboard_monthly),
                    ),
                    ButtonSegment(
                      value: DailyQuizLeaderboardPeriod.yearly,
                      label: Text(l10n.daily_quiz_leaderboard_yearly),
                    ),
                  ],
                  selected: {_period},
                  onSelectionChanged:
                      (selected) => _selectPeriod(selected.first),
                ),
              ),
            ),
          ),
          Expanded(child: _buildBody(l10n)),
        ],
      ),
    );
  }

  Widget _buildBody(AppLocalizations l10n) {
    if (_loadingCurrent && _snapshot == null) {
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
                child: Text(_emptyMessage(l10n), textAlign: TextAlign.center),
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
