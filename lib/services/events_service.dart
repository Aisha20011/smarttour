import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Event {
  final String id;
  final String title;
  final String titleEn;
  final String description;
  final String descriptionEn;
  final DateTime startDate;
  final DateTime endDate;
  final String location;
  final String locationEn;
  final String? imageUrl;
  final String category;
  final String categoryEn;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  Event({
    required this.id,
    required this.title,
    required this.titleEn,
    required this.description,
    required this.descriptionEn,
    required this.startDate,
    required this.endDate,
    required this.location,
    required this.locationEn,
    this.imageUrl,
    required this.category,
    required this.categoryEn,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'titleEn': titleEn,
      'description': description,
      'descriptionEn': descriptionEn,
      'startDate': Timestamp.fromDate(startDate),
      'endDate': Timestamp.fromDate(endDate),
      'location': location,
      'locationEn': locationEn,
      'imageUrl': imageUrl,
      'category': category,
      'categoryEn': categoryEn,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Event.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Event(
      id: doc.id,
      title: data['title'] ?? '',
      titleEn: data['titleEn'] ?? data['title'] ?? '',
      description: data['description'] ?? '',
      descriptionEn: data['descriptionEn'] ?? data['description'] ?? '',
      startDate: (data['startDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endDate: (data['endDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      location: data['location'] ?? '',
      locationEn: data['locationEn'] ?? data['location'] ?? '',
      imageUrl: data['imageUrl'],
      category: data['category'] ?? 'general',
      categoryEn: data['categoryEn'] ?? data['category'] ?? 'general',
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  bool get isUpcoming => startDate.isAfter(DateTime.now());
  bool get isOngoing => 
      DateTime.now().isAfter(startDate) && DateTime.now().isBefore(endDate);
  bool get isPast => endDate.isBefore(DateTime.now());
}

class EventsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get upcoming events
  Stream<List<Event>> getUpcomingEvents({int limit = 10}) {
    return _firestore
        .collection('events')
        .where('isActive', isEqualTo: true)
        .where('startDate', isGreaterThan: Timestamp.now())
        .orderBy('startDate', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    });
  }

  // Get ongoing events
  Stream<List<Event>> getOngoingEvents({int limit = 10}) {
    final now = Timestamp.now();
    return _firestore
        .collection('events')
        .where('isActive', isEqualTo: true)
        .where('startDate', isLessThanOrEqualTo: now)
        .where('endDate', isGreaterThanOrEqualTo: now)
        .orderBy('startDate', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    });
  }

  // Get all active events
  Stream<List<Event>> getActiveEvents({int limit = 20}) {
    return _firestore
        .collection('events')
        .where('isActive', isEqualTo: true)
        .orderBy('startDate', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    });
  }

  // Get events by category
  Stream<List<Event>> getEventsByCategory(String category, {int limit = 20}) {
    return _firestore
        .collection('events')
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category)
        .orderBy('startDate', descending: false)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Event.fromFirestore(doc)).toList();
    });
  }

  // Create event
  Future<String> createEvent(Event event) async {
    try {
      final docRef = await _firestore.collection('events').add(event.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create event: $e');
    }
  }

  // Update event
  Future<void> updateEvent(String eventId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('events').doc(eventId).update(updates);
    } catch (e) {
      throw Exception('Failed to update event: $e');
    }
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection('events').doc(eventId).delete();
    } catch (e) {
      throw Exception('Failed to delete event: $e');
    }
  }

  // Get event by ID
  Future<Event?> getEventById(String eventId) async {
    try {
      final doc = await _firestore.collection('events').doc(eventId).get();
      if (doc.exists) {
        return Event.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting event by ID: $e');
      return null;
    }
  }
}




