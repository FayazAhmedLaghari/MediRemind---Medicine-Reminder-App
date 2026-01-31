import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/medicine_viewmodel.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../../viewmodels/theme_viewmodel.dart';
import '../../viewmodels/language_viewmodel.dart';
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Patient Dashboard"),
        backgroundColor: Theme.of(context).primaryColor,
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
                ),
                ListTile(
                  leading: const Icon(Icons.medication),
                  title: const Text("My Medicines"),
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
                  title: const Text("Scan Prescription"),
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
                  title: const Text("Reminders"),
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
                  title: const Text("Profile"),
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
                    Provider.of<ThemeViewModel>(context).themeMode == ThemeMode.dark 
                      ? Icons.light_mode 
                      : Icons.dark_mode,
                  ),
                  title: Text(
                    Provider.of<ThemeViewModel>(context).themeMode == ThemeMode.dark 
                      ? "Light Mode" 
                      : "Dark Mode",
                  ),
                  onTap: () {
                    Provider.of<ThemeViewModel>(context, listen: false).toggleTheme();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.language),
                  title: const Text("Language"),
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
            return const Center(child: Text("No patient data found"));
          }

          return Padding(
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
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text("Age: ${vm.patient!.age}"),
                        Text("Gender: ${vm.patient!.gender}"),
                        const SizedBox(height: 8),
                        Text(
                          "History:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        Text(vm.patient!.history),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // 💊 Placeholder Sections
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DashboardTile(
                      title: "My Medicines",
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
                      title: "Scan Prescription",
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

                // 🔔 Second Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _DashboardTile(
                      title: "Reminders",
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
                      title: "Profile",
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
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
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
                  const SnackBar(
                    content: Text('✅ Logged out successfully'),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 2),
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Error: ${authVM.errorMessage ?? 'Failed to logout'}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: Colors.red),
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
          title: const Text("Select Language"),
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
                Icon(icon, size: 40, color: AppColors.primaryBlue),
                const SizedBox(height: 10),
                Text(title),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
