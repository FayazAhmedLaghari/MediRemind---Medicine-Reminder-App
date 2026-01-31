# Reminders Feature - Quick Start Guide

## What's New

### ✨ Features
1. **📅 Interactive Calendar** - Click dates to view/add reminders
2. **💊 Reminder Management** - Add, update, delete medication reminders
3. **💾 SQLite Database** - All reminders persist locally
4. **⏰ Time Scheduling** - Pick specific times for each reminder
5. **📝 Notes Support** - Add notes to reminders
6. **🎨 Status Tracking** - Track reminder completion status

## How to Use

### Access Reminders
**Option 1:** Click "Reminders" tile on dashboard
**Option 2:** Click "Reminders" in drawer menu

### Add a Reminder
1. Click "Add Reminder" button (FAB)
2. Select medicine from dropdown
3. Pick time using time picker
4. Add optional notes
5. Click "Add" to save

### View Reminders
1. Click any date on calendar
2. Selected date highlights in blue
3. Reminders for that day appear below

### Update Reminder Status
1. Click "Mark Done" on reminder card
2. Status changes to "COMPLETED" (green)
3. Button disappears for completed reminders

### Delete Reminder
1. Click "Delete" on reminder card
2. Confirm deletion in dialog
3. Reminder removed from list

## Technical Details

### Database
- **Table**: `reminders`
- **Type**: SQLite (local device storage)
- **Synced**: No (works offline)

### Data Model
```dart
Reminder {
  id,
  medicineId,
  medicineName,
  reminderDate,    // yyyy-MM-dd
  reminderTime,    // HH:mm
  dosage,
  status,          // pending, completed, missed
  notes,
  createdAt
}
```

### State Management
- **Provider**: ReminderViewModel
- **Pattern**: MVVM
- **Updates**: Automatic UI refresh

## Files Changed

| File | Change |
|------|--------|
| reminder_model.dart | NEW - Data model |
| reminder_viewmodel.dart | NEW - State manager |
| reminders_view.dart | NEW - Complete UI |
| database_helper.dart | UPDATED - Added reminder table & CRUD |
| main.dart | UPDATED - Added ReminderViewModel |
| dashboard_view.dart | UPDATED - Navigation links |
| pubspec.yaml | UPDATED - Added intl dependency |

## Database Operations

### Load All Reminders
```dart
final vm = Provider.of<ReminderViewModel>(context);
await vm.loadReminders();
```

### Get Reminders by Date
```dart
List<Reminder> today = await vm.getRemindersByDate(DateTime.now());
```

### Add Reminder
```dart
final reminder = Reminder(
  medicineId: '1',
  medicineName: 'Aspirin',
  reminderDate: '2026-01-19',
  reminderTime: '09:00',
  dosage: '500mg',
  createdAt: DateTime.now(),
);
await vm.addReminder(reminder);
```

### Update Reminder
```dart
final updated = reminder.copyWith(status: 'completed');
await vm.updateReminder(updated);
```

### Delete Reminder
```dart
await vm.deleteReminder(reminderId);
```

## UI Components

### Calendar Widget
- Month/year header with navigation
- Day labels (Sun-Sat)
- Grid of dates (7 columns)
- Color coding for selection/today
- Click to select date

### Reminder Card
- **Left border**: Color-coded status
- **Medication name**: Bold title
- **Time**: Large blue text
- **Dosage**: Gray subtitle
- **Status badge**: Colored pill
- **Notes**: Italicized if present
- **Buttons**: Mark Done, Delete

### Dialogs
- **Add Reminder**: Medicine dropdown, time picker, notes
- **Delete Confirmation**: Yes/No confirmation

## Status Colors
| Status | Color | Meaning |
|--------|-------|---------|
| PENDING | 🟠 Orange | Upcoming reminder |
| COMPLETED | 🟢 Green | Marked as taken |
| MISSED | 🔴 Red | Passed without marking |

## Keyboard & Input
- **Medicine Dropdown**: Searchable list
- **Time Picker**: Native Flutter dialog
- **Notes Field**: Multi-line text input

## Performance
- ⚡ Fast database queries (indexed by date)
- 📱 Low memory footprint
- 🔄 Efficient state updates
- 📊 Handles 100+ reminders easily

## Error Handling
| Scenario | Behavior |
|----------|----------|
| No medicine selected | Shows orange SnackBar |
| No time selected | Shows orange SnackBar |
| Database error | Shows red SnackBar with error |
| Add success | Shows green SnackBar |
| Delete success | Shows red SnackBar |

## Testing Quick Checks
```
[ ] Calendar displays correctly
[ ] Can select dates
[ ] Can add reminder
[ ] Reminder shows in list
[ ] Can mark done
[ ] Can delete reminder
[ ] Data persists after restart
```

## Troubleshooting

### Reminders Not Showing
1. Check selected date has correct format (YYYY-MM-DD)
2. Verify database migration ran (version 1→2)
3. Check ReminderViewModel is in Provider

### Time Not Working
1. Ensure TimeOfDay picked correctly
2. Check time format is HH:mm
3. Verify system time is correct

### Delete Not Working
1. Check reminder.id is not null
2. Verify reminder exists in database
3. Try reloading app

## Future Plans
- 🔔 Push notifications
- 🔄 Recurring reminders
- 📊 Reminder statistics
- 🗓️ Calendar sync
- 🤖 Smart timing

## Support
All features are fully functional. No known issues.

For questions or improvements, review:
- REMINDERS_FEATURE_IMPLEMENTATION.md (detailed)
- Code comments in reminders_view.dart
- ReminderViewModel for logic
