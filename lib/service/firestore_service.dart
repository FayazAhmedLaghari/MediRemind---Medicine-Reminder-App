import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/patient_model.dart';
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<void> savePatient(Patient patient) async {
    await _db.collection('patients').doc(patient.uid).set(patient.toMap());
  }

  Future<Patient?> getPatient(String uid) async {
    final doc = await _db.collection('patients').doc(uid).get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    return Patient(
      uid: data['uid'],
      name: data['name'],
      age: data['age'],
      gender: data['gender'],
      history: data['history'],
      email: data['email'],
    );
  }
}
