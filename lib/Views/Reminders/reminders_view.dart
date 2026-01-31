import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/reminder_viewmodel.dart';
import '../../viewmodels/medicine_viewmodel.dart';
import '../../models/reminder_model.dart';
import '../../core/app_colors.dart';

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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medication Reminders'),
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
      ),
      body: Consumer<ReminderViewModel>(
        builder: (context, vm, _) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // 📅 Calendar Section
                Container(
                  color: AppColors.primaryBlue.withOpacity(0.1),
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
                          color: AppColors.primaryBlue,
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
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
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'No reminders for this day',
                                  style: TextStyle(
                                    color: Colors.grey[600],
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
        backgroundColor: AppColors.primaryBlue,
        icon: const Icon(Icons.add),
        label: const Text('Add Reminder'),
      ),
    );
  }

  // 📅 Calendar Widget
  Widget _buildCalendar() {
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
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: IconButton(
                      icon: const Icon(Icons.chevron_left),
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
                      icon: const Icon(Icons.chevron_right),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
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
                      ? AppColors.primaryBlue
                      : isToday
                          ? AppColors.lightBlue.withOpacity(0.3)
                          : Colors.transparent,
                  border: isToday
                      ? Border.all(
                          color: AppColors.primaryBlue,
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
                      color: isSelected ? Colors.white : Colors.black,
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
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Dosage: ${reminder.dosage}',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
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
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
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
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
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

  // ➕ Add Reminder Dialog
  void _showAddReminderDialog(BuildContext context) {
    final medicineVM = Provider.of<MedicineViewModel>(context, listen: false);
    final reminderVM = Provider.of<ReminderViewModel>(context, listen: false);

    String? selectedMedicineId;
    String? selectedMedicineName;
    String? selectedDosage;
    TimeOfDay? selectedTime;
    String notesText = '';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Add Reminder'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Medicine Dropdown
                  DropdownButtonFormField<String>(
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
                              child: Text(medicine.name),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedMedicineId = value;
                        final medicine = medicineVM.medicines
                            .firstWhere((m) => m.id.toString() == value);
                        selectedMedicineName = medicine.name;
                        selectedDosage = medicine.dosage;
                      });
                    },
                  ),
                  const SizedBox(height: 16),

                  // Time Picker
                  ListTile(
                    title: const Text('Reminder Time'),
                    subtitle: Text(
                      selectedTime == null
                          ? 'Select time'
                          : selectedTime!.format(context),
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                      );
                      if (time != null) {
                        setState(() => selectedTime = time);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // Notes
                  TextField(
                    maxLines: 3,
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
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (selectedMedicineId != null && selectedTime != null) {
                    final reminder = Reminder(
                      medicineId: selectedMedicineId!,
                      medicineName: selectedMedicineName!,
                      reminderDate:
                          '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}',
                      reminderTime:
                          '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
                      dosage: selectedDosage!,
                      notes: notesText,
                      createdAt: DateTime.now(),
                    );

                    reminderVM.addReminder(reminder).then((_) async {
                      // Wait a moment for database to settle
                      await Future.delayed(const Duration(milliseconds: 300));

                      // Reload reminders from database
                      await reminderVM.loadReminders();

                      // Load reminders for the selected day
                      await _loadDayReminders();

                      if (context.mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('✅ Reminder added successfully'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      }
                    });
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Please select medicine and time'),
                        backgroundColor: Colors.orange,
                      ),
                    );
                  }
                },
                child: const Text('Add'),
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
