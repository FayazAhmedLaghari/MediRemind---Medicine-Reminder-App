import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/reminder_viewmodel.dart';
import '../../viewmodels/medicine_viewmodel.dart';
import '../../models/reminder_model.dart';
import '../../core/app_colors.dart';
import '../../service/notification_service.dart';
class RemindersView extends StatefulWidget {
  const RemindersView({super.key});
  
  @override
  State<RemindersView> createState() => _RemindersViewState();
}


class _RemindersViewState extends State<RemindersView> {
  late DateTime _selectedDate;
  late DateTime _displayedDate;
  late List<Reminder> _dayReminders;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _displayedDate = DateTime.now();
    _dayReminders = [];

    Future.microtask(() async {
      final reminderVM = Provider.of<ReminderViewModel>(context, listen: false);
      await reminderVM.loadReminders();
      await _loadDayReminders();
    });
  }

  Future<void> _loadDayReminders() async {
    final reminderVM = Provider.of<ReminderViewModel>(context, listen: false);
    final reminders = await reminderVM.getRemindersByDate(_selectedDate);
    setState(() {
      _dayReminders = reminders;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Reminders'),
        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primaryBlue,
        elevation: 0,
        actions: [
          // Debug button to show pending notifications
          IconButton(
            icon: const Icon(Icons.list_alt),
            tooltip: 'Debug Pending Notifications',
            onPressed: () async {
              final notificationService = NotificationService();
              await notificationService.debugPendingNotifications();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('📋 Pending notifications logged to console'),
                    backgroundColor: Colors.orange,
                    duration: Duration(seconds: 2),
                  ),
                );
              }
            },
          ),
          // Test scheduled notification (1 min)
          IconButton(
            icon: const Icon(Icons.alarm_add),
            tooltip: 'Test Scheduled (1 min)',
            onPressed: () async {
              final notificationService = NotificationService();
              await notificationService.testScheduledNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        '⏱️ Scheduled test notification for 1 minute! Check console.'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
          // Instant test notification
          IconButton(
            icon: const Icon(Icons.notifications_active),
            tooltip: 'Test Instant Notification',
            onPressed: () async {
              final notificationService = NotificationService();
              await notificationService.showTestNotification();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        '🔔 Test notification sent! Check your notification panel.'),
                    backgroundColor: Colors.blue,
                    duration: Duration(seconds: 3),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<ReminderViewModel>(
        builder: (context, vm, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // 📅 Calendar Section
                Container(
                  color: isDark
                      ? AppColors.darkSurface
                      : AppColors.primaryBlue.withOpacity(0.1),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Simple Calendar Widget
                      _buildCalendar(),
                      const SizedBox(height: 16),
                      // Selected Date
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.darkSecondary
                              : AppColors.primaryBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 📋 Reminders List
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reminders for this day',
                        style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 12),
                      if (_dayReminders.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.calendar_today_outlined,
                                  size: 64,
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No reminders for this day',
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.darkTextSecondary
                                        : Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _dayReminders.length,
                          itemBuilder: (context, index) {
                            final reminder = _dayReminders[index];
                            return _buildReminderCard(context, reminder, vm);
                          },
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddReminderDialog(context),
        backgroundColor: isDark ? AppColors.darkSecondary : AppColors.primaryBlue,
        icon: const Icon(Icons.add),
        label: const Text('Add Reminder'),
      ),
    );
  }

  // 📅 Calendar Widget
  Widget _buildCalendar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    final daysInMonth =
        DateTime(_displayedDate.year, _displayedDate.month + 1, 0).day;
    final firstDayOfMonth =
        DateTime(_displayedDate.year, _displayedDate.month, 1);
    final startingDayOfWeek = firstDayOfMonth.weekday;

    return Column(
      children: [
        // Month/Year Header
        Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatMonthYear(_displayedDate),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: Icon(Icons.chevron_left, color: textColor),
                      onPressed: () {
                        setState(() {
                          _displayedDate = DateTime(
                              _displayedDate.year, _displayedDate.month - 1);
                        });
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: Icon(Icons.chevron_right, color: textColor),
                      onPressed: () {
                        setState(() {
                          _displayedDate = DateTime(
                              _displayedDate.year, _displayedDate.month + 1);
                        });
                      },
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // Day labels
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
                .map((day) => Expanded(
                      child: Center(
                        child: Text(
                          day,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ),

        // Calendar grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: startingDayOfWeek + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startingDayOfWeek) {
              return const SizedBox();
            }

            final day = index - startingDayOfWeek + 1;
            final date =
                DateTime(_displayedDate.year, _displayedDate.month, day);
            final isSelected = _isSameDay(date, _selectedDate);
            final isToday = _isSameDay(date, DateTime.now());

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedDate = date;
                });
                _loadDayReminders();
              },
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.darkSecondary : AppColors.primaryBlue)
                      : isToday
                          ? AppColors.lightBlue.withOpacity(0.3)
                          : Colors.transparent,
                  border: isToday
                      ? Border.all(
                          color: isDark
                              ? AppColors.darkSecondary
                              : AppColors.primaryBlue,
                          width: 2,
                        )
                      : null,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected
                          ? Colors.white
                          : textColor,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  // 💊 Reminder Card
  Widget _buildReminderCard(
    BuildContext context,
    Reminder reminder,
    ReminderViewModel vm,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    final statusColor = reminder.status == 'completed'
        ? Colors.green
        : reminder.status == 'missed'
            ? Colors.red
            : Colors.orange;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: statusColor,
            width: 4,
          ),
        ),
        borderRadius: BorderRadius.circular(12),
        color: cardColor,
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Medicine name and time
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reminder.medicineName,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dosage: ${reminder.dosage}',
                        style: TextStyle(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      reminder.reminderTime,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkSecondary
                            : AppColors.primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        reminder.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (reminder.notes.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Note: ${reminder.notes}',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark
                      ? AppColors.darkTextSecondary
                      : Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 8),
            // 🔊📳 Sound & Vibration indicators
            Row(
              children: [
                _buildAlertChip(
                  icon: reminder.soundEnabled
                      ? Icons.volume_up
                      : Icons.volume_off,
                  label: reminder.soundEnabled ? 'Sound ON' : 'Sound OFF',
                  isEnabled: reminder.soundEnabled,
                  isDark: isDark,
                ),
                const SizedBox(width: 8),
                _buildAlertChip(
                  icon: reminder.vibrationEnabled
                      ? Icons.vibration
                      : Icons.phone_android,
                  label: reminder.vibrationEnabled ? 'Vibration ON' : 'Vibration OFF',
                  isEnabled: reminder.vibrationEnabled,
                  isDark: isDark,
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (reminder.status != 'completed')
                  TextButton.icon(
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Mark Done'),
                    onPressed: () async {
                      await vm.updateReminder(
                        reminder.copyWith(status: 'completed'),
                      );
                      await _loadDayReminders();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Marked as completed'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    },
                  ),
                const SizedBox(width: 8),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Delete'),
                  onPressed: () =>
                      _showDeleteConfirmation(context, reminder, vm),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Parse stored times string "08:00,14:00,20:00" into list of TimeOfDay
  List<TimeOfDay> _parseMedicineTimes(String timeStr) {
    if (timeStr.isEmpty) return [];
    final parts = timeStr.split(',').map((t) => t.trim()).toList();
    final List<TimeOfDay> times = [];
    for (final part in parts) {
      if (part.contains(':')) {
        final timeParts = part.split(':');
        final hour = int.tryParse(timeParts[0]) ?? 0;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        times.add(TimeOfDay(hour: hour, minute: minute));
      }
    }
    return times;
  }

  /// Parse frequency count from stored string like "2 times/day"
  int _parseFrequencyCount(String frequency) {
    if (frequency.isEmpty) return 1;
    final match = RegExp(r'(\d+)').firstMatch(frequency);
    if (match != null) {
      return int.tryParse(match.group(1)!) ?? 1;
    }
    return 1;
  }

  /// Format TimeOfDay to readable string like "08:00 AM"
  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  // ➕ Add Reminder Dialog
  void _showAddReminderDialog(BuildContext context) {
    final medicineVM = Provider.of<MedicineViewModel>(context, listen: false);
    final reminderVM = Provider.of<ReminderViewModel>(context, listen: false);

    String? selectedMedicineId;
    String? selectedMedicineName;
    String? selectedDosage;
    String notesText = '';

    // Medicine frequency & times
    int frequencyCount = 0;
    List<TimeOfDay> medicineTimes = [];

    // 🔊 Sound & vibration preferences (default: both ON)
    bool soundEnabled = true;
    bool vibrationEnabled = true;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          final theme = Theme.of(dialogContext);
          final isDark = theme.brightness == Brightness.dark;
          final dialogTextColor =
              theme.textTheme.bodyLarge?.color ?? Colors.black87;

          return AlertDialog(
            title: Text(
              'Add Reminder',
              style: TextStyle(color: dialogTextColor),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Medicine Dropdown
                  DropdownButtonFormField<String>(
                    dropdownColor: theme.cardColor,
                    style: TextStyle(color: dialogTextColor),
                    decoration: InputDecoration(
                      labelText: 'Select Medicine',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: const Icon(Icons.medication),
                    ),
                    items: medicineVM.medicines
                        .map((medicine) => DropdownMenuItem(
                              value: medicine.id.toString(),
                              child: Text(
                                medicine.name,
                                style: TextStyle(color: dialogTextColor),
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMedicineId = value;
                        final medicine = medicineVM.medicines
                            .firstWhere((m) => m.id.toString() == value);
                        selectedMedicineName = medicine.name;
                        selectedDosage = medicine.dosage;

                        // Parse frequency and times from medicine
                        frequencyCount =
                            _parseFrequencyCount(medicine.frequency);
                        medicineTimes =
                            _parseMedicineTimes(medicine.time);
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Show medicine times info if a medicine is selected
                  if (selectedMedicineId != null && medicineTimes.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.darkSecondary.withOpacity(0.15)
                            : AppColors.primaryBlue.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark
                              ? AppColors.darkSecondary.withOpacity(0.3)
                              : AppColors.primaryBlue.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.schedule,
                                  size: 18,
                                  color: isDark
                                      ? AppColors.darkSecondary
                                      : AppColors.primaryBlue),
                              const SizedBox(width: 8),
                              Text(
                                '$frequencyCount time${frequencyCount > 1 ? 's' : ''}/day',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.darkSecondary
                                      : AppColors.primaryBlue,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Reminders will be created for:',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: medicineTimes.map((time) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.darkSecondary
                                      : AppColors.primaryBlue,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _formatTimeOfDay(time),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Show message if medicine has no times set
                  if (selectedMedicineId != null && medicineTimes.isEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.orange.withOpacity(0.3),
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.warning_amber,
                              size: 18, color: Colors.orange),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No times set for this medicine. Please edit the medicine to set times.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ─── 🔊 Sound & Vibration Settings ───────────────
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 8, horizontal: 4),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.withOpacity(0.1)
                          : Colors.grey.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.15),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding:
                              const EdgeInsets.only(left: 12, bottom: 4),
                          child: Text(
                            'Alert Settings',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? AppColors.darkSecondary
                                  : AppColors.primaryBlue,
                            ),
                          ),
                        ),
                        // Sound toggle
                        SwitchListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          secondary: Icon(
                            soundEnabled
                                ? Icons.volume_up
                                : Icons.volume_off,
                            color: soundEnabled
                                ? (isDark
                                    ? AppColors.darkSecondary
                                    : AppColors.primaryBlue)
                                : Colors.grey,
                            size: 22,
                          ),
                          title: Text(
                            'Sound',
                            style: TextStyle(
                              fontSize: 14,
                              color: dialogTextColor,
                            ),
                          ),
                          subtitle: Text(
                            soundEnabled
                                ? 'Alarm sound will play'
                                : 'No sound',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : Colors.grey[600],
                            ),
                          ),
                          value: soundEnabled,
                          activeColor: isDark
                              ? AppColors.darkSecondary
                              : AppColors.primaryBlue,
                          onChanged: (val) {
                            setState(() {
                              soundEnabled = val;
                            });
                          },
                        ),
                        // Vibration toggle
                        SwitchListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          secondary: Icon(
                            vibrationEnabled
                                ? Icons.vibration
                                : Icons.phone_android,
                            color: vibrationEnabled
                                ? (isDark
                                    ? AppColors.darkSecondary
                                    : AppColors.primaryBlue)
                                : Colors.grey,
                            size: 22,
                          ),
                          title: Text(
                            'Vibration',
                            style: TextStyle(
                              fontSize: 14,
                              color: dialogTextColor,
                            ),
                          ),
                          subtitle: Text(
                            vibrationEnabled
                                ? 'Device will vibrate'
                                : 'No vibration',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark
                                  ? AppColors.darkTextSecondary
                                  : Colors.grey[600],
                            ),
                          ),
                          value: vibrationEnabled,
                          activeColor: isDark
                              ? AppColors.darkSecondary
                              : AppColors.primaryBlue,
                          onChanged: (val) {
                            setState(() {
                              vibrationEnabled = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextField(
                    maxLines: 3,
                    style: TextStyle(color: dialogTextColor),
                    decoration: InputDecoration(
                      labelText: 'Notes (optional)',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Add any notes about this reminder',
                    ),
                    onChanged: (value) {
                      notesText = value;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: (selectedMedicineId != null &&
                        medicineTimes.isNotEmpty)
                    ? () async {
                        final userId =
                            FirebaseAuth.instance.currentUser?.uid ?? '';
                        final dateStr =
                            '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';

                        debugPrint(
                            '🎯 [VIEW] Creating ${medicineTimes.length} reminders for ${selectedMedicineName!}');
                        debugPrint(
                            '🎯 [VIEW] Sound: ${soundEnabled ? "ON" : "OFF"}, Vibration: ${vibrationEnabled ? "ON" : "OFF"}');

                        bool allSuccess = true;

                        // Create one reminder for each time slot
                        for (int i = 0; i < medicineTimes.length; i++) {
                          final time = medicineTimes[i];
                          final timeStr =
                              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

                          final reminder = Reminder(
                            medicineId: selectedMedicineId!,
                            medicineName: selectedMedicineName!,
                            reminderDate: dateStr,
                            reminderTime: timeStr,
                            dosage: selectedDosage!,
                            notes: notesText,
                            createdAt: DateTime.now(),
                            userId: userId,
                            soundEnabled: soundEnabled,
                            vibrationEnabled: vibrationEnabled,
                          );

                          debugPrint(
                              '🎯 [VIEW] Creating reminder ${i + 1}/${medicineTimes.length}: $timeStr');

                          final success =
                              await reminderVM.addReminder(reminder);
                          if (!success) {
                            allSuccess = false;
                            debugPrint(
                                '🎯 [VIEW] ❌ Failed to add reminder ${i + 1}');
                          }
                        }
                        // Wait a moment for database to settle
                        await Future.delayed(
                            const Duration(milliseconds: 500));

                        // Reload reminders
                        await reminderVM.loadReminders();
                        await _loadDayReminders();

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(allSuccess
                                  ? '✅ ${medicineTimes.length} reminder${medicineTimes.length > 1 ? 's' : ''} added successfully'
                                  : '⚠️ Some reminders failed to add'),
                              backgroundColor: allSuccess
                                  ? Colors.green
                                  : Colors.orange,
                            ),
                          );
                        }
                      }
                    : null,
                child: Text(
                  medicineTimes.length > 1
                      ? 'Add ${medicineTimes.length} Reminders'
                      : 'Add Reminder',
                ),
              ),
            ],
          );
        },
      ),
    );
  }
  // Delete Confirmation Dialog
  void _showDeleteConfirmation(
    BuildContext context,
    Reminder reminder,
    ReminderViewModel vm,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Reminder?'),
        content: Text(
          'Are you sure you want to delete the reminder for ${reminder.medicineName} at ${reminder.reminderTime}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first

              await vm.deleteReminder(reminder.id!);

              // Reload the reminders list
              await _loadDayReminders();
              
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Reminder deleted'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  // 📅 Format date helper
  String _formatDate(DateTime date) {
    final days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday'
    ];
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];

    return '${days[date.weekday % 7]}, ${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  /// Build a small chip showing sound/vibration status
  Widget _buildAlertChip({
    required IconData icon,
    required String label,
    required bool isEnabled,
    required bool isDark,
  }) {
    final color = isEnabled
        ? (isDark ? AppColors.darkSecondary : AppColors.primaryBlue)
        : Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(isEnabled ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(isEnabled ? 0.3 : 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // 📅 Format month year helper
  String _formatMonthYear(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}
