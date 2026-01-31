import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();

  factory AuthService() {
    return _instance;
  }

  AuthService._internal();

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Check if user is logged in and has valid token
  Future<bool> isUserLoggedIn() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        // Get the ID token to verify it's still valid
        String? token = await user.getIdToken();
        return token != null && token.isNotEmpty;
      }
      return false;
    } catch (e) {
      print('Error checking login status: $e');
      return false;
    }
  }

  // Get current user
  User? getCurrentUser() {
    return _firebaseAuth.currentUser;
  }

  // Sign out user
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  // Get user token
  Future<String?> getUserToken() async {
    try {
      User? user = _firebaseAuth.currentUser;
      if (user != null) {
        return await user.getIdToken();
      }
      return null;
    } catch (e) {
      print('Error getting user token: $e');
      return null;
    }
  }

  // Get auth state stream
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();
}
