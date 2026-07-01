import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Trip {
  final String id;
  final String name;
  final String nameEn;
  final DateTime startDate;
  final DateTime endDate;
  final int places;
  final String status; // 'planned', 'ongoing', 'completed'
  final String? description;
  final String? descriptionEn;
  final String? imageUrl;
  final String userId;

  Trip({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.startDate,
    required this.endDate,
    required this.places,
    required this.status,
    this.description,
    this.descriptionEn,
    this.imageUrl,
    required this.userId,
  });

  // Convert Trip to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameEn': nameEn,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'places': places,
      'status': status,
      'description': description ?? '',
      'descriptionEn': descriptionEn ?? '',
      'imageUrl': imageUrl ?? '',
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Create Trip from Firestore document
  factory Trip.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Trip(
      id: doc.id,
      name: data['name'] ?? '',
      nameEn: data['nameEn'] ?? data['name'] ?? '',
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      places: data['places'] ?? 0,
      status: data['status'] ?? 'planned',
      description: data['description'],
      descriptionEn: data['descriptionEn'] ?? data['description'],
      imageUrl: data['imageUrl'],
      userId: data['userId'] ?? '',
    );
  }
}

class TripsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get currentUserId => _auth.currentUser?.uid;

  // Create a new trip
  Future<String> createTrip(Trip trip) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      final tripData = trip.toMap();
      tripData['userId'] = currentUserId!;

      final docRef = await _firestore
          .collection('trips')
          .add(tripData);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create trip: $e');
    }
  }

  // Get all trips for current user
  Stream<List<Trip>> getTripsStream() {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('trips')
        .where('userId', isEqualTo: currentUserId)
        .snapshots()
        .map((snapshot) {
      final trips = snapshot.docs
          .map((doc) => Trip.fromFirestore(doc))
          .toList();
      // Sort by createdAt descending locally
      trips.sort((a, b) {
        // Compare by createdAt if available, otherwise by id
        final aDate = a.startDate; // Use startDate as fallback
        final bDate = b.startDate;
        return bDate.compareTo(aDate);
      });
      return trips;
    });
  }

  // Get trips by status
  Stream<List<Trip>> getTripsByStatus(String status) {
    if (currentUserId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('trips')
        .where('userId', isEqualTo: currentUserId)
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snapshot) {
      final trips = snapshot.docs
          .map((doc) => Trip.fromFirestore(doc))
          .toList();
      // Sort by startDate descending locally
      trips.sort((a, b) => b.startDate.compareTo(a.startDate));
      return trips;
    });
  }

  // Update trip
  Future<void> updateTrip(String tripId, Map<String, dynamic> updates) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      updates['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('trips')
          .doc(tripId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update trip: $e');
    }
  }

  // Delete trip
  Future<void> deleteTrip(String tripId) async {
    try {
      if (currentUserId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('trips')
          .doc(tripId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete trip: $e');
    }
  }

  // Get single trip
  Future<Trip?> getTrip(String tripId) async {
    try {
      final doc = await _firestore
          .collection('trips')
          .doc(tripId)
          .get();

      if (doc.exists) {
        return Trip.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get trip: $e');
    }
  }
}

