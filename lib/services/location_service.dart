import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LocationData {
  final double latitude;
  final double longitude;
  final String city;
  final String? country;
  final String? address;

  LocationData({
    required this.latitude,
    required this.longitude,
    required this.city,
    this.country,
    this.address,
  });

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'city': city,
      'country': country,
      'address': address,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

class LocationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Check and request location permissions
  Future<bool> checkLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Get current location
  Future<LocationData?> getCurrentLocation() async {
    try {
      // Check permissions
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) {
        print('Location permission denied');
        return null;
      }

      // Get position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Get address from coordinates
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks[0];
        final city = place.locality ?? place.subAdministrativeArea ?? 'موقعك';
        final country = place.country;
        final address = place.street != null
            ? '${place.street}, ${place.locality ?? ''}'
            : place.locality;

        final locationData = LocationData(
          latitude: position.latitude,
          longitude: position.longitude,
          city: city,
          country: country,
          address: address,
        );

        // Save to Firebase
        await _saveLocationToFirestore(locationData);

        return locationData;
      }

      // If no placemarks, return location with coordinates only
      return LocationData(
        latitude: position.latitude,
        longitude: position.longitude,
        city: 'موقعك',
      );
    } catch (e) {
      print('Error getting location: $e');
      // Try to get cached location from Firebase
      return await _getCachedLocation();
    }
  }

  // Save location to Firestore
  Future<void> _saveLocationToFirestore(LocationData location) async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId != null) {
        await _firestore
            .collection('user_locations')
            .doc(userId)
            .set(location.toMap(), SetOptions(merge: true));
      }

      // Also save to general location cache
      await _firestore
          .collection('location_cache')
          .doc('current')
          .set(location.toMap(), SetOptions(merge: true));
    } catch (e) {
      print('Error saving location to Firestore: $e');
    }
  }

  // Get cached location from Firestore
  Future<LocationData?> _getCachedLocation() async {
    try {
      final doc = await _firestore
          .collection('location_cache')
          .doc('current')
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return LocationData(
          latitude: (data['latitude'] as num).toDouble(),
          longitude: (data['longitude'] as num).toDouble(),
          city: data['city'] ?? 'موقعك',
          country: data['country'],
          address: data['address'],
        );
      }
    } catch (e) {
      print('Error getting cached location: $e');
    }
    return null;
  }

  // Get user's last known location from Firestore
  Future<LocationData?> getUserLocation() async {
    try {
      final userId = _auth.currentUser?.uid;
      if (userId == null) return null;

      final doc = await _firestore
          .collection('user_locations')
          .doc(userId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        return LocationData(
          latitude: (data['latitude'] as num).toDouble(),
          longitude: (data['longitude'] as num).toDouble(),
          city: data['city'] ?? 'موقعك',
          country: data['country'],
          address: data['address'],
        );
      }
    } catch (e) {
      print('Error getting user location: $e');
    }
    return null;
  }
}





