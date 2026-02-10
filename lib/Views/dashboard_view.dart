import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/medicine_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
import '../../l10n/app_localizations.dart';
import '../core/app_colors.dart';
import 'Medicine/medicine_list_view.dart';
import 'ocr/scan_prescription_view.dart';
import 'Reminders/reminders_view.dart';
import 'profile_view.dart';
import 'login_view.dart';

class DashboardView extends StatefulWidget {
  const DashboardView({super.key});

  @override
  State<DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      final dashVM = Provider.of<DashboardViewModel>(context, listen: false);
      final medicineVM = Provider.of<MedicineViewModel>(context, listen: false);
      dashVM.loadPatient();
      medicineVM.loadMedicines();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;
    final accentColor = isDark ? AppColors.darkSecondary : AppColors.primaryBlue;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)!.dashboardTitle),
        backgroundColor: isDark ? AppColors.darkPrimary : Theme.of(context).primaryColor,
        actions: [
          IconButton(
            icon: Icon(
              Provider.of<ThemeViewModel>(context).themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              Provider.of<ThemeViewModel>(context, listen: false).toggleTheme();
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: Consumer<DashboardViewModel>(
          builder: (context, vm, _) {
            if (vm.patient == null) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView(
              children: [
                UserAccountsDrawerHeader(
                  accountName: Text(vm.patient!.name),
                  accountEmail: Text(vm.patient!.email),
                  currentAccountPicture: const CircleAvatar(
                    child: Icon(Icons.person, size: 40),
                  ),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkPrimary : AppColors.primaryBlue,
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.medication),
                  title: Text(AppLocalizations.of(context)!.myMedicines),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MedicineListView(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: Text(AppLocalizations.of(context)!.scanPrescription),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ScanPrescriptionView(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.alarm),
                  title: Text(AppLocalizations.of(context)!.reminders),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RemindersView(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.person),
                  title: Text(AppLocalizations.of(context)!.profile),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileView(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: Icon(
                    Provider.of<ThemeViewModel>(context).themeMode ==
                            ThemeMode.dark
                        ? Icons.light_mode
                        : Icons.dark_mode,
                  ),
                  title: Text(
                    Provider.of<ThemeViewModel>(context).themeMode ==
                            ThemeMode.dark
                        ? AppLocalizations.of(context)!.lightMode
                        : AppLocalizations.of(context)!.darkMode,
                  ),
                  onTap: () {
                    Provider.of<ThemeViewModel>(context, listen: false)
                        .toggleTheme();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(AppLocalizations.of(context)!.language),
                  onTap: () {
                    _showLanguageSelectionDialog(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text("Logout"),
                  onTap: () {
                    _showLogoutDialog(context);
                  },
                ),
              ],
            );
          },
        ),
      ),
      body: Consumer<DashboardViewModel>(
        builder: (context, vm, _) {
          if (vm.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (vm.patient == null) {
            return Center(
                child: Text("No patient data found",
                    style: TextStyle(color: textColor)));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 👤 Patient Card
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 6,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vm.patient!.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text("Age: ${vm.patient!.age}",
                            style: TextStyle(color: textColor)),
                        Text("Gender: ${vm.patient!.gender}",
                            style: TextStyle(color: textColor)),
                        const SizedBox(height: 8),
                        Text(
                          "History:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: accentColor,
                          ),
                        ),
                        Text(vm.patient!.history,
                            style: TextStyle(color: textColor)),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // 💊 Today's Medicines
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.todaysMedicines,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor),
                            ),
                            Text(
                              AppLocalizations.of(context)!.today,
                              style: TextStyle(
                                  color: isDark
                                      ? AppColors.darkTextSecondary
                                      : Colors.grey),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        if (Provider.of<DashboardViewModel>(context)
                            .todaysReminders
                            .isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child:
                                Text(AppLocalizations.of(context)!.noReminders,
                                    style: TextStyle(color: textColor)),
                          )
                        else
                          SizedBox(
                            height: 120,
                            child: ListView.separated(
                              itemCount:
                                  Provider.of<DashboardViewModel>(context)
                                      .todaysReminders
                                      .length,
                              separatorBuilder: (_, __) => const Divider(),
                              itemBuilder: (context, index) {
                                final r =
                                    Provider.of<DashboardViewModel>(context)
                                        .todaysReminders[index];
                                return ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        accentColor.withOpacity(0.1),
                                    child: Text(
                                        r.reminderTime.substring(0, 5),
                                        style: TextStyle(
                                            fontSize: 12, color: textColor)),
                                  ),
                                  title: Text(r.medicineName,
                                      style: TextStyle(color: textColor)),
                                  subtitle: Text(
                                      '${r.dosage}${r.notes.isNotEmpty ? '\nNote: ${r.notes}' : ''}',
                                      style: TextStyle(
                                          color: isDark
                                              ? AppColors.darkTextSecondary
                                              : null)),
                                );
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 🗒️ Personal Notes / Doctor Instructions
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              AppLocalizations.of(context)!.personalNotes,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: textColor),
                            ),
                            IconButton(
                              onPressed: () => _showEditNotesDialog(context),
                              icon: const Icon(Icons.edit),
                            )
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          (Provider.of<DashboardViewModel>(context)
                                          .patient
                                          ?.notes ??
                                      '')
                                  .isNotEmpty
                              ? (Provider.of<DashboardViewModel>(context)
                                      .patient
                                      ?.notes ??
                                  '')
                              : AppLocalizations.of(context)!.noNotes,
                          style: TextStyle(color: textColor),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)!.doctorInstructions,
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: textColor),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (Provider.of<DashboardViewModel>(context)
                                          .patient
                                          ?.doctorInstructions ??
                                      '')
                                  .isNotEmpty
                              ? (Provider.of<DashboardViewModel>(context)
                                      .patient
                                      ?.doctorInstructions ??
                                  '')
                              : AppLocalizations.of(context)!.noNotes,
                          style: TextStyle(color: textColor),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 💊 First Row - Medicines & Scan
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DashboardTile(
                      title: AppLocalizations.of(context)!.myMedicines,
                      icon: Icons.medication,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MedicineListView(),
                          ),
                        );
                      },
                    ),
                    _DashboardTile(
                      title: AppLocalizations.of(context)!.scanPrescription,
                      icon: Icons.camera_alt,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScanPrescriptionView(),
                          ),
                        );
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 🔔 Second Row - Reminders & Profile
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DashboardTile(
                      title: AppLocalizations.of(context)!.reminders,
                      icon: Icons.alarm,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RemindersView(),
                          ),
                        );
                      },
                    ),
                    _DashboardTile(
                      title: AppLocalizations.of(context)!.profile,
                      icon: Icons.person,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfileView(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 🚪 Logout Dialog
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.confirmLogout),
        content: Text(AppLocalizations.of(context)!.logoutConfirmation),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first

              final authVM = Provider.of<AuthViewModel>(context, listen: false);
              final success = await authVM.logout();

              if (success && context.mounted) {
                // Clear navigation stack and go to login
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => LoginView()),
                  (route) => false,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(AppLocalizations.of(context)!.loggedOut),
                    backgroundColor: Colors.green,
                    duration: const Duration(seconds: 2),
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Error: ${authVM.errorMessage ?? AppLocalizations.of(context)!.logoutConfirmation}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: Text(
              AppLocalizations.of(context)!.logout,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelectionDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(AppLocalizations.of(context)!.selectLanguage),
          content: Consumer<LanguageViewModel>(
            builder: (context, langVM, child) {
              return SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: langVM.supportedLocales.length,
                  itemBuilder: (context, index) {
                    final locale = langVM.supportedLocales[index];
                    return RadioListTile<Locale>(
                      title: Text(langVM.getLanguageName(locale)),
                      value: locale,
                      groupValue: langVM.selectedLocale,
                      onChanged: (Locale? value) {
                        if (value != null) {
                          langVM.changeLanguage(value);
                          Navigator.pop(context);
                        }
                      },
                    );
                  },
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _showEditNotesDialog(BuildContext context) {
    final vm = Provider.of<DashboardViewModel>(context, listen: false);
    final notesCtrl = TextEditingController(text: vm.patient?.notes ?? '');
    final doctorCtrl =
        TextEditingController(text: vm.patient?.doctorInstructions ?? '');
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.personalNotes),
        content: SingleChildScrollView(
          child: Column(
            children: [
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.personalNotes,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: doctorCtrl,
                maxLines: 3,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)!.doctorInstructions,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await vm.saveNotes(
                notes: notesCtrl.text.trim(),
                doctorInstructions: doctorCtrl.text.trim(),
              );
              Navigator.pop(context);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(AppLocalizations.of(context)!.saveNotes)),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Error saving notes')),
                );
              }
            },
            child: Text(AppLocalizations.of(context)!.saveNotes),
          ),
        ],
      ),
    );
  }
}

// 🔹 Reusable Tile
class _DashboardTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _DashboardTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 25),
            child: Column(
              children: [
                Icon(icon,
                    size: 40,
                    color:
                        isDark ? AppColors.darkSecondary : AppColors.primaryBlue),
                const SizedBox(height: 10),
                Text(title, style: TextStyle(color: textColor)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
