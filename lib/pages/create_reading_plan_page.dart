import 'package:flutter/material.dart';
import 'package:saxatsavita_flutter/components/appbar.dart';
import 'package:saxatsavita_flutter/models/reading_plan_model.dart';
import 'package:saxatsavita_flutter/services/reading_plan_service.dart';

class CreateReadingPlanPage extends StatefulWidget {
  final ReadingPlan? editingPlan;

  const CreateReadingPlanPage({super.key, this.editingPlan});

  @override
  State<CreateReadingPlanPage> createState() => _CreateReadingPlanPageState();
}

class _CreateReadingPlanPageState extends State<CreateReadingPlanPage> {
  final _formKey = GlobalKey<FormState>();
  final ReadingPlanService _readingPlanService = ReadingPlanService();

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;

  int _targetSeconds = 15 * 60;
  int _targetKirans = 1;
  int _reminderHour = 7;
  int _reminderMinutes = 20;
  bool _enableReminders = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();

    // Initialize controllers with existing data if editing
    _titleController = TextEditingController(
      text: widget.editingPlan?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.editingPlan?.description ?? '',
    );

    // Initialize form values if editing
    if (widget.editingPlan != null) {
      _targetSeconds = widget.editingPlan!.targetSeconds;
      _targetKirans = widget.editingPlan!.targetKirans;
      _enableReminders = widget.editingPlan!.reminderTimes.isNotEmpty;
      if (_enableReminders && widget.editingPlan!.reminderTimes.isNotEmpty) {
        final firstReminder = widget.editingPlan!.reminderTimes.first;
        _reminderHour = firstReminder.hour;
        _reminderMinutes = firstReminder.minute;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.editingPlan != null;

    return Scaffold(
      appBar: buildAppBar(
        context,
        title: isEditing ? 'Edit Reading Plan' : 'Create Reading Plan',
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBasicInfoSection(),
                const SizedBox(height: 24),
                _buildGoalsSection(),
                const SizedBox(height: 24),
                _buildRemindersSection(),
                const SizedBox(height: 32),
                _buildPreviewSection(),
                const SizedBox(height: 32),
                _buildActionButtons(isEditing),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Basic Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Plan Title
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Plan Title',
                hintText: 'e.g., Morning Spiritual Reading',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title for your reading plan';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Plan Description
            TextFormField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Describe your reading goals and motivation...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Goals', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // Target Minutes
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Reading Time Goal',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed:
                          _targetSeconds > 5 * 60
                              ? () {
                                setState(() {
                                  _targetSeconds = (_targetSeconds - 5 * 60)
                                      .clamp(5 * 60, 120 * 60);
                                });
                              }
                              : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Container(
                      width: 80,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${_targetSeconds ~/ 60} mins',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _targetSeconds < 120 * 60
                              ? () {
                                setState(() {
                                  _targetSeconds = (_targetSeconds + 5 * 60)
                                      .clamp(5 * 60, 120 * 60);
                                });
                              }
                              : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Target Kirans
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Kirans to Complete',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed:
                          _targetKirans > 1
                              ? () {
                                setState(() {
                                  _targetKirans = (_targetKirans - 1).clamp(
                                    1,
                                    10,
                                  );
                                });
                              }
                              : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Container(
                      width: 60,
                      padding: const EdgeInsets.symmetric(
                        vertical: 8,
                        horizontal: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$_targetKirans',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    IconButton(
                      onPressed:
                          _targetKirans < 10
                              ? () {
                                setState(() {
                                  _targetKirans = (_targetKirans + 1).clamp(
                                    1,
                                    10,
                                  );
                                });
                              }
                              : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),
            Text(
              'Recommended: Start with shorter goals and gradually increase as you build the habit.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemindersSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Reminders', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),

            // Enable Reminders Toggle
            SwitchListTile(
              title: const Text('Enable Daily Reminders'),
              subtitle: Text(
                _enableReminders
                    ? 'Get notified to maintain your reading habit'
                    : 'No reminders will be sent',
              ),
              value: _enableReminders,
              onChanged: (value) {
                setState(() {
                  _enableReminders = value;
                });
              },
            ),

            if (_enableReminders) ...[
              const SizedBox(height: 16),

              // Reminder Time
              ListTile(
                title: const Text('Reminder Time'),
                subtitle: Text('Daily reminder at ${_formatReminderTime()}'),
                leading: const Icon(Icons.access_time),
                trailing: const Icon(Icons.chevron_right),
                onTap: _selectReminderTime,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewSection() {
    return Card(
      color: Theme.of(context).primaryColor.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.visibility, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Text(
                  'Plan Preview',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildPreviewItem(
                  icon: Icons.timer,
                  value: '${_targetSeconds ~/ 60} minutes',
                  label: 'Daily Reading',
                ),
                _buildPreviewItem(
                  icon: Icons.book,
                  value: '$_targetKirans',
                  label: 'Kirans',
                ),
                _buildPreviewItem(
                  icon: Icons.notifications,
                  value: _enableReminders ? 'ON' : 'OFF',
                  label: 'Reminders',
                ),
              ],
            ),

            if (_enableReminders) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.schedule, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 8),
                  Text(
                    'Daily reminder at ${_formatReminderTime()}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).primaryColor,
          ),
        ),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildActionButtons(bool isEditing) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _isLoading ? null : _savePlan,
            child:
                _isLoading
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : Text(isEditing ? 'Update Plan' : 'Create Plan'),
          ),
        ),
      ],
    );
  }

  String _formatReminderTime() {
    final hour = _reminderHour;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final displayMinutes = _reminderMinutes.toString().padLeft(2, '0');
    return '$displayHour:$displayMinutes $period';
  }

  void _selectReminderTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: _reminderHour, minute: _reminderMinutes),
      helpText: 'Select Reminder Time',
      cancelText: 'Cancel',
      confirmText: 'Save',
    );

    if (picked != null) {
      setState(() {
        _reminderHour = picked.hour;
        _reminderMinutes = picked.minute;
      });
    }
  }

  void _savePlan() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.editingPlan != null) {
        // Create updated plan with new values
        final updatedPlan = ReadingPlan(
          id: widget.editingPlan!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: widget.editingPlan!.type,
          targetSeconds: _targetSeconds,
          targetKirans: _targetKirans,
          startDate: widget.editingPlan!.startDate,
          endDate: widget.editingPlan!.endDate,
          isActive: widget.editingPlan!.isActive,
          reminderTimes:
              _enableReminders
                  ? [
                    ReminderTime(hour: _reminderHour, minute: _reminderMinutes),
                  ]
                  : [],
          dailyProgress: widget.editingPlan!.dailyProgress,
          dailyKirans: widget.editingPlan!.dailyKirans,
          createdAt: widget.editingPlan!.createdAt,
          updatedAt: DateTime.now(),
        );

        await _readingPlanService.updateReadingPlan(updatedPlan);
      } else {
        // Create new plan
        await _readingPlanService.createReadingPlan(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          type: ReadingPlanType.custom,
          targetSeconds: _targetSeconds,
          targetKirans: _targetKirans,
          reminderTimes:
              _enableReminders
                  ? [
                    ReminderTime(hour: _reminderHour, minute: _reminderMinutes),
                  ]
                  : [],
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.editingPlan != null
                  ? 'Reading plan updated successfully!'
                  : 'Reading plan created successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error saving reading plan: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving plan: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
