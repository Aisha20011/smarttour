import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserData {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoURL;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserData({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.photoURL,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert UserData to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName ?? '',
      'phoneNumber': phoneNumber ?? '',
      'photoURL': photoURL ?? '',
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  // Create UserData from Firestore document
  factory UserData.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserData(
      uid: doc.id,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      phoneNumber: data['phoneNumber'],
      photoURL: data['photoURL'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  // Create UserData from Firebase User
  factory UserData.fromFirebaseUser(User user) {
    return UserData(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
      phoneNumber: user.phoneNumber,
      photoURL: user.photoURL,
      createdAt: user.metadata.creationTime ?? DateTime.now(),
      updatedAt: user.metadata.lastSignInTime,
    );
  }
}

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create or update user document in Firestore
  Future<void> createOrUpdateUser({
    required String uid,
    required String email,
    String? displayName,
    String? phoneNumber,
    String? photoURL,
    bool? isAdmin,
  }) async {
    try {
      final userRef = _firestore.collection('users').doc(uid);
      final userDoc = await userRef.get();

      if (userDoc.exists) {
        // Update existing user
        final updates = <String, dynamic>{
          'updatedAt': FieldValue.serverTimestamp(),
        };
        
        if (displayName != null && displayName.isNotEmpty) {
          updates['displayName'] = displayName;
        }
        if (phoneNumber != null && phoneNumber.isNotEmpty) {
          updates['phoneNumber'] = phoneNumber;
        }
        if (photoURL != null && photoURL.isNotEmpty) {
          updates['photoURL'] = photoURL;
        }
        if (isAdmin != null) {
          updates['isAdmin'] = isAdmin;
          updates['role'] = isAdmin ? 'admin' : 'user';
        }
        
        // Always update email to ensure it's current
        updates['email'] = email;
        
        await userRef.update(updates);
      } else {
        // Create new user
        final userData = UserData(
          uid: uid,
          email: email,
          displayName: displayName ?? '',
          phoneNumber: phoneNumber ?? '',
          photoURL: photoURL ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await userRef.set(userData.toMap());
      }
    } on FirebaseException catch (e) {
      throw Exception('Firestore error: ${e.code} - ${e.message}');
    } catch (e) {
      throw Exception('Failed to create/update user: $e');
    }
  }

  // Get user data from Firestore
  Future<UserData?> getUserData(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserData.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get user data: $e');
    }
  }

  // Get current user data
  Future<UserData?> getCurrentUserData() async {
    if (currentUserId == null) {
      return null;
    }
    return getUserData(currentUserId!);
  }

  // Update user data
  Future<void> updateUserData({
    String? displayName,
    String? phoneNumber,
    String? photoURL,
  }) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final updates = <String, dynamic>{
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayName != null) {
        updates['displayName'] = displayName;
      }
      if (phoneNumber != null) {
        updates['phoneNumber'] = phoneNumber;
      }
      if (photoURL != null) {
        updates['photoURL'] = photoURL;
      }

      await _firestore.collection('users').doc(currentUserId!).update(updates);
    } catch (e) {
      throw Exception('Failed to update user data: $e');
    }
  }

  // Stream user data
  Stream<UserData?> getUserDataStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserData.fromFirestore(doc);
      }
      return null;
    });
  }

  // Stream current user data
  Stream<UserData?> getCurrentUserDataStream() {
    if (currentUserId == null) {
      return Stream.value(null);
    }
    return getUserDataStream(currentUserId!);
  }

  // Delete user data (when user deletes account)
  Future<void> deleteUserData(String uid) async {
    try {
      await _firestore.collection('users').doc(uid).delete();
    } catch (e) {
      throw Exception('Failed to delete user data: $e');
    }
  }
}

