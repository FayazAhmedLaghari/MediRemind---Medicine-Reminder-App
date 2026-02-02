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
  late TextEditingController frequencyCtrl;
  late TextEditingController timeCtrl;
  late TextEditingController notesCtrl;

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

    // 🔥 AUTO-FILL FROM OCR
    // Initialize with medicine data if editing, otherwise use autoData if available
    if (widget.medicine != null) {
      nameCtrl = TextEditingController(text: widget.medicine!.name);
      dosageCtrl = TextEditingController(text: widget.medicine!.dosage);
      frequencyCtrl = TextEditingController(text: widget.medicine!.frequency);
      timeCtrl = TextEditingController(text: widget.medicine!.time);
      notesCtrl = TextEditingController(text: widget.medicine!.notes);
    } else if (widget.autoData != null) {
      // 🎯 Use auto-filled data from OCR/ML Kit
      nameCtrl = TextEditingController(text: widget.autoData?['name'] ?? '');
      dosageCtrl =
          TextEditingController(text: widget.autoData?['dosage'] ?? '');
      frequencyCtrl =
          TextEditingController(text: widget.autoData?['frequency'] ?? '');
      timeCtrl = TextEditingController(text: widget.autoData?['time'] ?? '');
      notesCtrl = TextEditingController(text: widget.autoData?['notes'] ?? '');

      // Show snackbar notifying user of auto-fill
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
      // Empty form for new medicine
      nameCtrl = TextEditingController();
      dosageCtrl = TextEditingController();
      frequencyCtrl = TextEditingController();
      timeCtrl = TextEditingController();
      notesCtrl = TextEditingController();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    nameCtrl.dispose();
    dosageCtrl.dispose();
    frequencyCtrl.dispose();
    timeCtrl.dispose();
    notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveMedicine() async {
    if (_formKey.currentState!.validate()) {
      try {
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
        final medicine = Medicine(
          id: widget.medicine?.id,
          name: nameCtrl.text.trim(),
          dosage: dosageCtrl.text.trim(),
          frequency: frequencyCtrl.text.trim(),
          time: timeCtrl.text.trim(),
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.9),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.primaryBlue),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFFE8F0FE),
                Color(0xFFF5F6FA),
              ],
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header Section
                Container(
                  height: 180,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppColors.primaryBlue, AppColors.lightBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.only(
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
                        ),
                        _buildInputField(
                          "Dosage",
                          dosageCtrl,
                          Icons.fitness_center,
                          hint: "e.g., 500mg",
                        ),
                        _buildInputField(
                          "Frequency",
                          frequencyCtrl,
                          Icons.repeat,
                          hint: "e.g., 2 times/day",
                        ),
                        _buildInputField(
                          "Time",
                          timeCtrl,
                          Icons.access_time,
                          hint: "e.g., Morning/Night",
                        ),
                        _buildInputField(
                          "Notes",
                          notesCtrl,
                          Icons.note,
                          maxLines: 3,
                          hint: "Optional notes about the medicine",
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
                                  side: const BorderSide(
                                    color: AppColors.primaryBlue,
                                    width: 2,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
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
                                  gradient: const LinearGradient(
                                    colors: [
                                      AppColors.primaryBlue,
                                      AppColors.lightBlue
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.primaryBlue
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

  Widget _buildInputField(
    String label,
    TextEditingController controller,
    IconData icon, {
    int maxLines = 1,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(icon, color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            validator: (v) => v!.isEmpty ? "Required" : null,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.grey.withOpacity(0.6),
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: Colors.grey.withOpacity(0.2),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primaryBlue,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: Colors.red,
                  width: 2,
                ),
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
