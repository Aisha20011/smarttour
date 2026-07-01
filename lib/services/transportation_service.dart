import 'package:cloud_firestore/cloud_firestore.dart';

class TransportationInfo {
  final String id;
  final String type; // 'metro', 'bus', 'taxi', 'uber', 'careem'
  final String typeEn;
  final String route;
  final String routeEn;
  final String? status; // 'operational', 'delayed', 'suspended'
  final String? statusEn;
  final String? description;
  final String? descriptionEn;
  final DateTime? lastUpdate;
  final DateTime createdAt;
  final DateTime updatedAt;

  TransportationInfo({
    required this.id,
    required this.type,
    required this.typeEn,
    required this.route,
    required this.routeEn,
    this.status,
    this.statusEn,
    this.description,
    this.descriptionEn,
    this.lastUpdate,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'typeEn': typeEn,
      'route': route,
      'routeEn': routeEn,
      'status': status,
      'statusEn': statusEn,
      'description': description,
      'descriptionEn': descriptionEn,
      'lastUpdate': lastUpdate != null ? Timestamp.fromDate(lastUpdate!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory TransportationInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return TransportationInfo(
      id: doc.id,
      type: data['type'] ?? '',
      typeEn: data['typeEn'] ?? data['type'] ?? '',
      route: data['route'] ?? '',
      routeEn: data['routeEn'] ?? data['route'] ?? '',
      status: data['status'],
      statusEn: data['statusEn'],
      description: data['description'],
      descriptionEn: data['descriptionEn'],
      lastUpdate: (data['lastUpdate'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class TransportationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all transportation updates
  Stream<List<TransportationInfo>> getTransportationUpdates({int limit = 20}) {
    return _firestore
        .collection('transportation')
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TransportationInfo.fromFirestore(doc))
          .toList();
    });
  }

  // Get transportation by type
  Stream<List<TransportationInfo>> getTransportationByType(
    String type, {
    int limit = 10,
  }) {
    return _firestore
        .collection('transportation')
        .where('type', isEqualTo: type)
        .orderBy('updatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TransportationInfo.fromFirestore(doc))
          .toList();
    });
  }

  // Create transportation update
  Future<String> createTransportationUpdate(
      TransportationInfo transportation) async {
    try {
      final docRef =
          await _firestore.collection('transportation').add(transportation.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create transportation update: $e');
    }
  }

  // Update transportation
  Future<void> updateTransportation(
      String id, Map<String, dynamic> updates) async {
    try {
      updates['updatedAt'] = FieldValue.serverTimestamp();
      await _firestore.collection('transportation').doc(id).update(updates);
    } catch (e) {
      throw Exception('Failed to update transportation: $e');
    }
  }
}




