import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/patient_model.dart';
import '../models/reminder_model.dart';
import '../service/firestore_service.dart';
import '../service/database_helper.dart';

class DashboardViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  Patient? patient;
  bool isLoading = true;
  List<Reminder> todaysReminders = [];
  final DatabaseHelper _db = DatabaseHelper.instance;

  Future<void> loadPatient() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    isLoading = true;
    notifyListeners();

    patient = await _firestoreService.getPatient(uid);

    // Load today's reminders
    final today = DateTime.now();
    final todayStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    todaysReminders = await _db.getRemindersByDate(todayStr, uid);

    isLoading = false;
    notifyListeners();
  }

  Future<bool> saveNotes({String? notes, String? doctorInstructions}) async {
    try {
      if (patient == null) return false;
      final updated = Patient(
        uid: patient!.uid,
        name: patient!.name,
        age: patient!.age,
        gender: patient!.gender,
        history: patient!.history,
        email: patient!.email,
        notes: notes ?? patient!.notes,
        doctorInstructions: doctorInstructions ?? patient!.doctorInstructions,
      );
      await _firestoreService.savePatient(updated);
      patient = updated;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }
}
