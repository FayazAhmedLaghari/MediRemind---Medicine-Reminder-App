import 'dart:io';
import 'package:flutter/material.dart';
import '../service/ocr_service.dart';
class OCRViewModel extends ChangeNotifier {
  final OCRService _ocrService = OCRService();

  String extractedText = '';
  String? errorMessage;
  bool isLoading = false;

  /// Whether the current platform supports ML Kit OCR (Android/iOS only)
  bool get isOCRSupported => OCRService.isSupported;

  /// Clear extracted text and reset state
  void clear() {
    extractedText = '';
    errorMessage = null;
    isLoading = false;
    notifyListeners();
  }

  Future<void> scanPrescription(File image) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      extractedText = await _ocrService.extractText(image);
      debugPrint('📝 [OCR] Extracted text:\n$extractedText');
    } on UnsupportedError catch (e) {
      debugPrint('📝 [OCR] Unsupported: $e');
      errorMessage = e.message;
      extractedText = '';
    } catch (e) {
      debugPrint('📝 [OCR] Error: $e');
      errorMessage = 'Failed to scan prescription: $e';
      extractedText = '';
    }

    isLoading = false;
    notifyListeners();
  }

  /// Intelligently parse medicine info from extracted OCR text
  Map<String, String> autoFillMedicine() {
    if (extractedText.isEmpty) {
      return {'name': '', 'dosage': '', 'frequency': '', 'time': '', 'notes': ''};
    }

    final text = extractedText;
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final name = _extractMedicineName(text, lines);
    final dosage = _extractDosage(text);
    final frequency = _extractFrequency(text);
    final time = _extractTime(text);
    final notes = _extractNotes(text, lines, name, dosage, frequency);

    debugPrint('📝 [OCR] Parsed -> name: $name, dosage: $dosage, frequency: $frequency, time: $time, notes: $notes');

    return {
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'time': time,
      'notes': notes,
    };
  }

  /// Extract medicine name from the text
  /// Strategy: Look for common medicine name patterns, or use the most
  /// prominent line that looks like a medicine name
  String _extractMedicineName(String text, List<String> lines) {
    // Common medicine name patterns (brand names often start with uppercase)
    // Try to find a line that contains a medicine-like word

    // 1. Look for line after keywords like "Medicine:", "Drug:", "Rx:", "Tab.", "Cap.", "Syp."
    final prefixPatterns = [
      RegExp(r'(?:Tab\.?|Tablet)\s+(.+)', caseSensitive: false),
      RegExp(r'(?:Cap\.?|Capsule)\s+(.+)', caseSensitive: false),
      RegExp(r'(?:Syp\.?|Syrup)\s+(.+)', caseSensitive: false),
      RegExp(r'(?:Inj\.?|Injection)\s+(.+)', caseSensitive: false),
      RegExp(r'(?:Susp\.?|Suspension)\s+(.+)', caseSensitive: false),
      RegExp(r'(?:Drops?)\s+(.+)', caseSensitive: false),
      RegExp(r'(?:Oint\.?|Ointment)\s+(.+)', caseSensitive: false),
      RegExp(r'(?:Cream)\s+(.+)', caseSensitive: false),
      RegExp(r'Rx[:\s]+(.+)', caseSensitive: false),
      RegExp(r'Medicine[:\s]+(.+)', caseSensitive: false),
      RegExp(r'Drug[:\s]+(.+)', caseSensitive: false),
      RegExp(r'Name[:\s]+(.+)', caseSensitive: false),
    ];

    for (final pattern in prefixPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        String name = match.group(1)!.trim();
        // Remove dosage info from the end if present
        name = name.replaceAll(RegExp(r'\s*\d+\s*(?:mg|ml|g|mcg|iu)\b.*', caseSensitive: false), '').trim();
        if (name.isNotEmpty && name.length >= 2) {
          return _capitalizeFirstLetter(name);
        }
      }
    }

    // 2. Look for common medicine names in the text
    final commonMedicines = [
      'Panadol', 'Paracetamol', 'Acetaminophen', 'Ibuprofen', 'Aspirin',
      'Amoxicillin', 'Azithromycin', 'Ciprofloxacin', 'Metformin',
      'Omeprazole', 'Pantoprazole', 'Atorvastatin', 'Amlodipine',
      'Losartan', 'Lisinopril', 'Metoprolol', 'Cetirizine', 'Loratadine',
      'Diclofenac', 'Naproxen', 'Prednisone', 'Dexamethasone',
      'Levothyroxine', 'Insulin', 'Warfarin', 'Clopidogrel',
      'Ranitidine', 'Famotidine', 'Montelukast', 'Salbutamol',
      'Fluoxetine', 'Sertraline', 'Escitalopram', 'Alprazolam',
      'Diazepam', 'Tramadol', 'Codeine', 'Morphine',
      'Ceftriaxone', 'Doxycycline', 'Clindamycin', 'Fluconazole',
      'Acyclovir', 'Tamiflu', 'Oseltamivir', 'Hydroxychloroquine',
      'Vitamin', 'Calcium', 'Iron', 'Folic Acid', 'Zinc',
      'Augmentin', 'Flagyl', 'Metronidazole', 'Brufen',
      'Voltaren', 'Nexium', 'Lipitor', 'Norvasc', 'Cozaar',
      'Glucophage', 'Ventolin', 'Zocor', 'Simvastatin',
      'Cephalexin', 'Erythromycin', 'Levofloxacin',
      'Digoxin', 'Furosemide', 'Hydrochlorothiazide',
      'Risperidone', 'Quetiapine', 'Olanzapine',
      'Gabapentin', 'Pregabalin', 'Carbamazepine',
      'Phenytoin', 'Valproic', 'Levetiracetam',
    ];

    final lowerText = text.toLowerCase();
    for (final med in commonMedicines) {
      if (lowerText.contains(med.toLowerCase())) {
        return med;
      }
    }

    // 3. Try to find a word that looks like a medicine name
    //    (capitalized word that's not a common non-medicine word)
    final skipWords = {
      'patient', 'doctor', 'dr', 'mr', 'mrs', 'ms', 'name', 'age',
      'date', 'hospital', 'clinic', 'pharmacy', 'prescription',
      'diagnosis', 'address', 'phone', 'mobile', 'email',
      'the', 'for', 'and', 'with', 'from', 'take', 'daily',
      'morning', 'evening', 'night', 'after', 'before', 'meal',
      'food', 'water', 'times', 'day', 'days', 'week', 'month',
      'tablet', 'capsule', 'syrup', 'injection', 'dose', 'dosage',
      'notes', 'note', 'instructions', 'remarks',
      'once', 'twice', 'thrice', 'every', 'hours',
    };

    // Look for capitalized words that could be medicine names
    for (final line in lines) {
      // Skip very short or very long lines
      if (line.length < 3 || line.length > 60) continue;

      // Skip lines that are clearly metadata
      if (RegExp(r'^\d{1,2}[/\-]\d{1,2}[/\-]\d{2,4}$').hasMatch(line)) continue;
      if (RegExp(r'^(Dr\.?|Patient|Name|Date|Age|Hospital|Clinic)', caseSensitive: false).hasMatch(line)) continue;

      // Check if this line starts with a capitalized word that's not in skip list
      final words = line.split(RegExp(r'\s+'));
      if (words.isNotEmpty) {
        final firstWord = words[0].replaceAll(RegExp(r'[^a-zA-Z]'), '');
        if (firstWord.isNotEmpty &&
            firstWord[0] == firstWord[0].toUpperCase() &&
            !skipWords.contains(firstWord.toLowerCase()) &&
            firstWord.length >= 3) {
          // This could be a medicine name - take the line but clean it
          String candidate = line;
          // Remove dosage and frequency parts
          candidate = candidate.replaceAll(
              RegExp(r'\s*\d+\s*(?:mg|ml|g|mcg|iu)\b.*', caseSensitive: false), '').trim();
          candidate = candidate.replaceAll(
              RegExp(r'\s*(?:once|twice|thrice|\d+\s*(?:times?|x))\s*(?:a\s*)?(?:day|daily).*',
                  caseSensitive: false), '').trim();
          if (candidate.isNotEmpty && candidate.length >= 3) {
            return _capitalizeFirstLetter(candidate);
          }
        }
      }
    }

    // 4. Fallback: use the first non-trivial line as medicine name
    for (final line in lines) {
      if (line.length >= 3 && line.length <= 50) {
        final cleaned = line.replaceAll(
            RegExp(r'\s*\d+\s*(?:mg|ml|g|mcg|iu)\b.*', caseSensitive: false), '').trim();
        if (cleaned.isNotEmpty && cleaned.length >= 3) {
          return _capitalizeFirstLetter(cleaned);
        }
      }
    }

    // Last resort: return first line trimmed
    return lines.isNotEmpty ? lines[0].substring(0, lines[0].length.clamp(0, 40)) : '';
  }

  /// Extract dosage from text (e.g., "500mg", "250 mg", "10ml", "5 mg/ml")
  String _extractDosage(String text) {
    // Match patterns like: 500mg, 250 mg, 10ml, 500 MG, 5mg/ml, etc.
    final dosagePatterns = [
      // "Dosage: 500mg" or "Dose: 500mg"
      RegExp(r'(?:dosage|dose)[:\s]*(\d+[\.\d]*\s*(?:mg|ml|g|mcg|iu|units?)(?:\s*/\s*(?:ml|kg|dose))?)',
          caseSensitive: false),
      // Common dosage with units: "500mg", "250 mg", "10 ml"
      RegExp(r'(\d+[\.\d]*\s*(?:mg|ml|g|mcg|iu|units?)(?:\s*/\s*(?:ml|kg|dose))?)',
          caseSensitive: false),
    ];

    for (final pattern in dosagePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)!.trim();
      }
    }

    return '';
  }

  /// Extract frequency from text
  String _extractFrequency(String text) {
    final lowerText = text.toLowerCase();

    // Check for medical abbreviations first
    // BD / BID = twice daily, TDS/TID = three times daily, QID = four times daily, OD = once daily
    final abbrevPatterns = [
      (RegExp(r'\b(?:qid|q\.i\.d\.?)\b', caseSensitive: false), '4 times/day'),
      (RegExp(r'\b(?:tds|tid|t\.d\.s\.?|t\.i\.d\.?)\b', caseSensitive: false), '3 times/day'),
      (RegExp(r'\b(?:bd|bid|b\.d\.?|b\.i\.d\.?)\b', caseSensitive: false), '2 times/day'),
      (RegExp(r'\b(?:od|o\.d\.?|qd|q\.d\.?)\b', caseSensitive: false), '1 time/day'),
      (RegExp(r'\b(?:prn|p\.r\.n\.?|as\s*needed|when\s*needed)\b', caseSensitive: false), '1 time/day'),
      (RegExp(r'\b(?:hs|h\.s\.?|at\s*bedtime|before\s*sleep)\b', caseSensitive: false), '1 time/day'),
    ];

    for (final (pattern, freq) in abbrevPatterns) {
      if (pattern.hasMatch(text)) {
        return freq;
      }
    }

    // Check for written-out frequency
    final freqPatterns = [
      (RegExp(r'(?:4|four)\s*(?:times?\s*(?:a\s*|per\s*)?(?:day|daily))', caseSensitive: false), '4 times/day'),
      (RegExp(r'(?:3|three|thrice)\s*(?:times?\s*(?:a\s*|per\s*)?(?:day|daily))?', caseSensitive: false), '3 times/day'),
      (RegExp(r'(?:2|two|twice)\s*(?:times?\s*(?:a\s*|per\s*)?(?:day|daily))?', caseSensitive: false), '2 times/day'),
      (RegExp(r'(?:1|one|once)\s*(?:times?\s*(?:a\s*|per\s*)?(?:day|daily))?', caseSensitive: false), '1 time/day'),
      (RegExp(r'every\s*(?:6|six)\s*hours?', caseSensitive: false), '4 times/day'),
      (RegExp(r'every\s*(?:8|eight)\s*hours?', caseSensitive: false), '3 times/day'),
      (RegExp(r'every\s*(?:12|twelve)\s*hours?', caseSensitive: false), '2 times/day'),
      (RegExp(r'every\s*(?:24|twenty.?four)\s*hours?', caseSensitive: false), '1 time/day'),
    ];

    for (final (pattern, freq) in freqPatterns) {
      if (pattern.hasMatch(text)) {
        return freq;
      }
    }

    // Check for simple digit followed by "x" or "times"
    final simpleMatch = RegExp(r'(\d)\s*(?:x|times)\s*(?:per\s*)?(?:day|daily)?', caseSensitive: false).firstMatch(text);
    if (simpleMatch != null) {
      final count = int.tryParse(simpleMatch.group(1)!) ?? 1;
      if (count >= 1 && count <= 4) {
        return '$count times/day';
      }
    }

    // Check for "daily" alone
    if (lowerText.contains('daily') || lowerText.contains('once')) {
      return '1 time/day';
    }

    return '';
  }

  /// Extract time information from text
  String _extractTime(String text) {
    final lowerText = text.toLowerCase();
    final times = <String>[];

    // Check for specific time patterns like "8:00 AM", "08:00", "8 AM"
    final timeRegex = RegExp(r'(\d{1,2})[:\.](\d{2})\s*(?:am|pm|AM|PM)?');
    final timeMatches = timeRegex.allMatches(text);
    for (final match in timeMatches) {
      final hour = int.tryParse(match.group(1)!) ?? 0;
      final minute = int.tryParse(match.group(2)!) ?? 0;
      if (hour >= 0 && hour <= 23 && minute >= 0 && minute <= 59) {
        times.add('${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}');
      }
    }

    if (times.isNotEmpty) {
      return times.join(',');
    }

    // Check for time-of-day words
    final hasMorning = lowerText.contains('morning') || lowerText.contains('breakfast') || lowerText.contains('am');
    final hasAfternoon = lowerText.contains('afternoon') || lowerText.contains('lunch') || lowerText.contains('noon');
    final hasEvening = lowerText.contains('evening') || lowerText.contains('dinner') || lowerText.contains('supper');
    final hasNight = lowerText.contains('night') || lowerText.contains('bedtime') || lowerText.contains('sleep');

    final timeSlots = <String>[];
    if (hasMorning) timeSlots.add('08:00');
    if (hasAfternoon) timeSlots.add('14:00');
    if (hasEvening) timeSlots.add('18:00');
    if (hasNight) timeSlots.add('22:00');

    if (timeSlots.isNotEmpty) {
      return timeSlots.join(',');
    }

    return '';
  }

  /// Extract any additional notes from the remaining text
  String _extractNotes(String text, List<String> lines, String name, String dosage, String frequency) {
    final lowerText = text.toLowerCase();
    final notesParts = <String>[];

    // Check for meal instructions
    if (lowerText.contains('before meal') || lowerText.contains('before food') || lowerText.contains('empty stomach')) {
      notesParts.add('Take before meals');
    } else if (lowerText.contains('after meal') || lowerText.contains('after food') || lowerText.contains('with food')) {
      notesParts.add('Take after meals');
    } else if (lowerText.contains('with meal') || lowerText.contains('during meal')) {
      notesParts.add('Take with meals');
    }

    // Check for duration
    final durationMatch = RegExp(r'(?:for\s+)?(\d+)\s*(?:days?|weeks?|months?)', caseSensitive: false).firstMatch(text);
    if (durationMatch != null) {
      notesParts.add('Duration: ${durationMatch.group(0)!.trim()}');
    }

    // Check for special instructions
    if (lowerText.contains('avoid') || lowerText.contains('do not')) {
      final avoidMatch = RegExp(r'(?:avoid|do\s*not)[:\s]*(.+?)(?:\.|$)', caseSensitive: false).firstMatch(text);
      if (avoidMatch != null) {
        notesParts.add('Avoid: ${avoidMatch.group(1)!.trim()}');
      }
    }

    // Check for explicit notes section
    final notesMatch = RegExp(r'(?:notes?|remarks?|instructions?)[:\s]+(.+)', caseSensitive: false).firstMatch(text);
    if (notesMatch != null) {
      notesParts.add(notesMatch.group(1)!.trim());
    }

    return notesParts.join('. ');
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
