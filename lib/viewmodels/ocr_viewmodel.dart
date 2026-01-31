import 'dart:io';
import 'package:flutter/material.dart';

import '../service/ocr_service.dart';

class OCRViewModel extends ChangeNotifier {
  final OCRService _ocrService = OCRService();

  String extractedText = '';
  bool isLoading = false;

  Future<void> scanPrescription(File image) async {
    isLoading = true;
    notifyListeners();

    extractedText = await _ocrService.extractText(image);

    isLoading = false;
    notifyListeners();
  }

  /// Simple medicine parsing (can be improved)
  Map<String, String> autoFillMedicine() {
    return {
      'name': extractedText.contains('Panadol') ? 'Panadol' : '',
      'dosage': extractedText.contains('500') ? '500mg' : '',
      'frequency': extractedText.contains('2') ? '2 times/day' : '',
    };
  }
}
