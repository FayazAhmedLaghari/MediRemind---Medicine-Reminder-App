import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/ocr_viewmodel.dart';
import '../../viewmodels/medicine_viewmodel.dart';
import '../../models/medicine_model.dart';
import '../../core/app_colors.dart';
import '../medicine/add_edit_medicine_view.dart';
class ScanPrescriptionView extends StatefulWidget {
  ScanPrescriptionView({super.key});

  @override
  State<ScanPrescriptionView> createState() => _ScanPrescriptionViewState();
}

class _ScanPrescriptionViewState extends State<ScanPrescriptionView> {
  final ImagePicker _picker = ImagePicker();
  String? _pickedImagePath;
  
  Future<void> _pickFromCamera(BuildContext context) async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (image != null && context.mounted) {
        setState(() {
          _pickedImagePath = image.path;
        });
        final vm = Provider.of<OCRViewModel>(context, listen: false);
        await vm.scanPrescription(File(image.path));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: Check camera permissions. $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery(BuildContext context) async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
        maxWidth: 2000,
        maxHeight: 2000,
      );
      if (image != null && context.mounted) {
        setState(() {
          _pickedImagePath = image.path;
        });
        final vm = Provider.of<OCRViewModel>(context, listen: false);
        await vm.scanPrescription(File(image.path));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gallery error: Check storage permissions. $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<OCRViewModel>();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardColor = theme.cardColor;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: isDark ? AppColors.darkPrimary : AppColors.primaryBlue,
        title: const Text(
          'Scan Prescription',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [AppColors.darkBackground, AppColors.darkSurface]
                : [const Color(0xFFE8F0FE), const Color(0xFFF5F6FA)],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Platform warning banner
                if (!vm.isOCRSupported)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.amber.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.amber, size: 24),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'OCR scanning is only supported on Android & iOS devices. '
                            'Please run this app on a phone or emulator.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.amber[200]
                                  : Colors.amber[900],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Instructions Card
                if (vm.extractedText.isEmpty && !vm.isLoading)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? AppColors.darkSecondary.withOpacity(0.3)
                            : AppColors.primaryBlue.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.document_scanner_outlined,
                          size: 48,
                          color: isDark
                              ? AppColors.darkSecondary
                              : AppColors.primaryBlue,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Scan your prescription',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Take a clear photo of your handwritten or printed prescription. '
                          'Make sure the text is readable and well-lit.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        // Tips
                        _buildTip(Icons.wb_sunny_outlined, 'Good lighting helps accuracy', isDark),
                        _buildTip(Icons.crop_free, 'Keep the text in frame', isDark),
                        _buildTip(Icons.text_fields, 'Works with handwriting & printed text', isDark),
                      ],
                    ),
                  ),

                // Camera Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: (isDark
                                ? AppColors.darkSecondary
                                : AppColors.primaryBlue)
                            .withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.camera_alt, size: 28),
                    label: const Text(
                      'Scan from Camera',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    onPressed: vm.isLoading ? null : () async {
                      await _pickFromCamera(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isDark ? AppColors.darkSecondary : AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Gallery Button
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.lightBlue.withOpacity(0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.photo, size: 28),
                    label: const Text(
                      'Pick from Gallery',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    onPressed: vm.isLoading ? null : () async {
                      await _pickFromGallery(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.lightBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Image Preview
                if (_pickedImagePath != null && !kIsWeb)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey.withOpacity(0.3)
                            : Colors.grey.withOpacity(0.2),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.file(
                        File(_pickedImagePath!),
                        height: 200,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),

                // Loading Indicator
                if (vm.isLoading)
                  Container(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        CircularProgressIndicator(
                          color: isDark
                              ? AppColors.darkSecondary
                              : AppColors.primaryBlue,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Scanning prescription...',
                          style: TextStyle(
                            fontSize: 14,
                            color: isDark
                                ? AppColors.darkSecondary
                                : AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Analyzing handwriting and extracting medicine information',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                // Error State (unsupported platform / plugin error)
                if (!vm.isLoading && vm.errorMessage != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.red.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.error_outline,
                            size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(
                          'OCR Not Available',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          vm.errorMessage!,
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Prescription scanning requires an Android or iOS device.\n'
                          'If you are on Android/iOS, try: flutter clean → flutter pub get → flutter run',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                // No Text Found State
                if (!vm.isLoading && vm.errorMessage == null && vm.extractedText.isEmpty && _pickedImagePath != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.text_snippet_outlined,
                            size: 48, color: Colors.orange),
                        const SizedBox(height: 12),
                        Text(
                          'No text detected',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try taking a clearer photo with better lighting, '
                          'or make sure the prescription text is visible.',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark
                                ? AppColors.darkTextSecondary
                                : Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                // Extracted Text Display
                if (vm.extractedText.isNotEmpty && !vm.isLoading)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Raw extracted text
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? Colors.grey.withOpacity(0.3)
                                : Colors.grey.withOpacity(0.2),
                            width: 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (isDark
                                      ? Colors.black
                                      : AppColors.primaryBlue)
                                  .withOpacity(0.08),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.green[600],
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Extracted Text',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isDark
                                        ? AppColors.darkSecondary
                                        : AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              vm.extractedText,
                              style: TextStyle(
                                fontSize: 13,
                                color: textColor,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Parsed medicine info preview
                      _buildParsedPreview(vm, isDark, cardColor, textColor),

                      const SizedBox(height: 20),

                      // Action Buttons
                      Row(
                        children: [
                          // Quick Save Button
                          Expanded(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Colors.green, Color(0xFF66BB6A)],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.save),
                                label: const Text(
                                  'Quick Save',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: () async {
                                  try {
                                    final data = vm.autoFillMedicine();
                                    final hasValidData = data.values
                                        .any((value) => value.isNotEmpty);

                                    if (hasValidData) {
                                      final userId = FirebaseAuth
                                              .instance.currentUser?.uid ??
                                          '';
                                      final medicine = Medicine(
                                        name: data['name'] ?? '',
                                        dosage: data['dosage'] ?? '',
                                        frequency: data['frequency'] ?? '',
                                        time: data['time'] ?? '',
                                        notes: data['notes'] ?? '',
                                        userId: userId,
                                      );

                                      final medicineVM =
                                          Provider.of<MedicineViewModel>(
                                              context,
                                              listen: false);
                                      await medicineVM.addMedicine(medicine);

                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                '✅ Medicine saved successfully'),
                                            backgroundColor: Colors.green,
                                            duration: Duration(seconds: 2),
                                          ),
                                        );

                                        Future.delayed(
                                            const Duration(seconds: 2), () {
                                          if (context.mounted) {
                                            Navigator.pop(context);
                                          }
                                        });
                                      }
                                    } else if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Could not extract medicine information. Try "Edit & Save" to enter manually.'),
                                          backgroundColor: Colors.orange,
                                          duration: Duration(seconds: 4),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Edit & Save Button
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
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.edit),
                                label: const Text(
                                  'Edit & Save',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                onPressed: () {
                                  try {
                                    final data = vm.autoFillMedicine();

                                    if (context.mounted) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => AddEditMedicineView(
                                            medicine: null,
                                            autoData: data,
                                          ),
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text('Error: $e'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 14),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Rescan button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          icon: const Icon(Icons.refresh),
                          label: const Text('Scan Again'),
                          onPressed: () {
                            setState(() {
                              _pickedImagePath = null;
                            });
                            vm.clear();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.darkSecondary
                                  : AppColors.primaryBlue,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Build a preview of the parsed medicine data
  Widget _buildParsedPreview(
      OCRViewModel vm, bool isDark, Color cardColor, Color textColor) {
    final data = vm.autoFillMedicine();
    final accentColor = isDark ? AppColors.darkSecondary : AppColors.primaryBlue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(isDark ? 0.15 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: accentColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, size: 20, color: accentColor),
              const SizedBox(width: 8),
              Text(
                'Detected Medicine Info',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: accentColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildParsedRow('Name', data['name'] ?? '', textColor, isDark),
          _buildParsedRow('Dosage', data['dosage'] ?? '', textColor, isDark),
          _buildParsedRow('Frequency', data['frequency'] ?? '', textColor, isDark),
          _buildParsedRow('Time', data['time'] ?? '', textColor, isDark),
          if ((data['notes'] ?? '').isNotEmpty)
            _buildParsedRow('Notes', data['notes']!, textColor, isDark),
          const SizedBox(height: 8),
          Text(
            'Tap "Edit & Save" to review and correct before saving',
            style: TextStyle(
              fontSize: 11,
              fontStyle: FontStyle.italic,
              color: isDark ? AppColors.darkTextSecondary : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParsedRow(
      String label, String value, Color textColor, bool isDark) {
    final hasValue = value.isNotEmpty;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor.withOpacity(0.7),
              ),
            ),
          ),
          Expanded(
            child: Text(
              hasValue ? value : '(not detected)',
              style: TextStyle(
                fontSize: 13,
                color: hasValue
                    ? textColor
                    : (isDark
                        ? AppColors.darkTextSecondary.withOpacity(0.5)
                        : Colors.grey),
                fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ),
          Icon(
            hasValue ? Icons.check_circle : Icons.help_outline,
            size: 16,
            color: hasValue ? Colors.green : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildTip(IconData icon, String text, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon,
              size: 16,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : Colors.grey[500]),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? AppColors.darkTextSecondary
                  : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}
