import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AdminService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check if current user is admin
  Future<bool> isAdmin() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      // Check if email is admin email
      if (user.email == 'admin@gmail.com') {
        return true;
      }

      // Check admin role in Firestore
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        return data?['isAdmin'] == true || data?['role'] == 'admin';
      }

      return false;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  // Get admin statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final placesCount = await _firestore.collection('places').count().get();
      final tripsCount = await _firestore.collection('trips').count().get();
      final usersCount = await _firestore.collection('users').count().get();
      final faqsCount = await _firestore.collection('faqs').count().get();

      return {
        'places': placesCount.count,
        'trips': tripsCount.count,
        'users': usersCount.count,
        'faqs': faqsCount.count,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {
        'places': 0,
        'trips': 0,
        'users': 0,
        'faqs': 0,
      };
    }
  }
}



