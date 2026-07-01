import 'package:cloud_firestore/cloud_firestore.dart';

class Place {
  final String id;
  final String name;
  final String nameEn;
  final String description;
  final String descriptionEn;
  final String category;
  final String categoryEn;
  final double rating;
  final int reviews;
  final double latitude;
  final double longitude;
  final String? address;
  final String? addressEn;
  final String? phone;
  final String? website;
  final String? hours;
  final String? visitHours; // ساعات الزيارة
  final String? imageUrl;
  final List<String>? imageUrls;
  final String? audioGuideUrl; // رابط الدليل الصوتي
  final String? arImageUrl; // صورة الواقع المعزز
  final bool isFeatured;
  final DateTime createdAt;
  final DateTime updatedAt;

  Place({
    required this.id,
    required this.name,
    required this.nameEn,
    required this.description,
    required this.descriptionEn,
    required this.category,
    required this.categoryEn,
    required this.rating,
    required this.reviews,
    required this.latitude,
    required this.longitude,
    this.address,
    this.addressEn,
    this.phone,
    this.website,
    this.hours,
    this.visitHours,
    this.imageUrl,
    this.imageUrls,
    this.audioGuideUrl,
    this.arImageUrl,
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'nameEn': nameEn,
      'description': description,
      'descriptionEn': descriptionEn,
      'category': category,
      'categoryEn': categoryEn,
      'rating': rating,
      'reviews': reviews,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
      'addressEn': addressEn,
      'phone': phone,
      'website': website,
      'hours': hours,
      'visitHours': visitHours,
      'imageUrl': imageUrl,
      'imageUrls': imageUrls ?? [],
      'audioGuideUrl': audioGuideUrl,
      'arImageUrl': arImageUrl,
      'isFeatured': isFeatured,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Place.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Helper function to safely get string value
    String _getString(dynamic value, String fallback) {
      if (value == null) return fallback;
      if (value is String) return value;
      return value.toString();
    }
    
    // Helper function to safely get list of strings
    List<String>? _getStringList(dynamic value) {
      if (value == null) return null;
      if (value is List) {
        return value.map((e) => e.toString()).toList();
      }
      return null;
    }
    
    return Place(
      id: doc.id,
      name: _getString(data['name'], ''),
      nameEn: _getString(data['nameEn'], _getString(data['name'], '')),
      description: _getString(data['description'], ''),
      descriptionEn: _getString(data['descriptionEn'], _getString(data['description'], '')),
      category: _getString(data['category'], ''),
      categoryEn: _getString(data['categoryEn'], _getString(data['category'], '')),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      reviews: (data['reviews'] as num?)?.toInt() ?? 0,
      latitude: (data['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (data['longitude'] as num?)?.toDouble() ?? 0.0,
      address: data['address'] != null ? _getString(data['address'], '') : null,
      addressEn: data['addressEn'] != null ? _getString(data['addressEn'], '') : null,
      phone: data['phone'] != null ? _getString(data['phone'], '') : null,
      website: data['website'] != null ? _getString(data['website'], '') : null,
      hours: data['hours'] != null ? _getString(data['hours'], '') : null,
      visitHours: data['visitHours'] != null ? _getString(data['visitHours'], '') : null,
      imageUrl: data['imageUrl'] != null ? _getString(data['imageUrl'], '') : null,
      imageUrls: _getStringList(data['imageUrls']),
      audioGuideUrl: data['audioGuideUrl'] != null ? _getString(data['audioGuideUrl'], '') : null,
      arImageUrl: data['arImageUrl'] != null ? _getString(data['arImageUrl'], '') : null,
      isFeatured: data['isFeatured'] == true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class PlacesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get featured places
  Stream<List<Place>> getFeaturedPlaces({int limit = 10}) {
    return _firestore
        .collection('places')
        .where('isFeatured', isEqualTo: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final placesMap = <String, Place>{};
      for (var doc in snapshot.docs) {
        try {
          final place = Place.fromFirestore(doc);
          // Use place ID as key to avoid duplicates
          placesMap[place.id] = place;
        } catch (e) {
          print('Error parsing place ${doc.id}: $e');
        }
      }
      final places = placesMap.values.toList();
      // Sort by rating in memory
      places.sort((a, b) => b.rating.compareTo(a.rating));
      return places.take(limit).toList();
    });
  }

  // Get places by category
  Stream<List<Place>> getPlacesByCategory(String category, {int limit = 20}) {
    return _firestore
        .collection('places')
        .where('category', isEqualTo: category)
        .orderBy('rating', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Place.fromFirestore(doc)).toList();
    });
  }

  // Get places count by category
  Future<int> getPlacesCountByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('places')
          .where('category', isEqualTo: category)
          .count()
          .get();
      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting places count: $e');
      return 0;
    }
  }

  // Get all categories with counts
  Future<Map<String, int>> getCategoriesWithCounts() async {
    try {
      final snapshot = await _firestore.collection('places').get();
      final Map<String, int> counts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final category = data['category'] as String? ?? 'other';
        counts[category] = (counts[category] ?? 0) + 1;
      }

      return counts;
    } catch (e) {
      print('Error getting categories with counts: $e');
      return {};
    }
  }

  // Get place by ID
  Future<Place?> getPlaceById(String placeId) async {
    try {
      final doc = await _firestore.collection('places').doc(placeId).get();
      if (doc.exists) {
        return Place.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting place by ID: $e');
      return null;
    }
  }

  // Get all places
  Stream<List<Place>> getAllPlaces({int limit = 100}) {
    return _firestore
        .collection('places')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      final places = snapshot.docs.map((doc) {
        try {
          return Place.fromFirestore(doc);
        } catch (e) {
          print('Error parsing place ${doc.id}: $e');
          return null;
        }
      }).whereType<Place>().toList();
      // Sort by rating in memory
      places.sort((a, b) => b.rating.compareTo(a.rating));
      return places;
    });
  }

  // Search places
  Stream<List<Place>> searchPlaces(String query, {int limit = 20}) {
    // Note: Firestore doesn't support full-text search natively
    // This is a simple prefix search on name field
    // For better search, consider using Algolia or similar service
    return _firestore
        .collection('places')
        .where('name', isGreaterThanOrEqualTo: query)
        .where('name', isLessThan: query + 'z')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Place.fromFirestore(doc)).toList();
    });
  }

  // Create a new place
  Future<String> createPlace(Place place) async {
    try {
      final docRef = await _firestore.collection('places').add(place.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create place: $e');
    }
  }

  // Update place
  Future<void> updatePlace(String placeId, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('places').doc(placeId).update(updates);
    } catch (e) {
      throw Exception('Failed to update place: $e');
    }
  }

  // Delete place
  Future<void> deletePlace(String placeId) async {
    try {
      await _firestore.collection('places').doc(placeId).delete();
    } catch (e) {
      throw Exception('Failed to delete place: $e');
    }
  }
}



