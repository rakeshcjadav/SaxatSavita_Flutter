import 'package:flutter/material.dart';
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
    } catch (e) {
      debugPrint('Error initializing services: $e');
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.reading_plans),
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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "add",
            onPressed: () => _navigateToCreatePlan(),
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayTab() {
    final activePlan = _readingPlanService.activePlan;

    if (activePlan == null) {
      return _buildNoPlanState();
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

  Widget _buildTodayProgress(ReadingPlan plan) {
    final progressPercentage = plan.todayProgressPercentage;
    final isGoalAchieved = plan.todayGoalAchieved;

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
                    isGoalAchieved
                        ? AppLocalizations.of(context)!.today_goal_achieved
                        : AppLocalizations.of(context)!.today_progress,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress bar
            LinearProgressIndicator(
              value: progressPercentage,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                isGoalAchieved ? Colors.green : Theme.of(context).primaryColor,
              ),
            ),
            const SizedBox(height: 12),

            // Progress details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${plan.todayProgress ~/ 60}m:${plan.todayProgress % 60}s/${plan.targetSeconds ~/ 60} ${AppLocalizations.of(context)!.minutes}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      AppLocalizations.of(context)!.reading_time,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${plan.todayKirans.length}/${plan.targetKirans} ${AppLocalizations.of(context)!.kirans}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      AppLocalizations.of(context)!.completed,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
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
        shape: MaterialStateProperty.all<RoundedRectangleBorder>(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
        ),
      ),
      icon: Icon(icon, size: 32, color: Theme.of(context).primaryColor),
      label: Text(label, style: Theme.of(context).textTheme.bodySmall),
    );
  }

  Widget _buildTodayStats(ReadingPlan plan) {
    final stats = _readingPlanService.getReadingStatistics();

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
                  '${stats['goalsAchieved']} ${AppLocalizations.of(context)!.goals}',
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
      color: color.withOpacity(0.1),
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
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final localizations = AppLocalizations.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 12.0),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16.0),
        leading: InkWell(
          onTap: () async {
            await _readingPlanService.setActivePlan(plan.id);
            setState(() {});
            scaffoldMessenger.showSnackBar(
              SnackBar(
                content: Text(localizations!.plan_now_active(plan.title)),
              ),
            );
          },
          child: CircleAvatar(
            backgroundColor:
                isActive ? Theme.of(context).primaryColor : Colors.grey,
            child: Icon(
              isActive ? Icons.play_arrow : Icons.pause,
              color: Colors.white,
            ),
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
              '• ${AppLocalizations.of(context)!.min_per_day(plan.targetSeconds ~/ 60)}\n• ${plan.targetKirans} ${AppLocalizations.of(context)!.kirans}\n• ${AppLocalizations.of(context)!.day_streak(plan.streakDays)}',
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
                  child: Text(
                    isActive
                        ? AppLocalizations.of(context)!.already_active
                        : AppLocalizations.of(context)!.set_as_active,
                    style:
                        isActive
                            ? TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimary.withValues(alpha: 0.5),
                            )
                            : TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                  ),
                ),
                PopupMenuItem(
                  value: 'edit',
                  child: Text(
                    AppLocalizations.of(context)!.reading_plans_edit,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Text(
                    AppLocalizations.of(context)!.reading_plans_delete,
                    style: TextStyle(color: Colors.red.shade300),
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

    final progressSummary = _readingPlanService.getDailyProgressSummary();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressChart(progressSummary),
          const SizedBox(height: 24),
          _buildProgressCalendar(progressSummary),
        ],
      ),
    );
  }

  Widget _buildProgressChart(List<Map<String, dynamic>> progressSummary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)!.last_30_days_progress,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Container(
              height: 200,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children:
                    progressSummary.map((day) {
                      final progress = (day['progressPercentage'] as double)
                          .clamp(0.0, 1.0);
                      final goalAchieved = day['goalAchieved'] as bool;

                      return Container(
                        width: 8,
                        height: 180 * progress,
                        margin: const EdgeInsets.symmetric(horizontal: 1),
                        decoration: BoxDecoration(
                          color:
                              goalAchieved
                                  ? Colors.green
                                  : Theme.of(
                                    context,
                                  ).primaryColor.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
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
                  cellColor = Colors.blue.withOpacity(0.5);
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
                  Colors.blue.withOpacity(0.5),
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

  void _viewPlanDetails(ReadingPlan plan) async {
    // TODO: Implement plan details page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(AppLocalizations.of(context)!.plan_details_coming_soon),
      ),
    );
  }

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
                  Navigator.pop(context);
                  await _readingPlanService.deleteReadingPlan(plan.id);
                  setState(() {});
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        AppLocalizations.of(context)!.reading_plan_deleted,
                      ),
                    ),
                  );
                },
                child: Text(AppLocalizations.of(context)!.reading_plans_delete),
              ),
            ],
          ),
    );
  }

  void _startReading() {
    // Navigate to book main page or reading page
    Navigator.pushNamed(context, '/bookmainpage');
    // You can add navigation to a specific reading page here
  }

  void _testReminder() async {
    await _notificationService.showReadingSuggestion();

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
}
