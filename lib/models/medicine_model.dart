class Medicine {
  final int? id;
  final String name;
  final String dosage;
  final String frequency;
  final String time;
  final String notes;
  final String userId; // Firebase UID

  Medicine({
    this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.time,
    required this.notes,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'time': time,
      'notes': notes,
      'userId': userId,
    };
  }

  factory Medicine.fromMap(Map<String, dynamic> map) {
    return Medicine(
      id: map['id'] as int?,
      name: map['name'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      frequency: map['frequency'] as String? ?? '',
      time: map['time'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
    );
  }
}
