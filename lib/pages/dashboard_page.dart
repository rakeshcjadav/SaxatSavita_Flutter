import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/components/drawer.dart';
import 'package:saxatsavita_flutter/models/kiraninfo_model.dart';
import 'package:saxatsavita_flutter/models/reading_history_model.dart';
import 'package:saxatsavita_flutter/services/dashboard_service.dart';
import 'package:saxatsavita_flutter/models/user_profile_model.dart';
import 'package:saxatsavita_flutter/services/analytics_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/services/kiranlistservice.dart';

class DashboardPage extends StatefulWidget {
  final bool showScaffold;

  const DashboardPage({super.key, this.showScaffold = true});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardService _dashboardService = DashboardService();
  bool _isLoading = true;
  DashboardStatistics? _statistics;
  UserProfile? _userProfile;

  @override
  void initState() {
    super.initState();
    AnalyticsService().logScreenView(screenName: 'dashboard_page');
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final stats = await _dashboardService.getDashboardStatistics();
      final profile = await _dashboardService.getUserProfile();

      if (mounted) {
        setState(() {
          _statistics = stats;
          _userProfile = profile;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard data: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final body =
        _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeCard(),
                    _buildStreakCard(),
                    const SizedBox(height: 16),
                    _buildReadingStatsCards(),
                    const SizedBox(height: 16),
                    _buildQuickActionsGrid(),
                    _buildActivePlanCard(),
                    _buildWeeklyChartCard(),
                    _buildRecentActivityCard(),
                  ],
                ),
              ),
            );

    if (!widget.showScaffold) {
      return body;
    }

    return Scaffold(
      appBar: buildAppBar(
        context,
        title: AppLocalizations.of(context)!.dashboard,
        actionItems: [ActionOptions.settings],
        extraActions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppLocalizations.of(context)!.refresh,
            onPressed: _isLoading ? null : _loadDashboardData,
          ),
        ],
      ),
      drawer: MyDrawer(
        items: [
          DrawerItem.aashirvachan,
          DrawerItem.notes,
          DrawerItem.search,
          DrawerItem.readingPlans,
          DrawerItem.readingHistory,
          DrawerItem.quotesImageGenerator,
          DrawerItem.profile,
          DrawerItem.welcomeTour,
          DrawerItem.marketingShowcase,
          DrawerItem.migration,
          DrawerItem.adminpanel,
          DrawerItem.logout,
        ],
      ),
      body: body,
    );
  }

  Widget _buildWelcomeCard() {
    final greetingType = _dashboardService.getTimeBasedGreeting();
    final greeting = switch (greetingType) {
      GreetingType.morning => AppLocalizations.of(context)!.goodMorning,
      GreetingType.afternoon => AppLocalizations.of(context)!.goodAfternoon,
      GreetingType.evening => AppLocalizations.of(context)!.goodEvening,
    };
    final userName =
        '${_userProfile?.firstName ?? ''} ${_userProfile?.lastName ?? ''}'
            .trim();
    final user = FirebaseAuth.instance.currentUser;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 32,
              backgroundColor: Theme.of(context).colorScheme.primary,
              backgroundImage:
                  user?.photoURL != null ? NetworkImage(user!.photoURL!) : null,
              child:
                  user?.photoURL == null
                      ? Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      )
                      : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (_userProfile?.city != null &&
                      _userProfile!.city.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      _userProfile!.city,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStreakItem(
              icon: Icons.local_fire_department,
              label: AppLocalizations.of(context)!.currentStreak,
              value: '${_statistics?.currentStreak ?? 0}',
              color: Colors.orange,
            ),
            const SizedBox(height: 16),
            Container(
              height: 1,
              width: double.infinity,
              color: Colors.grey[300],
            ),
            const SizedBox(height: 16),
            _buildStreakItem(
              icon: Icons.emoji_events,
              label: AppLocalizations.of(context)!.longestStreak,
              value: '${_statistics?.longestStreak ?? 0}',
              color: Colors.amber,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(width: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onPrimary,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickActionsGrid() {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.quickActions,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildQuickActionItem(
                icon: Icons.description,
                label: AppLocalizations.of(context)!.aashirvachan,
                onTap: () => Navigator.pushNamed(context, '/aashirvachan'),
              ),
              _buildQuickActionItem(
                icon: Icons.note,
                label: AppLocalizations.of(context)!.notes,
                onTap: () => Navigator.pushNamed(context, '/notelist'),
              ),
              _buildQuickActionItem(
                icon: Icons.search,
                label: AppLocalizations.of(context)!.search,
                onTap: () => Navigator.pushNamed(context, '/search'),
              ),
              _buildQuickActionItem(
                icon: Icons.calendar_today,
                label: AppLocalizations.of(context)!.reading_plans,
                onTap: () => Navigator.pushNamed(context, '/readingplan'),
              ),
              _buildQuickActionItem(
                icon: Icons.history,
                label: AppLocalizations.of(context)!.reading_history,
                onTap: () => Navigator.pushNamed(context, '/readinghistory'),
              ),
              _buildQuickActionItem(
                icon: Icons.info,
                label: AppLocalizations.of(context)!.information,
                onTap: () => Navigator.pushNamed(context, '/info'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReadingStatsCards() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Text(
            AppLocalizations.of(context)!.readingStatistics,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.timer,
                label: AppLocalizations.of(context)!.totalTime,
                value: _dashboardService.formatReadingTime(
                  _statistics?.totalReadingTimeSeconds ?? 0,
                ),
                color: Colors.blue,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                icon: Icons.book,
                label: AppLocalizations.of(context)!.sessions,
                value: '${_statistics?.totalReadingSessions ?? 0}',
                color: Colors.green,
              ),
            ),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.today,
                label: AppLocalizations.of(context)!.today,
                value: '${_statistics?.todaysSessions ?? 0}',
                color: Colors.purple,
              ),
            ),
            Expanded(
              child: _buildStatCard(
                icon: Icons.star,
                label: AppLocalizations.of(context)!.kirans,
                value: '${_statistics?.uniqueKiransRead ?? 0}',
                color: Colors.orange,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivePlanCard() {
    final plan = _statistics?.activePlan;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, '/readingplan'),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child:
              plan == null
                  ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.assignment_outlined,
                            color: Theme.of(context).colorScheme.primary,
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.noActivePlan,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        AppLocalizations.of(context)!.noActivePlanMessage,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              () =>
                                  Navigator.pushNamed(context, '/readingplan'),
                          icon: const Icon(Icons.add),
                          label: Text(AppLocalizations.of(context)!.createPlan),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                  : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.assignment,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)!.activePlan,
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 16,
                            color: Colors.grey[400],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        plan.title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        plan.description,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)!.progress,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 4),
                                LinearProgressIndicator(
                                  value: (_statistics?.planProgress ?? 0) / 100,
                                  backgroundColor: Colors.grey[200],
                                  minHeight: 8,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '${_statistics?.planProgress.toStringAsFixed(0) ?? 0}%',
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildWeeklyChartCard() {
    return _buildDailyReadingChart();
  }

  Widget _buildDailyReadingChart() {
    final dailyData = _getDailyReadingData();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.dailyReadingMinutes,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Column(
              children: [
                Text(
                  AppLocalizations.of(context)!.dailyChartDescription,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primaryContainer.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timeline,
                        size: 12,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.of(context)!.dailyChartLatestRange,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Scrollbar(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  height: 200,
                  width: dailyData.length < 7 ? 300 : dailyData.length * 50.0,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (dailyData.length - 1).toDouble(),
                      minY: 0,
                      maxY:
                          dailyData.isEmpty
                              ? 1
                              : dailyData
                                      .map((e) => e.minutes)
                                      .reduce((a, b) => a > b ? a : b) *
                                  1.1,
                      clipData: FlClipData.all(),
                      gridData: const FlGridData(show: true),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: null,
                            getTitlesWidget: (value, meta) {
                              return Text(
                                '${value.toInt()}${AppLocalizations.of(context)!.chartMinutesLabel.substring(0, 2)}',
                                style: const TextStyle(fontSize: 10),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            interval: 1,
                            getTitlesWidget: (value, meta) {
                              final index = value.toInt();
                              if (index >= 0 && index < dailyData.length) {
                                final date = dailyData[index].date;
                                final hasData = dailyData[index].minutes > 0;

                                final isMostRecentWithData = _isMostRecentDate(
                                  date,
                                  dailyData,
                                );
                                if (isMostRecentWithData ||
                                    _isToday(date) ||
                                    _isYesterday(date)) {
                                  final label =
                                      isMostRecentWithData && !_isToday(date)
                                          ? _getMostRecentDateLabel(
                                            date,
                                            hasData,
                                          )
                                          : _getIntuitiveDateLabel(date);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      label,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color:
                                            Theme.of(
                                              context,
                                            ).colorScheme.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  );
                                }

                                final shouldShow =
                                    dailyData.length > 20
                                        ? index % 7 == 0
                                        : dailyData.length > 10
                                        ? index % 3 == 0
                                        : true;

                                if (shouldShow ||
                                    index == 0 ||
                                    index == dailyData.length - 1) {
                                  final label = _getIntuitiveDateLabel(date);
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.7),
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  );
                                }
                              }
                              return const Text('');
                            },
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      borderData: FlBorderData(
                        show: true,
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.outline.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      lineBarsData: [
                        LineChartBarData(
                          spots:
                              dailyData.asMap().entries.map((entry) {
                                return FlSpot(
                                  entry.key.toDouble(),
                                  entry.value.minutes,
                                );
                              }).toList(),
                          isCurved: true,
                          curveSmoothness: 0.3,
                          color: Theme.of(context).colorScheme.primary,
                          barWidth: 3,
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, barData, index) {
                              final isToday = index == 0;
                              return FlDotCirclePainter(
                                radius: isToday ? 6 : 4,
                                color:
                                    isToday
                                        ? Theme.of(context).colorScheme.primary
                                        : Theme.of(context).colorScheme.primary
                                            .withValues(alpha: 0.8),
                                strokeWidth: isToday ? 3 : 2,
                                strokeColor:
                                    Theme.of(context).colorScheme.surface,
                              );
                            },
                          ),
                          belowBarData: BarAreaData(
                            show: true,
                            color: Theme.of(
                              context,
                            ).colorScheme.primary.withValues(alpha: 0.1),
                          ),
                          preventCurveOverShooting: true,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivityCard() {
    final recentHistory =
        (_statistics?.recentHistory ?? [])
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.recentActivity,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (recentHistory.isEmpty)
              Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.history, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        AppLocalizations.of(context)!.noActivityYet,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: recentHistory.length.clamp(0, 5),
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final history = recentHistory[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(_getKiranTitle(history)),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          history.category,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _dashboardService.formatReadingTime(
                                history.durationSeconds,
                              ),
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              _formatDate(history.createdAt),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 12),
            if (recentHistory.length > 5)
              ElevatedButton(
                onPressed:
                    () => Navigator.pushNamed(context, '/readinghistory'),
                child: Text(AppLocalizations.of(context)!.viewAll),
              ),
          ],
        ),
      ),
    );
  }

  String _getKiranTitle(ReadingHistory history) {
    final KiranInfo kiranInfo = KiranListService().getKiranInfo(
      history.partNumber,
      history.kiranIndex,
    );
    return '${kiranInfo.number} ${kiranInfo.title}';
    //final kiranUserInfo = KiranListService().getKiranList(history.partNumber).list. (history.kiranIndex);
    //return kiranUserInfo?.title ?? 'Kiran ${history.kiranIndex}';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateDay = DateTime(date.year, date.month, date.day);

    if (dateDay == today) {
      return 'Today';
    } else if (dateDay == yesterday) {
      return 'Yesterday';
    } else {
      final daysDifference = today.difference(dateDay).inDays;

      if (daysDifference < 7 && daysDifference > 0) {
        // Show weekday name for dates within the last week (localized)
        return DateFormat(
          'EEE',
          Localizations.localeOf(context).toString(),
        ).format(date);
      } else {
        // Show date for older dates
        return '${date.day}/${date.month}/${date.year}';
      }
    }
  }

  // Helper methods for daily reading chart
  List<DailyReadingData> _getDailyReadingData() {
    final recentHistory = _statistics?.recentHistory ?? [];
    final Map<DateTime, double> dailyMinutes = {};

    for (final history in recentHistory) {
      final date = DateTime(
        history.createdAt.year,
        history.createdAt.month,
        history.createdAt.day,
      );
      dailyMinutes[date] =
          (dailyMinutes[date] ?? 0) + (history.durationSeconds / 60);
    }

    final today = DateTime.now();
    DateTime? mostRecentDate;

    if (dailyMinutes.isNotEmpty) {
      mostRecentDate = dailyMinutes.keys.reduce((a, b) => a.isAfter(b) ? a : b);
    }

    final startDate = mostRecentDate ?? today;
    final normalizedStartDate = DateTime(
      startDate.year,
      startDate.month,
      startDate.day,
    );

    final List<DailyReadingData> result = [];

    for (int i = 0; i < 30; i++) {
      final date = normalizedStartDate.subtract(Duration(days: i));
      final minutes = dailyMinutes[date] ?? 0.0;
      result.add(DailyReadingData(date, minutes));
    }

    return result;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }

  bool _isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year &&
        date.month == yesterday.month &&
        date.day == yesterday.day;
  }

  String _getIntuitiveDateLabel(DateTime date) {
    if (_isToday(date)) {
      return AppLocalizations.of(context)!.today;
    } else if (_isYesterday(date)) {
      return AppLocalizations.of(context)!.yesterday;
    } else {
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference <= 7) {
        return DateFormat('EEE').format(date);
      } else if (difference <= 30) {
        return DateFormat('dd/MM').format(date);
      } else {
        return DateFormat('MM/yy').format(date);
      }
    }
  }

  String _getMostRecentDateLabel(DateTime date, bool hasData) {
    if (!hasData) {
      return _getIntuitiveDateLabel(date);
    }

    final latestLabel = AppLocalizations.of(context)!.latest;

    if (_isToday(date)) {
      return '$latestLabel (${AppLocalizations.of(context)!.today})';
    } else if (_isYesterday(date)) {
      return '$latestLabel (${AppLocalizations.of(context)!.yesterday})';
    } else {
      final now = DateTime.now();
      final difference = now.difference(date).inDays;

      if (difference <= 7) {
        return '$latestLabel (${DateFormat('EEE', Localizations.localeOf(context).toString()).format(date)})';
      } else {
        return '$latestLabel (${DateFormat('dd/MM').format(date)})';
      }
    }
  }

  bool _isMostRecentDate(DateTime date, List<DailyReadingData> dailyData) {
    if (dailyData.isEmpty) return false;
    return dailyData.first.date.isAtSameMomentAs(date) &&
        dailyData.first.minutes > 0;
  }
}

class DailyReadingData {
  final DateTime date;
  final double minutes;

  DailyReadingData(this.date, this.minutes);
}
