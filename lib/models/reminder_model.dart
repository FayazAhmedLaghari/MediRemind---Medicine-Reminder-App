class Reminder {
  final int? id;
  final String medicineId; // ID of the medicine
  final String medicineName;
  final String reminderDate; // Format: yyyy-MM-dd
  final String reminderTime; // Format: HH:mm
  final String dosage;
  final String status; // pending, completed, missed
  final String notes;
  final DateTime createdAt;
  final String userId; // Firebase UID
  Reminder({
    this.id,
    required this.medicineId,
    required this.medicineName,
    required this.reminderDate,
    required this.reminderTime,
    required this.dosage,
    this.status = 'pending',
    this.notes = '',
    required this.createdAt,
    required this.userId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'medicineId': medicineId,
      'medicineName': medicineName,
      'reminderDate': reminderDate,
      'reminderTime': reminderTime,
      'dosage': dosage,
      'status': status,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'userId': userId,
    };
  }

  factory Reminder.fromMap(Map<String, dynamic> map) {
    String createdAtStr = (map['createdAt'] as String?) ?? '';
    DateTime created;
    try {
      created = createdAtStr.isNotEmpty
          ? DateTime.parse(createdAtStr)
          : DateTime.now();
    } catch (_) {
      created = DateTime.now();
    }

    return Reminder(
      id: map['id'] as int?,
      medicineId: map['medicineId'] as String? ?? '',
      medicineName: map['medicineName'] as String? ?? '',
      reminderDate: map['reminderDate'] as String? ?? '',
      reminderTime: map['reminderTime'] as String? ?? '',
      dosage: map['dosage'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      notes: map['notes'] as String? ?? '',
      createdAt: created,
      userId: map['userId'] as String? ?? '',
    );
  }
  // Copy with method for updates
  Reminder copyWith({
    int? id,
    String? medicineId,
    String? medicineName,
    String? reminderDate,
    String? reminderTime,
    String? dosage,
    String? status,
    String? notes,
    DateTime? createdAt,
    String? userId,
  }) {
    return Reminder(
      id: id ?? this.id,
      medicineId: medicineId ?? this.medicineId,
      medicineName: medicineName ?? this.medicineName,
      reminderDate: reminderDate ?? this.reminderDate,
      reminderTime: reminderTime ?? this.reminderTime,
      dosage: dosage ?? this.dosage,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      userId: userId ?? this.userId,
    );
  }
}
