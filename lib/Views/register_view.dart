import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/auth_viewmodel.dart';
import '../core/app_colors.dart';

class RegisterView extends StatelessWidget {
  RegisterView({super.key});

  final nameCtrl = TextEditingController();
  final ageCtrl = TextEditingController();
  final historyCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();
  final confirmPassCtrl = TextEditingController();

  final List<String> genders = ['Male', 'Female', 'Other'];

  @override
  Widget build(BuildContext context) {
    final vm = Provider.of<AuthViewModel>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyLarge?.color ?? Colors.black87;

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🔷 Header
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [AppColors.darkPrimary, AppColors.darkSecondary]
                      : [AppColors.primaryBlue, AppColors.lightBlue],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
              ),
              child: const Center(
                child: Text(
                  "Patient Registration",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🧾 Form Card
            Padding(
              padding: const EdgeInsets.all(20),
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Patient Name
                      TextField(
                        controller: nameCtrl,
                        style: TextStyle(color: textColor),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.person),
                          hintText: "Patient Full Name",
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Age
                      TextField(
                        controller: ageCtrl,
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.cake),
                          hintText: "Age",
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Gender Dropdown
                      DropdownButtonFormField<String>(
                        dropdownColor: theme.cardColor,
                        style: TextStyle(color: textColor),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.wc),
                          hintText: "Gender",
                        ),
                        items: genders
                            .map(
                              (g) => DropdownMenuItem(
                                value: g,
                                child: Text(g,
                                    style: TextStyle(color: textColor)),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {},
                      ),
                      const SizedBox(height: 14),

                      // Medical History
                      TextField(
                        controller: historyCtrl,
                        maxLines: 3,
                        style: TextStyle(color: textColor),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.medical_information),
                          hintText: "Medical History (e.g. Diabetes, BP)",
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Email
                      TextField(
                        controller: emailCtrl,
                        style: TextStyle(color: textColor),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.email),
                          hintText: "Email Address",
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password
                      TextField(
                        controller: passCtrl,
                        obscureText: !vm.isPasswordVisible,
                        style: TextStyle(color: textColor),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.lock),
                          hintText: "Password",
                          suffixIcon: IconButton(
                            icon: Icon(vm.isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off),
                            onPressed: vm.togglePassword,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Confirm Password
                      TextField(
                        controller: confirmPassCtrl,
                        obscureText: !vm.isPasswordVisible,
                        style: TextStyle(color: textColor),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.lock_outline),
                          hintText: "Confirm Password",
                        ),
                      ),
                      const SizedBox(height: 25),

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: () async {
                            if (passCtrl.text != confirmPassCtrl.text) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Passwords do not match")),
                              );
                              return;
                            }

                            final success = await vm.registerPatient(
                              name: nameCtrl.text.trim(),
                              age: int.parse(ageCtrl.text.trim()),
                              gender: 'Male', // connect dropdown value
                              history: historyCtrl.text.trim(),
                              email: emailCtrl.text.trim(),
                              password: passCtrl.text.trim(),
                            );

                            if (success) {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text(
                                        "Patient registered successfully")),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                    content: Text(vm.errorMessage ??
                                        "Registration failed")),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isDark
                                ? AppColors.darkSecondary
                                : AppColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: vm.isLoading
                              ? const CircularProgressIndicator(
                                  color: Colors.white,
                                )
                              : const Text(
                                  "Register Patient",
                                  style: TextStyle(
                                      fontSize: 18, color: Colors.white),
                                ),
                        ),
                      ),

                      const SizedBox(height: 15),

                      // Back to Login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Already registered? ",
                            style: TextStyle(color: textColor),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.pop(context),
                            child: Text(
                              "Log In",
                              style: TextStyle(
                                color: isDark
                                    ? AppColors.darkSecondary
                                    : AppColors.primaryBlue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
