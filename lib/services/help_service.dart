import 'package:cloud_firestore/cloud_firestore.dart';

class FAQ {
  final String id;
  final String questionAr;
  final String questionEn;
  final String answerAr;
  final String answerEn;
  final String category;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  FAQ({
    required this.id,
    required this.questionAr,
    required this.questionEn,
    required this.answerAr,
    required this.answerEn,
    required this.category,
    required this.order,
    required this.createdAt,
    required this.updatedAt,
  });

  factory FAQ.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FAQ(
      id: doc.id,
      questionAr: data['questionAr'] ?? '',
      questionEn: data['questionEn'] ?? '',
      answerAr: data['answerAr'] ?? '',
      answerEn: data['answerEn'] ?? '',
      category: data['category'] ?? 'general',
      order: data['order'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'questionAr': questionAr,
      'questionEn': questionEn,
      'answerAr': answerAr,
      'answerEn': answerEn,
      'category': category,
      'order': order,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class HelpService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get all FAQs
  Stream<List<FAQ>> getFAQs() {
    return _firestore
        .collection('faqs')
        .snapshots()
        .map((snapshot) {
      final faqs = snapshot.docs.map((doc) => FAQ.fromFirestore(doc)).toList();
      // Sort by order then createdAt in memory
      faqs.sort((a, b) {
        final orderCompare = a.order.compareTo(b.order);
        if (orderCompare != 0) return orderCompare;
        return a.createdAt.compareTo(b.createdAt);
      });
      return faqs;
    });
  }

  // Get FAQs by category
  Stream<List<FAQ>> getFAQsByCategory(String category) {
    return _firestore
        .collection('faqs')
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) {
      final faqs = snapshot.docs.map((doc) => FAQ.fromFirestore(doc)).toList();
      // Sort by order then createdAt in memory
      faqs.sort((a, b) {
        final orderCompare = a.order.compareTo(b.order);
        if (orderCompare != 0) return orderCompare;
        return a.createdAt.compareTo(b.createdAt);
      });
      return faqs;
    });
  }

  // Get FAQ by ID
  Future<FAQ?> getFAQById(String id) async {
    try {
      final doc = await _firestore.collection('faqs').doc(id).get();
      if (doc.exists) {
        return FAQ.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error getting FAQ: $e');
      return null;
    }
  }

  // Search FAQs
  Future<List<FAQ>> searchFAQs(String query, String language) async {
    try {
      final snapshot = await _firestore.collection('faqs').get();
      final allFAQs = snapshot.docs.map((doc) => FAQ.fromFirestore(doc)).toList();
      
      final queryLower = query.toLowerCase();
      return allFAQs.where((faq) {
        final question = language == 'ar' ? faq.questionAr : faq.questionEn;
        final answer = language == 'ar' ? faq.answerAr : faq.answerEn;
        return question.toLowerCase().contains(queryLower) ||
               answer.toLowerCase().contains(queryLower);
      }).toList();
    } catch (e) {
      print('Error searching FAQs: $e');
      return [];
    }
  }
}


