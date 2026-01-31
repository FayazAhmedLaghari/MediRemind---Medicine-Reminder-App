import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/patient_model.dart';
import '../service/firestore_service.dart';

class DashboardViewModel extends ChangeNotifier {
  final FirestoreService _firestoreService = FirestoreService();

  Patient? patient;
  bool isLoading = true;

  Future<void> loadPatient() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    patient = await _firestoreService.getPatient(uid);
    isLoading = false;
    notifyListeners();
  }
}
