import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import '../l10n/app_localizations.dart';

class ReviewsScreen extends StatelessWidget {
  final String placeId;
  final String placeName;
  final double rating;
  final int totalReviews;

  const ReviewsScreen({
    super.key,
    required this.placeId,
    required this.placeName,
    required this.rating,
    required this.totalReviews,
  });

  // Mock reviews data - In real app, this would come from Firebase
  List<Map<String, dynamic>> get _reviews {
    return [
      {
        'name': 'أحمد محمد',
        'rating': 5,
        'date': '١٤٤٥/٧/٣ هـ',
        'comment': 'مكان رائع ومقدس، تجربة لا تُنسى. الخدمة ممتازة والجو هادئ ومريح.',
      },
      {
        'name': 'فاطمة علي',
        'rating': 5,
        'date': '١٤٤٥/٧/٢ هـ',
        'comment': 'من أجمل الأماكن التي زرتها. أنصح الجميع بزيارته.',
      },
      {
        'name': 'محمد خالد',
        'rating': 4,
        'date': '١٤٤٥/٧/١ هـ',
        'comment': 'مكان جميل جداً، لكن يحتاج تحسين في الخدمات.',
      },
      {
        'name': 'سارة أحمد',
        'rating': 5,
        'date': '١٤٤٥/٦/٢٨ هـ',
        'comment': 'تجربة رائعة! المكان نظيف ومنظم والموظفون متعاونون.',
      },
      {
        'name': 'عبدالله سعيد',
        'rating': 4,
        'date': '١٤٤٥/٦/٢٧ هـ',
        'comment': 'مكان يستحق الزيارة. التصميم جميل والموقع ممتاز.',
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLocalizations.of(context)?.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.translate('reviews_ratings') ??
              'التقييمات والمراجعات',
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Place Name
            Text(
              placeName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textDirection:
                  isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
            const SizedBox(height: 8),

            // Rating Summary
            Row(
              children: [
                Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Text(
                  '($totalReviews ${AppLocalizations.of(context)?.translate('reviews') ?? 'تقييم'})',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textDirection:
                      isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Reviews List
            Text(
              AppLocalizations.of(context)?.translate('all_reviews') ??
                  'جميع المراجعات',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textDirection:
                  isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
            const SizedBox(height: 16),
            ..._reviews.map((review) => _buildReviewItem(
                  context,
                  review['name'] as String,
                  review['rating'] as int,
                  review['date'] as String,
                  review['comment'] as String?,
                  isArabic,
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem(
    BuildContext context,
    String name,
    int rating,
    String date,
    String? comment,
    bool isArabic,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.grey, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textDirection:
                          isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          return Icon(
                            Icons.star,
                            size: 16,
                            color: index < rating ? Colors.amber : Colors.grey[300],
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          textDirection: isArabic
                              ? ui.TextDirection.rtl
                              : ui.TextDirection.ltr,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment != null && comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
              textDirection:
                  isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
          ],
        ],
      ),
    );
  }
}




