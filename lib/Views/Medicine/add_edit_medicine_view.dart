import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../models/medicine_model.dart';
import '../../viewmodels/medicine_viewmodel.dart';
import '../../core/app_colors.dart';

class AddEditMedicineView extends StatefulWidget {
  final Medicine? medicine;
  final Map<String, String>? autoData;

  const AddEditMedicineView({super.key, this.medicine, this.autoData});

  @override
  State<AddEditMedicineView> createState() => _AddEditMedicineViewState();
}

class _AddEditMedicineViewState extends State<AddEditMedicineView>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  late TextEditingController nameCtrl;
  late TextEditingController dosageCtrl;
  late TextEditingController notesCtrl;

  // Frequency dropdown value (1, 2, 3, 4)
  int _frequencyCount = 1;

  // List of selected times (one per frequency count)
  List<TimeOfDay?> _selectedTimes = [null];

  // Frequency options
  static const List<Map<String, dynamic>> _frequencyOptions = [
    {'value': 1, 'label': '1 time/day'},
    {'value': 2, 'label': '2 times/day'},
    {'value': 3, 'label': '3 times/day'},
    {'value': 4, 'label': '4 times/day'},
  ];

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();

    if (widget.medicine != null) {
      nameCtrl = TextEditingController(text: widget.medicine!.name);
      dosageCtrl = TextEditingController(text: widget.medicine!.dosage);
      notesCtrl = TextEditingController(text: widget.medicine!.notes);
      _frequencyCount = _parseFrequencyCount(widget.medicine!.frequency);
      _selectedTimes =
          _parseStoredTimes(widget.medicine!.time, _frequencyCount);
    } else if (widget.autoData != null) {
      nameCtrl = TextEditingController(text: widget.autoData?['name'] ?? '');
      dosageCtrl =
          TextEditingController(text: widget.autoData?['dosage'] ?? '');
      notesCtrl = TextEditingController(text: widget.autoData?['notes'] ?? '');
      _frequencyCount =
          _parseFrequencyCount(widget.autoData?['frequency'] ?? '');
      _selectedTimes = _parseStoredTimes(
          widget.autoData?['time'] ?? '', _frequencyCount);

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.auto_awesome, color: Colors.white),
                  SizedBox(width: 12),
                  Text("Data auto-filled from image"),
                ],
              ),
              backgroundColor: AppColors.primaryBlue,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      });
    } else {
      nameCtrl = TextEditingController();
      dosageCtrl = TextEditingController();
      notesCtrl = TextEditingController();
      _frequencyCount = 1;
      _selectedTimes = [null];
    }
  }

  int _parseFrequencyCount(String frequency) {
    if (frequency.isEmpty) return 1;
    final match = RegExp(r'(\d+)').firstMatch(frequency);
    if (match != null) {
      final count = int.tryParse(match.group(1)!) ?? 1;
      return count.clamp(1, 4);
    }
    return 1;
  }

  List<TimeOfDay?> _parseStoredTimes(String timeStr, int count) {
    if (timeStr.isEmpty) return List.filled(count, null);
    final parts = timeStr.split(',').map((t) => t.trim()).toList();
    final List<TimeOfDay?> times = [];
    for (int i = 0; i < count; i++) {
      if (i < parts.length && parts[i].contains(':')) {
        final timeParts = parts[i].split(':');
        final hour = int.tryParse(timeParts[0]) ?? 8;
        final minute = int.tryParse(timeParts[1]) ?? 0;
        times.add(TimeOfDay(hour: hour, minute: minute));
      } else {
        times.add(null);
      }
    }
    return times;
  }

  String _frequencyToString(int count) => '$count times/day';

  String _timesToString(List<TimeOfDay?> times) {
    return times.map((t) {
      if (t == null) return '';
      return '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    }).join(',');
  }

  void _onFrequencyChanged(int newCount) {
    setState(() {
      _frequencyCount = newCount;
      final newTimes = List<TimeOfDay?>.filled(newCount, null);
      for (int i = 0; i < newCount && i < _selectedTimes.length; i++) {
        newTimes[i] = _selectedTimes[i];
      }
      _selectedTimes = newTimes;
    });
  }

  Future<void> _pickTime(int index) async {
    final initialTime = _selectedTimes[index] ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    if (picked != null) {
      setState(() {
        _selectedTimes[index] = picked;
      });
    }
  }

  String _getTimeSlotLabel(int index, int total) {
    if (total == 1) return 'Time';
    final labels = ['Morning', 'Afternoon', 'Evening', 'Night'];
    if (index < labels.length) return labels[index];
    return 'Time ${index + 1}';
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $period';
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameCtrl.dispose();
    dosageCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveMedicine() async {
    if (_formKey.currentState!.validate()) {
      final missingTimes = _selectedTimes.where((t) => t == null).length;
      if (missingTimes > 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please select all medicine times"),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      try {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final medicine = Medicine(
          id: widget.medicine?.id,
          name: nameCtrl.text.trim(),
          dosage: dosageCtrl.text.trim(),
          frequency: _frequencyToString(_frequencyCount),
          time: _timesToString(_selectedTimes),
          notes: notesCtrl.text.trim(),
          userId: userId,
        );

        final vm = Provider.of<MedicineViewModel>(context, listen: false);
        if (widget.medicine == null) {
          await vm.addMedicine(medicine);
        } else {
          await vm.updateMedicine(medicine);
        }

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.medicine == null
                  ? "Medicine added successfully"
                  : "Medicine updated successfully"),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error saving medicine: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final hintColor = theme.hintColor;
    final bgColors = isDark
        ? [AppColors.darkBackground, AppColors.darkSurface]
        : [const Color(0xFFE8F0FE), const Color(0xFFF5F6FA)];

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: cardColor.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back,
                color: isDark ? Colors.white : AppColors.primaryBlue),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: bgColors,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isDark
                          ? [AppColors.darkPrimary, AppColors.darkSecondary]
                          : [AppColors.primaryBlue, AppColors.lightBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          widget.medicine == null
                              ? Icons.add_circle
                              : Icons.edit,
                          color: Colors.white,
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.medicine == null
                              ? "Add New Medicine"
                              : "Edit Medicine",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Form Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildInputField(
                          "Medicine Name",
                          nameCtrl,
                          Icons.local_pharmacy,
                          textColor: textColor,
                          cardColor: cardColor,
                          hintColor: hintColor,
                          isDark: isDark,
                        ),
                        _buildInputField(
                          "Dosage",
                          dosageCtrl,
                          Icons.fitness_center,
                          hint: "e.g., 500mg",
                          textColor: textColor,
                          cardColor: cardColor,
                          hintColor: hintColor,
                          isDark: isDark,
                        ),

                        // Frequency Dropdown
                        _buildFrequencyDropdown(
                            textColor, cardColor, isDark),

                        // Dynamic Time Pickers
                        _buildTimePickers(textColor, cardColor, isDark),

                        _buildInputField(
                          "Notes",
                          notesCtrl,
                          Icons.note,
                          maxLines: 3,
                          hint: "Optional notes about the medicine",
                          isRequired: false,
                          textColor: textColor,
                          cardColor: cardColor,
                          hintColor: hintColor,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 32),
                        // Action Buttons
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () => Navigator.pop(context),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  side: BorderSide(
                                    color: isDark
                                        ? AppColors.darkSecondary
                                        : AppColors.primaryBlue,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: isDark
                                        ? AppColors.darkTextPrimary
                                        : AppColors.primaryBlue,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: isDark
                                        ? [
                                            AppColors.darkPrimary,
                                            AppColors.darkSecondary
                                          ]
                                        : [
                                            AppColors.primaryBlue,
                                            AppColors.lightBlue
                                          ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isDark
                                              ? AppColors.darkSecondary
                                              : AppColors.primaryBlue)
                                          .withOpacity(0.3),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _saveMedicine,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: const Text(
                                    "Save Medicine",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFrequencyDropdown(
      Color textColor, Color cardColor, bool isDark) {
    final accentColor = isDark ? AppColors.darkSecondary : AppColors.primaryBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.repeat, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  "Frequency",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          DropdownButtonFormField<int>(
            value: _frequencyCount,
            dropdownColor: cardColor,
            style: TextStyle(color: textColor, fontSize: 15),
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: isDark
                        ? Colors.grey.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: isDark
                        ? Colors.grey.withOpacity(0.3)
                        : Colors.grey.withOpacity(0.2)),
              ),
              filled: true,
              fillColor: cardColor,
            ),
            items: _frequencyOptions.map((option) {
              return DropdownMenuItem<int>(
                value: option['value'] as int,
                child: Text(
                  option['label'] as String,
                  style: TextStyle(color: textColor, fontSize: 15),
                ),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) _onFrequencyChanged(value);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTimePickers(Color textColor, Color cardColor, bool isDark) {
    final accentColor = isDark ? AppColors.darkSecondary : AppColors.primaryBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(Icons.access_time, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  _frequencyCount == 1
                      ? "Medicine Time"
                      : "Medicine Times ($_frequencyCount times/day)",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          ...List.generate(_frequencyCount, (index) {
            final time = _selectedTimes[index];
            final label = _getTimeSlotLabel(index, _frequencyCount);

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: time != null
                      ? accentColor.withOpacity(0.3)
                      : Colors.grey.withOpacity(isDark ? 0.3 : 0.2),
                ),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: time != null
                        ? accentColor.withOpacity(0.1)
                        : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: time != null ? accentColor : Colors.grey,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                title: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  time != null
                      ? _formatTimeOfDay(time)
                      : 'Tap to select time',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight:
                        time != null ? FontWeight.w600 : FontWeight.normal,
                    color: time != null ? textColor : Colors.grey,
                  ),
                ),
                trailing: Icon(
                  time != null ? Icons.check_circle : Icons.access_time,
                  color: time != null ? accentColor : Colors.grey,
                ),
                onTap: () => _pickTime(index),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    String? hint,
    bool isRequired = true,
    required Color textColor,
    required Color cardColor,
    required Color hintColor,
    required bool isDark,
  }) {
    final accentColor = isDark ? AppColors.darkSecondary : AppColors.primaryBlue;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(icon, color: accentColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
                ),
              ],
            ),
          ),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            style: TextStyle(color: textColor),
            validator:
                isRequired ? (v) => v!.isEmpty ? "Required" : null : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: hintColor.withOpacity(0.6)),
              filled: true,
              fillColor: cardColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: Colors.grey.withOpacity(isDark ? 0.3 : 0.2)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                    color: Colors.grey.withOpacity(isDark ? 0.3 : 0.2)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: accentColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
