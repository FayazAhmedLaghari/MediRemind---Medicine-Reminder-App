class Patient {
  final String uid;
  final String name;
  final int age;
  final String gender;
  final String history;
  final String email;

  Patient({
    required this.uid,
    required this.name,
    required this.age,
    required this.gender,
    required this.history,
    required this.email,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'age': age,
      'gender': gender,
      'history': history,
      'email': email,
      'createdAt': DateTime.now(),
    };
  }
}
