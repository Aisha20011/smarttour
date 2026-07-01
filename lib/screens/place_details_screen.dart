import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/favorites_service.dart';

class PlaceDetailsScreen extends StatefulWidget {
  final String placeId;
  final String name;
  final String description;
  final String category;
  final double rating;
  final int reviews;
  final double distance;
  final int duration;
  final String? imageUrl;
  final List<String>? imageUrls;
  final double? latitude;
  final double? longitude;
  final String address;
  final String hours;
  final String? phone;
  final String? website;

  const PlaceDetailsScreen({
    super.key,
    required this.placeId,
    required this.name,
    required this.description,
    required this.category,
    required this.rating,
    required this.reviews,
    required this.distance,
    required this.duration,
    this.imageUrl,
    this.imageUrls,
    this.latitude,
    this.longitude,
    required this.address,
    required this.hours,
    this.phone,
    this.website,
  });

  @override
  State<PlaceDetailsScreen> createState() => _PlaceDetailsScreenState();
}

class _PlaceDetailsScreenState extends State<PlaceDetailsScreen> {
  int _currentImageIndex = 0;
  bool _isFavorite = false;
  final PageController _pageController = PageController();
  final FavoritesService _favoritesService = FavoritesService();

  Color _getCategoryColor(String category) {
    if (category.contains('معلم')) return Colors.blue;
    if (category.contains('فعالية')) return Colors.purple;
    if (category.contains('مطعم')) return Colors.orange;
    if (category.contains('تسوق')) return Colors.green;
    if (category.contains('مقهى')) return Colors.brown;
    return Colors.grey;
  }

  int _getImageCount() {
    int count = 0;
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      count++;
    }
    if (widget.imageUrls != null && widget.imageUrls!.isNotEmpty) {
      count += widget.imageUrls!.length;
    }
    return count > 0 ? count : 1; // At least 1 for fallback
  }

  String? _getImageUrl(int index) {
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      if (index == 0) {
        return widget.imageUrl;
      }
      index--; // Adjust index for imageUrls
    }
    if (widget.imageUrls != null && widget.imageUrls!.isNotEmpty) {
      if (index < widget.imageUrls!.length) {
        return widget.imageUrls![index];
      }
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _checkFavoriteStatus();
  }

  Future<void> _checkFavoriteStatus() async {
    final isFav = await _favoritesService.isFavorite(widget.placeId);
    if (mounted) {
      setState(() {
        _isFavorite = isFav;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      final newStatus = await _favoritesService.toggleFavorite(widget.placeId);
      if (mounted) {
        setState(() {
          _isFavorite = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              newStatus
                  ? (AppLocalizations.of(context)?.translate('added_to_favorites') ??
                      'تم إضافة المكان إلى المفضلة')
                  : (AppLocalizations.of(context)?.translate('removed_from_favorites') ??
                      'تم إزالة المكان من المفضلة'),
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        final categoryColor = _getCategoryColor(widget.category);
        final loc = AppLocalizations.of(context);
        final isArabic = loc?.locale.languageCode == 'ar';
        
        return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: Icon(
                    _isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: _isFavorite ? Colors.red : Colors.white,
                  ),
                  onPressed: _toggleFavorite,
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: Colors.white),
                  onPressed: () {
                    // TODO: Share place
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Images with PageView
                  PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentImageIndex = index;
                      });
                    },
                    itemCount: _getImageCount(),
                    itemBuilder: (context, index) {
                      final imageUrl = _getImageUrl(index);
                      return Container(
                        decoration: BoxDecoration(
                          gradient: imageUrl == null
                              ? LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    categoryColor.withOpacity(0.7),
                                    categoryColor,
                                  ],
                                )
                              : null,
                          image: imageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(imageUrl),
                                  fit: BoxFit.cover,
                                  onError: (exception, stackTrace) {
                                    // If image fails to load, show gradient
                                  },
                                )
                              : null,
                        ),
                        child: imageUrl == null
                            ? Center(
                                child: Icon(
                                  Icons.landscape,
                                  size: 120,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              )
                            : null,
                      );
                    },
                  ),
                  // Category Tag
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: categoryColor,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  // Image Indicators
                  if (_getImageCount() > 1)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_getImageCount(), (index) {
                          return Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentImageIndex == index
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.5),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and Rating
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        widget.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Rating and Distance
                      Row(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 20),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.rating}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '(${widget.reviews.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},')} ${loc?.translate('reviews') ?? 'تقييم'})',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Row(
                            children: [
                              const Icon(Icons.location_on, color: Colors.blue, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.distance} ${loc?.translate('km') ?? 'كم'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      
                      // Address
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.grey, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              widget.address,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Duration and Hours
                      Row(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.orange, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.duration}-${widget.duration + 1} ${loc?.translate('hours') ?? 'ساعات'}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 24),
                          Row(
                            children: [
                              const Icon(Icons.person, color: Colors.grey, size: 16),
                              const SizedBox(width: 4),
                              Text(
                                widget.hours,
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (widget.latitude != null && widget.longitude != null) {
                              Navigator.of(context).pushNamed(
                                '/map',
                                arguments: {
                                  'latitude': widget.latitude,
                                  'longitude': widget.longitude,
                                  'placeName': widget.name,
                                },
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    loc?.translate('location_not_available') ?? 'الموقع غير متاح',
                                  ),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.navigation, color: Colors.white),
                          label: Text(
                            loc?.translate('navigate') ?? 'التنقل',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF030213),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Open AR
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc?.translate('ar_mode') ?? 'واقع معزز'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.camera_alt),
                        label: Text(loc?.translate('ar_mode') ?? 'واقع معزز'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).cardColor,
                          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton.icon(
                        onPressed: () {
                          // TODO: Open audio guide
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(loc?.translate('audio_guide') ?? 'دليل صوتي'),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow),
                        label: Text(loc?.translate('audio_guide') ?? 'دليل صوتي'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).cardColor,
                          foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                
                // Add to Trip Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Add to trip
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(loc?.translate('add_to_trip') ?? 'أضف إلى خطة الرحلة'),
                          ),
                        );
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(loc?.translate('add_to_trip') ?? 'أضف إلى خطة الرحلة'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // About Section
                _buildSection(
                  title: loc?.translate('about_place') ?? 'عن هذا المكان',
                  content: Text(
                    widget.description,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ),

                // History Section
                _buildSection(
                  title: loc?.translate('history') ?? 'التاريخ',
                  content: Text(
                    loc?.translate('history_description') ?? 'تم بناء المسجد في السنة الأولى للهجرة، وكان في البداية منزل النبي محمد صلى الله عليه وسلم. تم توسيعه عدة مرات عبر التاريخ ليصبح أحد أكبر المساجد في العالم.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      height: 1.6,
                    ),
                  ),
                ),

                // Facilities Section
                _buildSection(
                  title: loc?.translate('facilities') ?? 'المرافق',
                  content: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildFacilityChip(loc?.translate('air_conditioning') ?? 'مكيف الهواء'),
                      _buildFacilityChip(loc?.translate('parking') ?? 'مقاعد السيارات'),
                      _buildFacilityChip(loc?.translate('wheelchair_accessible') ?? 'امكانية الوصول للكراسي المتحركة'),
                      _buildFacilityChip(loc?.translate('restrooms') ?? 'دورات المياه'),
                      _buildFacilityChip(loc?.translate('prayer_area') ?? 'مكان للصلاة'),
                    ],
                  ),
                ),

                // Visit Tips Section
                _buildSection(
                  title: loc?.translate('visit_tips') ?? 'نصائح للزيارة',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTipItem(loc?.translate('best_visit_time') ?? 'أفضل أوقات الزيارة من بعد صلاة الفجر حتى شروق الشمس'),
                      _buildTipItem(loc?.translate('dress_code_tip') ?? 'ينصح بارتداء ملابس محتشمة ومناسبة'),
                      _buildTipItem(loc?.translate('booking_tip') ?? 'يفضل الحجز المسبق خلال موسم الحج والعمرة'),
                    ],
                  ),
                ),

                // Contact Section
                if (widget.phone != null || widget.website != null)
                  _buildSection(
                    title: loc?.translate('contact_info') ?? 'معلومات الاتصال',
                    content: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (widget.phone != null)
                          _buildContactItem(
                            icon: Icons.phone,
                            text: widget.phone!,
                          ),
                        if (widget.website != null) ...[
                          const SizedBox(height: 12),
                          _buildContactItem(
                            icon: Icons.language,
                            text: widget.website!,
                          ),
                        ],
                      ],
                    ),
                  ),

                // Reviews Section
                _buildSection(
                  title: loc?.translate('reviews_ratings') ?? 'التقييمات والمراجعات',
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/reviews',
                                arguments: {
                                  'placeId': widget.placeId,
                                  'placeName': widget.name,
                                  'rating': widget.rating,
                                  'totalReviews': widget.reviews,
                                },
                              );
                            },
                            child: Text(
                              loc?.translate('view_all') ?? 'عرض الكل',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _buildReviewItem(
                        name: 'أحمد محمد',
                        rating: 5,
                        date: '١٤٤٥/٧/٣ هـ',
                        comment: 'مكان رائع ومقدس، تجربة لا تُنسى',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
        );
      },
    );
  }

  Widget _buildSection({required String title, required Widget content}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          content,
        ],
      ),
    );
  }

  Widget _buildFacilityChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, left: 8),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: Colors.black87,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.black87,
                height: 1.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactItem({required IconData icon, required String text}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewItem({
    required String name,
    required int rating,
    required String date,
    String? comment,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.grey),
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
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (comment != null) ...[
            const SizedBox(height: 12),
            Text(
              comment,
              style: const TextStyle(
                fontSize: 14,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}


