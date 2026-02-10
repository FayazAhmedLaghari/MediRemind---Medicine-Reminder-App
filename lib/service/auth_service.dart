import 'package:firebase_auth/firebase_auth.dart';
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  // 🔐 Login
  Future<User?> login(String email, String password) async {
    final userCredential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  // 📝 Register
  Future<User?> register(String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    return userCredential.user;
  }

  // � Send Password Reset Email
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // 🔑 Update Password
  Future<void> updatePassword(String newPassword) async {
    final user = _auth.currentUser;
    if (user != null) {
      await user.updatePassword(newPassword);
    } else {
      throw Exception('No user logged in');
    }
  }

  // 🔑 Confirm Password Reset (Sign in with email link)
  Future<bool> isSignInWithEmailLink(String email, String emailLink) async {
    return await _auth.isSignInWithEmailLink(emailLink);
  }

  // �🚪 Logout
  Future<void> logout() async {
    await _auth.signOut();
  }
}
