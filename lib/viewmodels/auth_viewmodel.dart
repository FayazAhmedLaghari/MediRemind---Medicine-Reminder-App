import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/patient_model.dart';
import '../service/auth_service.dart';
import '../service/firestore_service.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool isLoading = false;
  bool isPasswordVisible = false;
  bool isConfirmPasswordVisible = false;
  String? errorMessage;

  void togglePassword() {
    isPasswordVisible = !isPasswordVisible;
    notifyListeners();
  }

  void toggleConfirmPassword() {
    isConfirmPasswordVisible = !isConfirmPasswordVisible;
    notifyListeners();
  }

  // 🔐 LOGIN
  Future<bool> login(String email, String password) async {
    try {
      isLoading = true;
      notifyListeners();

      await _authService.login(email, password);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 📝 REGISTER + SAVE PATIENT
  Future<bool> registerPatient({
    required String name,
    required int age,
    required String gender,
    required String history,
    required String email,
    required String password,
  }) async {
    try {
      isLoading = true;
      notifyListeners();

      User? user = await _authService.register(email, password);

      if (user == null) return false;

      final patient = Patient(
        uid: user.uid,
        name: name,
        age: age,
        gender: gender,
        history: history,
        email: email,
      );

      await _firestoreService.savePatient(patient);

      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 🔑 SEND PASSWORD RESET EMAIL
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _authService.sendPasswordResetEmail(email);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 🔑 UPDATE PASSWORD (for logged-in users)
  Future<bool> updatePassword(String newPassword) async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _authService.updatePassword(newPassword);
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 🚪 LOGOUT
  Future<bool> logout() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      await _authService.logout();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
