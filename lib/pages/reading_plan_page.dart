import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/helpers/open_kiran.dart';
import 'package:saxatsavita_flutter/helpers/reading_plan_schedule.dart';
import 'package:saxatsavita_flutter/l10n/app_localizations.dart';
import 'package:saxatsavita_flutter/models/reading_plan_model.dart';
import 'package:saxatsavita_flutter/services/reading_plan_service.dart';
import 'package:saxatsavita_flutter/services/notification_service.dart';
import 'package:saxatsavita_flutter/pages/create_reading_plan_page.dart';

class ReadingPlanPage extends StatefulWidget {
  const ReadingPlanPage({super.key});

  @override
  State<ReadingPlanPage> createState() => _ReadingPlanPageState();
}

class _ReadingPlanPageState extends State<ReadingPlanPage>
    with SingleTickerProviderStateMixin {
  final ReadingPlanService _readingPlanService = ReadingPlanService();
  final NotificationService _notificationService = NotificationService();

  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _initializeServices();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _initializeServices() async {
    setState(() => _isLoading = true);

    try {
      await _notificationService.initialize();
      await _readingPlanService.loadReadingPlans();
      await _readingPlanService.setActivePlan(
        _readingPlanService.activePlan?.id ?? '',
      );
    } catch (e) {
      debugPrint('Error initializing services: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(
        context,
        title: AppLocalizations.of(context)!.reading_plans,
        actionItems: [ActionOptions.settings],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              icon: const Icon(Icons.today),
              text: AppLocalizations.of(context)!.reading_plans_today,
            ),
            Tab(
              icon: const Icon(Icons.list),
              text: AppLocalizations.of(context)!.reading_plans_my_plans,
            ),
            Tab(
              icon: const Icon(Icons.bar_chart),
              text: AppLocalizations.of(context)!.reading_plans_progress,
            ),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SafeArea(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTodayTab(),
                    _buildMyPlansTab(),
                    _buildProgressTab(),
                  ],
                ),
              ),
      floatingActionButton: AnimatedBuilder(
        animation: _tabController,
        builder: (context, child) => _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    final currentIndex = _tabController.index;

    switch (currentIndex) {
      case 0: // Today Tab
        final activePlan = _readingPlanService.activePlan;
        if (activePlan == null) {
          return FloatingActionButton(
            heroTag: "add_plan",
            onPressed: () => _navigateToCreatePlan(),
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.add),
          );
        }
        return FloatingActionButton(
          heroTag: "start_reading",
          onPressed: () => _startReading(),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.play_arrow),
        );

      case 1: // My Plans Tab
        return FloatingActionButton(
          heroTag: "add_plan",
          onPressed: () => _navigateToCreatePlan(),
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: const Icon(Icons.add),
        );

      case 2: // Progress Tab
        final activePlan = _readingPlanService.activePlan;
        if (activePlan == null) {
          return FloatingActionButton(
            heroTag: "add_plan",
            onPressed: () => _navigateToCreatePlan(),
            backgroundColor: Theme.of(context).colorScheme.primary,
            child: const Icon(Icons.add),
          );
        }
        return FloatingActionButton(
          heroTag: "view_stats",
          onPressed: () => _showProgressSummary(),
          backgroundColor: Theme.of(context).colorScheme.secondary,
          child: const Icon(Icons.analytics),
        );

      default:
        return FloatingActionButton(
          heroTag: "default",
          onPressed: () => _navigateToCreatePlan(),
          child: const Icon(Icons.add),
        );
    }
  }

  Widget _buildTodayTab() {
    final activePlan = _readingPlanService.activePlan;

    if (activePlan == null) {
      return _buildNoPlanState();
    }
    if (!activePlan.hasStartKiran) {
      return _buildChooseStartKiran(activePlan);
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _readingPlanService.loadReadingPlans();
        setState(() {});
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTodayProgress(activePlan),
            const SizedBox(height: 8),
            _buildQuickActions(activePlan),
            const SizedBox(height: 8),
            _buildTodayStats(activePlan),
            const SizedBox(height: 8),
            _buildMotivationalMessage(activePlan),
          ],
        ),
      ),
    );
  }

  Widget _buildChooseStartKiran(ReadingPlan plan) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.flag_outlined, size: 72, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              l10n.choose_start_kiran,
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.choose_start_kiran_body,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _editPlan(plan),
              icon: const Icon(Icons.edit),
              label: Text(l10n.set_start_kiran),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTodayProgress(ReadingPlan plan) {
    final l10n = AppLocalizations.of(context)!;
    final today = plan.assignmentOn(DateTime.now());
    final tomorrow = plan.assignmentOn(
      DateTime.now().add(const Duration(days: 1)),
    );
    final week = plan.readingSchedule.weekContaining(
      DateTime.now(),
      today: DateTime.now(),
    );
    final isGoalAchieved = today.goalMet;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isGoalAchieved
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: isGoalAchieved ? Colors.green : Colors.grey,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    today.planComplete && today.remaining.isEmpty
                        ? l10n.reading_plan_complete
                        : isGoalAchieved
                        ? l10n.today_goal_achieved
                        : l10n.today_progress,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: today.progress,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isGoalAchieved ? Colors.green : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            if (today.remaining.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final kiran in today.remaining)
                    ActionChip(
                      avatar: const Icon(Icons.menu_book, size: 18),
                      label: Text('${l10n.preview_kirans} $kiran'),
                      onPressed: () => _openPlanKiran(kiran),
                    ),
                ],
              )
            else if (!today.planComplete)
              Text(l10n.no_kirans_due_today),
            if (today.backlog > 0) ...[
              const SizedBox(height: 8),
              Text(l10n.backlog_kirans(today.backlog)),
            ],
            if (today.extraFinished.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l10n.extra_kirans_today(today.extraFinished.join(', '))),
            ],
            if (isGoalAchieved && tomorrow.assigned.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(l10n.tomorrow_starts_at(tomorrow.assigned.first)),
            ],
            const SizedBox(height: 12),
            Text(
              '${l10n.this_week}: ${l10n.week_progress_count(week.read, week.target)}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions(ReadingPlan plan) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.flash_on,
                  color: Theme.of(context).primaryColor,
                  size: 25,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.quick_actions,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.play_arrow,
                  label: AppLocalizations.of(context)!.start_reading,
                  onTap: () => _startReading(),
                ),
                _buildActionButton(
                  icon: Icons.edit,
                  label: AppLocalizations.of(context)!.edit_plan,
                  onTap: () => _editPlan(plan),
                ),
                _buildActionButton(
                  icon: Icons.notifications,
                  label: AppLocalizations.of(context)!.test_reminder,
                  onTap: () => _testReminder(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    /*
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(width: 8),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );*/
    return ElevatedButton.icon(
      onPressed: onTap,
      style: ButtonStyle(
        shape: WidgetStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      ),
      icon: Icon(icon, size: 32, color: Theme.of(context).primaryColor),
      label: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }

  Widget _buildTodayStats(ReadingPlan plan) {
    if (!plan.hasStartKiran) return const SizedBox.shrink();
    final stats = _readingPlanService.getReadingStatistics();
    final week = plan.readingSchedule.weekContaining(
      DateTime.now(),
      today: DateTime.now(),
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 25,
                  color: Theme.of(context).primaryColor,
                ),
                const SizedBox(width: 8),
                Text(
                  AppLocalizations.of(context)!.your_statistics,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatItem(
                  AppLocalizations.of(context)!.streak,
                  AppLocalizations.of(context)!.day_streak(plan.streakDays),
                ),
                _buildStatItem(
                  AppLocalizations.of(context)!.this_week,
                  AppLocalizations.of(
                    context,
                  )!.week_progress_count(week.read, week.target),
                ),
                _buildStatItem(
                  AppLocalizations.of(context)!.total_time,
                  '${stats['totalSeconds'] ~/ 60}m:${stats['totalSeconds'] % 60}s',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildMotivationalMessage(ReadingPlan plan) {
    final streak = plan.streakDays;
    String message;
    IconData icon;
    Color color;

    if (plan.todayGoalAchieved) {
      message = AppLocalizations.of(context)!.excellent_work_today;
      icon = Icons.celebration;
      color = Colors.green;
    } else if (streak > 7) {
      message = AppLocalizations.of(context)!.on_fire_streak(streak);
      icon = Icons.local_fire_department;
      color = Colors.orange;
    } else if (plan.todayProgress > 0) {
      message = AppLocalizations.of(context)!.great_start;
      icon = Icons.trending_up;
      color = Colors.blue;
    } else {
      message = AppLocalizations.of(context)!.ready_to_start;
      icon = Icons.auto_awesome;
      color = Colors.purple;
    }

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyPlansTab() {
    final plans = _readingPlanService.readingPlans;

    if (plans.isEmpty) {
      return _buildNoPlanState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: plans.length,
      itemBuilder: (context, index) {
        final plan = plans[index];
        return _buildPlanCard(plan);
      },
    );
  }

  Widget _buildPlanCard(ReadingPlan plan) {
    final isActive = plan.id == _readingPlanService.activePlan?.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: CircleAvatar(
          backgroundColor:
              isActive ? Theme.of(context).colorScheme.primary : Colors.grey,
          child: Icon(
            isActive ? Icons.play_arrow : Icons.pause,
            color:
                isActive
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.black54,
          ),
        ),
        title: Text(
          plan.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(plan.description),
            const SizedBox(height: 4),
            Text(
              plan.hasStartKiran
                  ? '• ${AppLocalizations.of(context)!.plan_starts_at_kiran(plan.startKiran)}\n• ${AppLocalizations.of(context)!.kirans_per_day(plan.targetKirans)}\n• ${AppLocalizations.of(context)!.kirans_per_week(plan.targetKirans * 7)}'
                  : '• ${AppLocalizations.of(context)!.choose_start_kiran}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 4),
            Text(
              plan.reminderTimes.isNotEmpty
                  ? '• ${AppLocalizations.of(context)!.daily_reminder_at(plan.reminderTimes[0].format12Hour())}'
                  : "• ${AppLocalizations.of(context)!.no_reminders_set}",
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handlePlanAction(plan, value),
          itemBuilder:
              (context) => [
                PopupMenuItem(
                  value: 'activate',
                  enabled: !isActive,
                  child: Row(
                    children: [
                      Icon(
                        isActive ? Icons.play_arrow : Icons.pause,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isActive
                            ? AppLocalizations.of(context)!.already_active
                            : AppLocalizations.of(context)!.set_as_active,
                        style:
                            isActive
                                ? TextStyle(
                                  color: Theme.of(context).colorScheme.onPrimary
                                      .withValues(alpha: 0.5),
                                )
                                : TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary,
                                ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        Icons.edit,
                        color: Theme.of(context).colorScheme.onPrimary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.reading_plans_edit,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red.shade300),
                      const SizedBox(width: 8),
                      Text(
                        AppLocalizations.of(context)!.reading_plans_delete,
                        style: TextStyle(color: Colors.red.shade300),
                      ),
                    ],
                  ),
                ),
              ],
        ),
        onTap: () => _viewPlanDetails(plan),
      ),
    );
  }

  Widget _buildProgressTab() {
    final activePlan = _readingPlanService.activePlan;

    if (activePlan == null) {
      return _buildNoPlanState();
    }
    if (!activePlan.hasStartKiran) {
      return _buildChooseStartKiran(activePlan);
    }

    final weeks = activePlan.readingSchedule.recentWeeks(DateTime.now());
    final progressSummary = _readingPlanService.getDailyProgressSummary();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWeekList(weeks),
          const SizedBox(height: 8),
          _buildProgressCalendar(progressSummary),
        ],
      ),
    );
  }

  Widget _buildWeekList(List<WeekProgress> weeks) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.reading_plan_weeks,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            if (weeks.isEmpty)
              Text(l10n.no_activity)
            else
              for (final week in weeks)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${week.weekStart.day}/${week.weekStart.month} – ${week.weekEnd.day}/${week.weekEnd.month}',
                  ),
                  subtitle: Text(
                    l10n.week_progress_count(week.read, week.target),
                  ),
                  trailing: Text(
                    _weekStatusLabel(week.status),
                    style: TextStyle(
                      color: _weekStatusColor(week.status),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  String _weekStatusLabel(WeekStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case WeekStatus.successful:
        return l10n.week_successful;
      case WeekStatus.missed:
        return l10n.week_missed;
      case WeekStatus.inProgress:
        return l10n.week_in_progress;
      case WeekStatus.inactive:
        return l10n.no_activity;
    }
  }

  Color _weekStatusColor(WeekStatus status) {
    switch (status) {
      case WeekStatus.successful:
        return Colors.green;
      case WeekStatus.missed:
        return Colors.red;
      case WeekStatus.inProgress:
        return Theme.of(context).colorScheme.primary;
      case WeekStatus.inactive:
        return Colors.grey;
    }
  }

  Widget _buildProgressCalendar(List<Map<String, dynamic>> progressSummary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.progress_calendar,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 4,
              ),
              itemCount: progressSummary.length,
              itemBuilder: (context, index) {
                final day = progressSummary[index];
                final date = day['date'] as DateTime;
                final goalAchieved = day['goalAchieved'] as bool;
                final progress = (day['progressPercentage'] as double).clamp(
                  0.0,
                  1.0,
                );

                Color cellColor;
                if (goalAchieved) {
                  cellColor = Colors.green;
                } else if (progress > 0.5) {
                  cellColor = Colors.orange;
                } else if (progress > 0.0) {
                  cellColor = Colors.blue.withValues(alpha: 0.5);
                } else {
                  cellColor = Colors.grey[300]!;
                }

                return Container(
                  decoration: BoxDecoration(
                    color: cellColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Center(
                    child: Text(
                      '${date.day}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildLegendItem(
                  Colors.green,
                  AppLocalizations.of(context)!.goal_achieved,
                ),
                _buildLegendItem(
                  Colors.orange,
                  AppLocalizations.of(context)!.partial,
                ),
                _buildLegendItem(
                  Colors.blue.withValues(alpha: 0.5),
                  AppLocalizations.of(context)!.started,
                ),
                _buildLegendItem(
                  Colors.grey[300]!,
                  AppLocalizations.of(context)!.no_activity,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildNoPlanState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 24),
            Text(
              AppLocalizations.of(context)!.no_reading_plan,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              AppLocalizations.of(context)!.create_first_reading_plan,
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => _navigateToCreatePlan(),
              icon: const Icon(Icons.add),
              label: Text(AppLocalizations.of(context)!.create_reading_plan),
            ),
          ],
        ),
      ),
    );
  }

  // Action methods
  void _navigateToCreatePlan() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateReadingPlanPage()),
    );

    if (result == true) {
      await _readingPlanService.loadReadingPlans();
      setState(() {});
    }
  }

  void _editPlan(ReadingPlan plan) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateReadingPlanPage(editingPlan: plan),
      ),
    );

    if (result == true) {
      await _readingPlanService.loadReadingPlans();
      setState(() {});
    }
  }

  void _viewPlanDetails(ReadingPlan plan) async {}

  void _handlePlanAction(ReadingPlan plan, String action) async {
    switch (action) {
      case 'activate':
        await _readingPlanService.setActivePlan(plan.id);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.plan_now_active(plan.title),
            ),
          ),
        );
        break;
      case 'edit':
        _editPlan(plan);
        break;
      case 'delete':
        _confirmDeletePlan(plan);
        break;
    }
  }

  void _confirmDeletePlan(ReadingPlan plan) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.delete_reading_plan),
            content: Text(
              AppLocalizations.of(context)!.confirm_delete_plan(plan.title),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context)!.reading_plans_cancel),
              ),
              TextButton(
                onPressed: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final localizations = AppLocalizations.of(context)!;
                  Navigator.pop(context);
                  await _readingPlanService.deleteReadingPlan(plan.id);
                  setState(() {});
                  messenger.showSnackBar(
                    SnackBar(content: Text(localizations.reading_plan_deleted)),
                  );
                },
                child: Text(AppLocalizations.of(context)!.reading_plans_delete),
              ),
            ],
          ),
    );
  }

  Future<void> _openPlanKiran(int kiran) async {
    await openKiran(context, kiranIndex: kiran);
    if (mounted) setState(() {});
  }

  Future<void> _startReading() async {
    final plan = _readingPlanService.activePlan;
    if (plan == null || !plan.hasStartKiran) {
      Navigator.pushNamed(context, '/bookmainpage');
      return;
    }
    final today = plan.assignmentOn(DateTime.now());
    final kiran =
        today.remaining.isNotEmpty
            ? today.remaining.first
            : plan.readingSchedule.nextUnfinishedOn(DateTime.now());
    if (kiran == null) return;
    await _openPlanKiran(kiran);
  }

  void _testReminder() async {
    final plan = _readingPlanService.activePlan;
    if (plan != null && plan.hasStartKiran) {
      await _notificationService.showTodayReadingPlanNotification(plan);
    } else {
      await _notificationService.showReadingSuggestion();
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context)!.test_reminder_sent),
          action: SnackBarAction(
            label: 'Check Sound',
            onPressed: () => _showSoundTroubleshootingDialog(),
          ),
        ),
      );
    }
  }

  void _showSoundTroubleshootingDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('🔊 Notification Sound Troubleshooting'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('If you can\'t hear notification sounds, try:'),
                const SizedBox(height: 12),
                const Text(
                  '• Check if your device is not in silent/vibrate mode',
                ),
                const Text('• Increase notification volume in system settings'),
                const Text(
                  '• Go to Android Settings > Apps > Saxat Savita > Notifications',
                ),
                const Text(
                  '• Ensure "Reading Reminders" channel has sound enabled',
                ),
                const Text(
                  '• Check "Do Not Disturb" mode is not blocking notifications',
                ),
                const SizedBox(height: 12),
                const Text(
                  'The app just sent test notifications with sound enabled.',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Got it'),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  //await _notificationService.testNotificationSound();
                },
                child: const Text('Test Again'),
              ),
            ],
          ),
    );
  }

  void _showProgressSummary() {
    final activePlan = _readingPlanService.activePlan;
    if (activePlan == null) return;

    final statistics = _readingPlanService.getReadingStatistics();

    final goalsAchieved = statistics['goalsAchieved'];
    final completionRatePercent = (statistics['completionRate'] * 100)
        .toStringAsFixed(1);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.reading_plans_progress),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${AppLocalizations.of(context)!.plan_name}: ${activePlan.title}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  '${AppLocalizations.of(context)!.start_date}: ${activePlan.startDate.toLocal().toString().split(' ')[0]}',
                ),
                const SizedBox(height: 12),

                Text(
                  '${AppLocalizations.of(context)!.totalReadingTime}: ${_getTotalReadingTime(statistics['totalSeconds'])}',
                ),
                Text(
                  '${AppLocalizations.of(context)!.this_week}: ${AppLocalizations.of(context)!.week_progress_count(statistics['weekRead'] as int, statistics['weekTarget'] as int)}',
                ),
                Text(
                  '${AppLocalizations.of(context)!.total_kirans}: ${statistics['totalKirans']}',
                ),
                Text(
                  '${AppLocalizations.of(context)!.goals_achieved}: $goalsAchieved',
                ),
                Text(
                  '${AppLocalizations.of(context)!.completion_rate}: $completionRatePercent%',
                ),
                Text(
                  '${AppLocalizations.of(context)!.streak_days}: ${statistics['streakDays']}',
                ),
                const SizedBox(height: 12),
                if (activePlan.endDate != null)
                  Text(
                    '${AppLocalizations.of(context)!.end_date}: ${activePlan.endDate!.toLocal().toString().split(' ')[0]}',
                  ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(AppLocalizations.of(context)!.close),
              ),
            ],
          ),
    );
  }

  String _getTotalReadingTime(int totalSeconds) {
    final duration = Duration(seconds: totalSeconds);
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}h : ${minutes}m : ${seconds}s';
    } else if (minutes > 0) {
      return '${minutes}m : ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }
}
