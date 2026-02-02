import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/medicine_model.dart';
import '../service/database_helper.dart';

class MedicineViewModel extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;

  List<Medicine> medicines = [];
  List<Map<String, dynamic>> interactions = [];
  List<Medicine> refillReminders = [];

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> loadMedicines() async {
    if (_userId == null) return;
    medicines = await _db.getMedicines(_userId!);
    checkMedicineInteractions();
    checkRefillReminders();
    notifyListeners();
  }

  Future<void> addMedicine(Medicine medicine) async {
    await _db.insertMedicine(medicine);
    await loadMedicines();
  }

  Future<void> updateMedicine(Medicine medicine) async {
    await _db.updateMedicine(medicine);
    await loadMedicines();
  }

  Future<void> deleteMedicine(int id) async {
    await _db.deleteMedicine(id);
    await loadMedicines();
  }

  // Check for potential medicine interactions
  void checkMedicineInteractions() {
    interactions.clear();

    // Example interaction checking - in a real app this would come from a medical database
    for (int i = 0; i < medicines.length; i++) {
      for (int j = i + 1; j < medicines.length; j++) {
        if (_checkInteraction(
            medicines[i].name.toLowerCase(), medicines[j].name.toLowerCase())) {
          interactions.add({
            'medicine1': medicines[i].name,
            'medicine2': medicines[j].name,
            'interaction':
                'Potential interaction between \${medicines[i].name} and \${medicines[j].name}',
            'severity': 'moderate'
          });
        }
      }
    }
  }

  bool _checkInteraction(String med1, String med2) {
    // This is a simplified interaction checker
    // In a real app, this would connect to a medical interaction database
    List<List<String>> knownInteractions = [
      ['warfarin', 'aspirin'],
      ['ibuprofen', 'naproxen'],
      ['simvastatin', 'gemfibrozil'],
      ['digoxin', 'furosemide'],
      ['lisinopril', 'spironolactone'],
      ['metformin', 'contrast dye'],
    ];

    for (var interaction in knownInteractions) {
      if ((interaction[0] == med1 && interaction[1] == med2) ||
          (interaction[0] == med2 && interaction[1] == med1)) {
        return true;
      }
    }
    return false;
  }

  // Check for refill reminders
  void checkRefillReminders() {
    refillReminders.clear();
    // In a real app, this would check against dosage, frequency and last refill date
    // For now, we'll just add all medicines as potential refill reminders
    refillReminders = List.from(medicines);
  }

  List<Map<String, dynamic>> getInteractions() {
    return interactions;
  }

  List<Medicine> getRefillReminders() {
    return refillReminders;
  }
}
