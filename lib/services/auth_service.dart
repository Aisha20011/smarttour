import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_service.dart';
import 'admin_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final UserService _userService = UserService();

  // Get current user
  User? get currentUser => _auth.currentUser;

  // Auth state stream
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Sign up with email and password
  Future<UserCredential?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    String? name,
    String? phone,
  }) async {
    try {
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Update user display name if provided
      if (name != null && userCredential.user != null) {
        await userCredential.user!.updateDisplayName(name);
        await userCredential.user!.reload();
      }

      // Save user data to Firestore (non-blocking - don't fail if this fails)
      if (userCredential.user != null) {
        try {
          await _userService.createOrUpdateUser(
            uid: userCredential.user!.uid,
            email: email,
            displayName: name,
            phoneNumber: phone,
            photoURL: userCredential.user!.photoURL,
          );
        } catch (e) {
          // Log error but don't fail the signup
          // User is already created in Firebase Auth
          print('Warning: Failed to save user data to Firestore: $e');
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'حدث خطأ غير متوقع: $e';
    }
  }

  // Sign in with email and password
  Future<UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // If admin login, set admin role in Firestore
      if (email == 'admin@gmail.com') {
        try {
          await _userService.createOrUpdateUser(
            uid: userCredential.user!.uid,
            email: email,
            displayName: 'Admin',
            isAdmin: true,
          );
        } catch (e) {
          print('Warning: Failed to set admin role: $e');
        }
      }
      
      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'حدث خطأ غير متوقع: $e';
    }
  }

  // Sign in with Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the authentication flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User canceled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      final userCredential = await _auth.signInWithCredential(credential);

      // Save user data to Firestore (non-blocking - don't fail if this fails)
      if (userCredential.user != null) {
        try {
          await _userService.createOrUpdateUser(
            uid: userCredential.user!.uid,
            email: userCredential.user!.email ?? '',
            displayName: userCredential.user!.displayName ?? googleUser.displayName,
            phoneNumber: userCredential.user!.phoneNumber,
            photoURL: userCredential.user!.photoURL ?? googleUser.photoUrl,
          );
        } catch (e) {
          // Log error but don't fail the sign-in
          // User is already signed in
          print('Warning: Failed to save user data to Firestore: $e');
        }
      }

      return userCredential;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'حدث خطأ غير متوقع: $e';
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await Future.wait([
        _auth.signOut(),
        _googleSignIn.signOut(),
      ]);
      
      // Clear remember me when logging out
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('remembered_email');
        await prefs.setBool('remember_me', false);
      } catch (e) {
        print('Error clearing remember me: $e');
      }
    } catch (e) {
      throw 'حدث خطأ أثناء تسجيل الخروج: $e';
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      throw 'حدث خطأ غير متوقع: $e';
    }
  }

  // Handle Firebase Auth Exceptions
  // Returns error code that can be translated in the UI
  String _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'weak-password';
      case 'email-already-in-use':
        return 'email-already-in-use';
      case 'user-not-found':
        return 'user-not-found';
      case 'wrong-password':
        return 'wrong-password';
      case 'invalid-email':
        return 'invalid-email-format';
      case 'user-disabled':
        return 'user-disabled';
      case 'too-many-requests':
        return 'too-many-requests';
      case 'operation-not-allowed':
        return 'operation-not-allowed';
      case 'network-request-failed':
        return 'network-error';
      default:
        return 'unknown-error';
    }
  }
  
  // Get user-friendly error message key
  String getErrorMessageKey(String errorCode) {
    switch (errorCode) {
      case 'weak-password':
        return 'weak_password';
      case 'email-already-in-use':
        return 'email_already_in_use';
      case 'user-not-found':
        return 'user_not_found';
      case 'wrong-password':
        return 'wrong_password';
      case 'invalid-email-format':
        return 'invalid_email_format';
      case 'user-disabled':
        return 'user_disabled';
      case 'too-many-requests':
        return 'too_many_requests';
      case 'operation-not-allowed':
        return 'operation_not_allowed';
      case 'network-error':
        return 'network_error';
      default:
        return 'unknown_error';
    }
  }
}

