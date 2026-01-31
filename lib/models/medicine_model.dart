class Medicine {
  final int? id;
  final String name;
  final String dosage;
  final String frequency;
  final String time;
  final String notes;

  Medicine({
    this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    required this.time,
    required this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'time': time,
      'notes': notes,
    };
  }
}
