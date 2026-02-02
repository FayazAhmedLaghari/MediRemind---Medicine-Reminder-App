class Patient {
  final String uid;
  final String name;
  final int age;
  final String gender;
  final String history;
  final String email;
  final String notes; // Personal notes / doctor instructions
  final String doctorInstructions;

  Patient({
    required this.uid,
    required this.name,
    required this.age,
    required this.gender,
    required this.history,
    required this.email,
    this.notes = '',
    this.doctorInstructions = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'age': age,
      'gender': gender,
      'history': history,
      'email': email,
      'notes': notes,
      'doctorInstructions': doctorInstructions,
      'createdAt': DateTime.now(),
    };
  }
}
