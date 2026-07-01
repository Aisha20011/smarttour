import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/places_service.dart';
import '../services/trips_service.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  Database? _database;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Initialize database
  Future<void> initialize() async {
    if (_database != null) return;

    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, 'offline_data.db');

    _database = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        // Places table
        await db.execute('''
          CREATE TABLE places (
            id TEXT PRIMARY KEY,
            name TEXT,
            nameEn TEXT,
            description TEXT,
            descriptionEn TEXT,
            category TEXT,
            categoryEn TEXT,
            rating REAL,
            reviews INTEGER,
            latitude REAL,
            longitude REAL,
            address TEXT,
            addressEn TEXT,
            phone TEXT,
            website TEXT,
            hours TEXT,
            imageUrl TEXT,
            isFeatured INTEGER,
            createdAt TEXT,
            updatedAt TEXT,
            savedAt TEXT
          )
        ''');

        // Trips table
        await db.execute('''
          CREATE TABLE trips (
            id TEXT PRIMARY KEY,
            title TEXT,
            description TEXT,
            startDate TEXT,
            endDate TEXT,
            status TEXT,
            places TEXT,
            createdAt TEXT,
            updatedAt TEXT,
            savedAt TEXT
          )
        ''');

        // Offline data metadata
        await db.execute('''
          CREATE TABLE offline_metadata (
            key TEXT PRIMARY KEY,
            value TEXT,
            updatedAt TEXT
          )
        ''');
      },
    );
  }

  // Get database instance
  Future<Database> get database async {
    if (_database == null) {
      await initialize();
    }
    return _database!;
  }

  // Save places to local database
  Future<void> savePlacesToLocal(List<Place> places) async {
    try {
      final db = await database;
      final batch = db.batch();

      for (var place in places) {
        batch.insert(
          'places',
          {
            'id': place.id,
            'name': place.name,
            'nameEn': place.nameEn,
            'description': place.description,
            'descriptionEn': place.descriptionEn,
            'category': place.category,
            'categoryEn': place.categoryEn,
            'rating': place.rating,
            'reviews': place.reviews,
            'latitude': place.latitude,
            'longitude': place.longitude,
            'address': place.address,
            'addressEn': place.addressEn,
            'phone': place.phone,
            'website': place.website,
            'hours': place.hours,
            'imageUrl': place.imageUrl,
            'isFeatured': place.isFeatured ? 1 : 0,
            'createdAt': place.createdAt.toIso8601String(),
            'updatedAt': place.updatedAt.toIso8601String(),
            'savedAt': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      await _updateMetadata('places_last_sync', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving places to local: $e');
      rethrow;
    }
  }

  // Get places from local database
  Future<List<Place>> getPlacesFromLocal() async {
    try {
      final db = await database;
      final maps = await db.query('places', orderBy: 'savedAt DESC');

      return maps.map((map) {
        return Place(
          id: map['id'] as String,
          name: map['name'] as String,
          nameEn: map['nameEn'] as String,
          description: map['description'] as String,
          descriptionEn: map['descriptionEn'] as String,
          category: map['category'] as String,
          categoryEn: map['categoryEn'] as String,
          rating: map['rating'] as double,
          reviews: map['reviews'] as int,
          latitude: map['latitude'] as double,
          longitude: map['longitude'] as double,
          address: map['address'] as String?,
          addressEn: map['addressEn'] as String?,
          phone: map['phone'] as String?,
          website: map['website'] as String?,
          hours: map['hours'] as String?,
          imageUrl: map['imageUrl'] as String?,
          isFeatured: (map['isFeatured'] as int) == 1,
          createdAt: DateTime.parse(map['createdAt'] as String),
          updatedAt: DateTime.parse(map['updatedAt'] as String),
        );
      }).toList();
    } catch (e) {
      print('Error getting places from local: $e');
      return [];
    }
  }

  // Save trips to local database
  Future<void> saveTripsToLocal(List<Map<String, dynamic>> trips) async {
    try {
      final db = await database;
      final batch = db.batch();

      for (var trip in trips) {
        batch.insert(
          'trips',
          {
            'id': trip['id'],
            'title': trip['title'],
            'description': trip['description'],
            'startDate': trip['startDate']?.toIso8601String(),
            'endDate': trip['endDate']?.toIso8601String(),
            'status': trip['status'],
            'places': jsonEncode(trip['places'] ?? []),
            'createdAt': trip['createdAt']?.toIso8601String(),
            'updatedAt': trip['updatedAt']?.toIso8601String(),
            'savedAt': DateTime.now().toIso8601String(),
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }

      await batch.commit(noResult: true);
      await _updateMetadata('trips_last_sync', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error saving trips to local: $e');
      rethrow;
    }
  }

  // Get trips from local database
  Future<List<Map<String, dynamic>>> getTripsFromLocal() async {
    try {
      final db = await database;
      final maps = await db.query('trips', orderBy: 'savedAt DESC');

      return maps.map((map) {
        return {
          'id': map['id'] as String,
          'title': map['title'] as String,
          'description': map['description'] as String?,
          'startDate': map['startDate'] != null
              ? DateTime.parse(map['startDate'] as String)
              : null,
          'endDate': map['endDate'] != null
              ? DateTime.parse(map['endDate'] as String)
              : null,
          'status': map['status'] as String,
          'places': jsonDecode(map['places'] as String? ?? '[]'),
          'createdAt': map['createdAt'] != null
              ? DateTime.parse(map['createdAt'] as String)
              : DateTime.now(),
          'updatedAt': map['updatedAt'] != null
              ? DateTime.parse(map['updatedAt'] as String)
              : DateTime.now(),
        };
      }).toList();
    } catch (e) {
      print('Error getting trips from local: $e');
      return [];
    }
  }

  // Sync data from Firebase to local
  Future<void> syncFromFirebase() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return;

      // Sync places
      final placesSnapshot = await _firestore
          .collection('places')
          .where('isFeatured', isEqualTo: true)
          .limit(50)
          .get();

      final places = placesSnapshot.docs
          .map((doc) => Place.fromFirestore(doc))
          .toList();

      await savePlacesToLocal(places);

      // Sync trips
      final tripsSnapshot = await _firestore
          .collection('trips')
          .where('userId', isEqualTo: userId)
          .get();

      final trips = tripsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          ...data,
        };
      }).toList();

      await saveTripsToLocal(trips);

      await _updateMetadata('last_full_sync', DateTime.now().toIso8601String());
    } catch (e) {
      print('Error syncing from Firebase: $e');
      rethrow;
    }
  }

  // Get offline data statistics
  Future<Map<String, dynamic>> getOfflineStats() async {
    try {
      final db = await database;
      final placesCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM places'),
      ) ?? 0;
      final tripsCount = Sqflite.firstIntValue(
        await db.rawQuery('SELECT COUNT(*) FROM trips'),
      ) ?? 0;

      final placesLastSync = await _getMetadata('places_last_sync');
      final tripsLastSync = await _getMetadata('trips_last_sync');
      final lastFullSync = await _getMetadata('last_full_sync');

      return {
        'placesCount': placesCount,
        'tripsCount': tripsCount,
        'placesLastSync': placesLastSync,
        'tripsLastSync': tripsLastSync,
        'lastFullSync': lastFullSync,
      };
    } catch (e) {
      print('Error getting offline stats: $e');
      return {
        'placesCount': 0,
        'tripsCount': 0,
        'placesLastSync': null,
        'tripsLastSync': null,
        'lastFullSync': null,
      };
    }
  }

  // Clear all offline data
  Future<void> clearOfflineData() async {
    try {
      final db = await database;
      await db.delete('places');
      await db.delete('trips');
      await db.delete('offline_metadata');
      
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('offline_enabled');
    } catch (e) {
      print('Error clearing offline data: $e');
      rethrow;
    }
  }

  // Check if offline mode is enabled
  Future<bool> isOfflineModeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('offline_enabled') ?? false;
  }

  // Enable/disable offline mode
  Future<void> setOfflineModeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('offline_enabled', enabled);
    
    if (enabled) {
      // Auto-sync when enabling
      await syncFromFirebase();
    }
  }

  // Helper methods for metadata
  Future<void> _updateMetadata(String key, String value) async {
    final db = await database;
    await db.insert(
      'offline_metadata',
      {
        'key': key,
        'value': value,
        'updatedAt': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<String?> _getMetadata(String key) async {
    final db = await database;
    final result = await db.query(
      'offline_metadata',
      where: 'key = ?',
      whereArgs: [key],
    );
    if (result.isNotEmpty) {
      return result.first['value'] as String?;
    }
    return null;
  }

  // Get database size (approximate)
  Future<int> getDatabaseSize() async {
    try {
      final documentsDirectory = await getApplicationDocumentsDirectory();
      final path = join(documentsDirectory.path, 'offline_data.db');
      // Note: This is a simplified approach. For accurate size, use dart:io File operations
      return 0; // Placeholder - would need file system access
    } catch (e) {
      return 0;
    }
  }
}

