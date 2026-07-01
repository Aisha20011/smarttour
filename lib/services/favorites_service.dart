import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'places_service.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get current user ID
  String? get _userId => _auth.currentUser?.uid;

  // Add place to favorites
  Future<void> addToFavorites(String placeId) async {
    try {
      final userId = _userId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if already in favorites
      final favoriteDoc = await _firestore
          .collection('user_favorites')
          .doc(userId)
          .collection('places')
          .doc(placeId)
          .get();

      if (!favoriteDoc.exists) {
        // Get place data
        final placeDoc = await _firestore.collection('places').doc(placeId).get();
        if (placeDoc.exists) {
          final placeData = placeDoc.data()!;
          
          // Add to favorites
          await _firestore
              .collection('user_favorites')
              .doc(userId)
              .collection('places')
              .doc(placeId)
              .set({
            'placeId': placeId,
            'addedAt': FieldValue.serverTimestamp(),
            'name': placeData['name'],
            'nameEn': placeData['nameEn'],
            'category': placeData['category'],
            'categoryEn': placeData['categoryEn'],
            'rating': placeData['rating'],
            'imageUrl': placeData['imageUrl'],
          });
        }
      }
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  // Remove place from favorites
  Future<void> removeFromFavorites(String placeId) async {
    try {
      final userId = _userId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      await _firestore
          .collection('user_favorites')
          .doc(userId)
          .collection('places')
          .doc(placeId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  // Check if place is in favorites
  Future<bool> isFavorite(String placeId) async {
    try {
      final userId = _userId;
      if (userId == null) return false;

      final doc = await _firestore
          .collection('user_favorites')
          .doc(userId)
          .collection('places')
          .doc(placeId)
          .get();

      return doc.exists;
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }

  // Get stream of favorite place IDs
  Stream<List<String>> getFavoriteIds() {
    final userId = _userId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('user_favorites')
        .doc(userId)
        .collection('places')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }

  // Get favorite places with full details
  Stream<List<Place>> getFavoritePlaces() {
    final userId = _userId;
    if (userId == null) {
      return Stream.value([]);
    }

    return _firestore
        .collection('user_favorites')
        .doc(userId)
        .collection('places')
        .orderBy('addedAt', descending: true)
        .snapshots()
        .asyncMap((snapshot) async {
      final places = <Place>[];
      final placesService = PlacesService();

      for (var doc in snapshot.docs) {
        final placeId = doc.data()['placeId'] as String? ?? doc.id;
        final place = await placesService.getPlaceById(placeId);
        if (place != null) {
          places.add(place);
        }
      }

      return places;
    });
  }

  // Get favorite places count
  Future<int> getFavoritesCount() async {
    try {
      final userId = _userId;
      if (userId == null) return 0;

      final snapshot = await _firestore
          .collection('user_favorites')
          .doc(userId)
          .collection('places')
          .count()
          .get();

      return snapshot.count ?? 0;
    } catch (e) {
      print('Error getting favorites count: $e');
      return 0;
    }
  }

  // Toggle favorite status
  Future<bool> toggleFavorite(String placeId) async {
    try {
      final isFav = await isFavorite(placeId);
      if (isFav) {
        await removeFromFavorites(placeId);
        return false;
      } else {
        await addToFavorites(placeId);
        return true;
      }
    } catch (e) {
      throw Exception('Failed to toggle favorite: $e');
    }
  }
}




