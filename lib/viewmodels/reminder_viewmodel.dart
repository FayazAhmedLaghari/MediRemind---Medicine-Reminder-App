import 'package:flutter/material.dart';
import '../models/reminder_model.dart';
import '../service/database_helper.dart';
import '../service/notification_service.dart';
class ReminderViewModel extends ChangeNotifier {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final NotificationService _notificationService = NotificationService();
  List<Reminder> reminders = [];  
  List<Reminder> filteredReminders = [];  
  bool isLoading = false;  
  String? errorMessage;
  // 📋 Load all reminders
  Future<void> loadReminders() async {
    try {
      isLoading = true;
      notifyListeners();
      reminders = await _db.getReminders();
      filteredReminders = reminders;
    } catch (e) {
      errorMessage = e.toString();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 📅 Get reminders for specific date
  Future<List<Reminder>> getRemindersByDate(DateTime date) async {
    try {
      final dateStr =
          '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      return await _db.getRemindersByDate(dateStr);
    } catch (e) {
      errorMessage = e.toString();
      return [];
    }
  }

  // ➕ Add reminder
  Future<bool> addReminder(Reminder reminder) async {
    try {
      isLoading = true;
      notifyListeners();

      final id = await _db.insertReminder(reminder);
      final reminderWithId = reminder.copyWith(id: id);
      
      // Schedule notification if reminder is pending and in the future
      if (reminder.status == 'pending') {
        await _notificationService.scheduleReminderNotification(reminderWithId);
      }
      
      await loadReminders();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ✏️ Update reminder
  Future<bool> updateReminder(Reminder reminder) async {
    try {
      isLoading = true;
      notifyListeners();

      // Cancel existing notification
      if (reminder.id != null) {
        await _notificationService.cancelReminderNotification(reminder.id!);
      }

      await _db.updateReminder(reminder);
      
      // Schedule new notification if reminder is pending
      if (reminder.status == 'pending' && reminder.id != null) {
        await _notificationService.scheduleReminderNotification(reminder);
      }
      
      await loadReminders();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ❌ Delete reminder
  Future<bool> deleteReminder(int id) async {
    try {
      isLoading = true;
      notifyListeners();

      // Cancel notification before deleting
      await _notificationService.cancelReminderNotification(id);
      
      await _db.deleteReminder(id);
      await loadReminders();
      return true;
    } catch (e) {
      errorMessage = e.toString();
      return false;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // 🔍 Get upcoming reminders
  Future<List<Reminder>> getUpcomingReminders() async {
    try {
      return await _db.getUpcomingReminders();
    } catch (e) {
      errorMessage = e.toString();
      return [];
    }
  }

  // 🔎 Filter reminders by status
  void filterByStatus(String status) {
    if (status == 'all') {
      filteredReminders = reminders;
    } else {
      filteredReminders = reminders.where((r) => r.status == status).toList();
    }
    notifyListeners();
  }

  // 🔎 Filter reminders by date range
  void filterByDateRange(DateTime start, DateTime end) {
    final startStr =
        '${start.year}-${start.month.toString().padLeft(2, '0')}-${start.day.toString().padLeft(2, '0')}';
    final endStr =
        '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}';

    filteredReminders = reminders.where((r) {
      return r.reminderDate.compareTo(startStr) >= 0 &&
          r.reminderDate.compareTo(endStr) <= 0;
    }).toList();
    notifyListeners();
  }

  // 🔔 Reschedule all pending reminders
  Future<void> rescheduleAllReminders() async {
    try {
      await _notificationService.rescheduleAllReminders();
    } catch (e) {
      errorMessage = e.toString();
    }
  }
}
