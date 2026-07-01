import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/app_drawer.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/notification_service.dart';
import '../services/places_service.dart';
import 'place_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  final NotificationService _notificationService = NotificationService();
  final PlacesService _placesService = PlacesService();
  
  WeatherData? _weatherData;
  LocationData? _locationData;
  bool _isLoadingWeather = true;
  bool _isLoadingLocation = true;
  
  Map<String, int> _categoryCounts = {};
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _loadWeatherAndLocation();
    _loadCategoryCounts();
  }

  Future<void> _loadCategoryCounts() async {
    try {
      final counts = await _placesService.getCategoriesWithCounts();
      if (mounted) {
        setState(() {
          _categoryCounts = counts;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      print('Error loading category counts: $e');
      if (mounted) {
        setState(() {
          _isLoadingCategories = false;
        });
      }
    }
  }

  Future<void> _loadWeatherAndLocation() async {
    // Load location first
    setState(() {
      _isLoadingLocation = true;
    });

    try {
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        setState(() {
          _locationData = location;
          _isLoadingLocation = false;
        });

        // Load weather based on location
        setState(() {
          _isLoadingWeather = true;
        });

        final weather = await _weatherService.getWeatherByCoordinates(
          location.latitude,
          location.longitude,
        );

        if (weather != null) {
          setState(() {
            _weatherData = weather;
            _isLoadingWeather = false;
          });
        } else {
          // Try to get weather by city name
          final weatherByCity = await _weatherService.getWeatherByCity(location.city);
          if (weatherByCity != null) {
            setState(() {
              _weatherData = weatherByCity;
              _isLoadingWeather = false;
            });
          } else {
            setState(() {
              _isLoadingWeather = false;
            });
          }
        }
      } else {
        // If location fails, try default city (Riyadh)
        if (!mounted) return;
        
        setState(() {
          _isLoadingLocation = false;
          _isLoadingWeather = true;
        });

        final loc = AppLocalizations.of(context);
        final defaultCity = 'Riyadh';
        final weather = await _weatherService.getWeatherByCity(defaultCity);
        
        if (!mounted) return;
        
        if (weather != null) {
          setState(() {
            _weatherData = weather;
            _locationData = LocationData(
              latitude: 24.7136,
              longitude: 46.6753,
              city: loc?.translate('riyadh') ?? 'الرياض',
            );
            _isLoadingWeather = false;
          });
        } else {
          setState(() {
            _isLoadingWeather = false;
          });
        }
      }
    } catch (e) {
      print('Error loading weather and location: $e');
      setState(() {
        _isLoadingLocation = false;
        _isLoadingWeather = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        final loc = AppLocalizations.of(context);
        final isArabic = loc?.locale.languageCode == 'ar';
        
        return Scaffold(
      drawer: const AppDrawer(),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Bar
            _buildTopBar(),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Explore City Section
                    _buildExploreCitySection(),
                    
                    // Featured Places Section
                    _buildFeaturedPlacesSection(),
                    
                    // Quick Actions Section
                    _buildQuickActionsSection(),
                    
                    const SizedBox(height: 80), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Notifications & Search
          Row(
            children: [
              StreamBuilder<int>(
                stream: _notificationService.getUnreadCount(),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications_outlined, size: 24),
                        onPressed: () {
                          Navigator.of(context).pushNamed('/notifications');
                        },
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 16,
                              minHeight: 16,
                            ),
                            child: Text(
                              unreadCount > 9 ? '9+' : unreadCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.search, size: 24),
                onPressed: () {
                  // TODO: Navigate to search
                },
              ),
            ],
          ),
          
          // Center: Title, Weather, Location
          Column(
            children: [
              const Text(
                'SmartTour',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Weather
                  if (_isLoadingWeather)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
                      ),
                    )
                  else if (_weatherData != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          WeatherService.getWeatherIcon(_weatherData!.icon),
                          style: const TextStyle(fontSize: 14),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${_weatherData!.temperature.toStringAsFixed(0)}°C',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else
                    const Icon(Icons.wb_sunny, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  // Location
                  if (_isLoadingLocation)
                    const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    )
                  else
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.blue),
                        const SizedBox(width: 2),
                        Text(
                          _locationData?.city ?? AppLocalizations.of(context)?.translate('riyadh') ?? 'الرياض',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                          textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                              ? TextDirection.rtl 
                              : TextDirection.ltr,
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
          
          // Right: Menu
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu, size: 24),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExploreCitySection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.translate('explore_city') ?? 'استكشف المدينة',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                ? TextDirection.rtl 
                : TextDirection.ltr,
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _buildCategoryCard(
                AppLocalizations.of(context)?.translate('restaurants') ?? 'المطاعم',
                Icons.restaurant,
                Colors.green,
                _categoryCounts['مطعم']?.toString() ?? _categoryCounts['restaurant']?.toString(),
                'restaurants',
              ),
              _buildCategoryCard(
                AppLocalizations.of(context)?.translate('landmarks') ?? 'المعالم الأثرية',
                Icons.location_on,
                Colors.blue,
                _categoryCounts['معلم']?.toString() ?? _categoryCounts['landmark']?.toString(),
                'landmarks',
              ),
              _buildCategoryCard(
                AppLocalizations.of(context)?.translate('events') ?? 'الفعاليات',
                Icons.calendar_today,
                Colors.orange,
                null,
                'events',
              ),
              _buildCategoryCard(
                AppLocalizations.of(context)?.translate('shopping') ?? 'التسوق',
                Icons.shopping_bag,
                Colors.purple,
                _categoryCounts['تسوق']?.toString() ?? _categoryCounts['shopping']?.toString(),
                'shopping',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(String title, IconData icon, Color color, String? count, String categoryId) {
    return InkWell(
      onTap: () {
        Navigator.pushNamed(
          context,
          '/recommendations',
          arguments: categoryId,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child: count != null
                  ? Center(
                      child: Text(
                        count,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                            ? TextDirection.rtl 
                            : TextDirection.ltr,
                      ),
                    )
                  : Icon(icon, color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                  ? TextDirection.rtl 
                  : TextDirection.ltr,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedPlacesSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)?.translate('featured_places') ?? 'الأماكن المميزة',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                    ? TextDirection.rtl 
                    : TextDirection.ltr,
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    '/recommendations',
                    arguments: 'all',
                  );
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)?.translate('view_all') ?? 'عرض الكل',
                      style: const TextStyle(
                        color: Color(0xFF030213),
                        fontWeight: FontWeight.w500,
                      ),
                      textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                          ? TextDirection.rtl 
                          : TextDirection.ltr,
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_back_ios,
                      size: 16,
                      color: Color(0xFF030213),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<Place>>(
            stream: _placesService.getFeaturedPlaces(limit: 10),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SizedBox(
                  height: 250,
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (snapshot.hasError) {
                final isArabic = AppLocalizations.of(context)?.locale.languageCode == 'ar';
                return SizedBox(
                  height: 250,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)?.translate('error_loading_places') ?? 'حدث خطأ في تحميل الأماكن',
                          style: TextStyle(color: Colors.grey[600]),
                          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final places = snapshot.data ?? [];
              final isArabic = AppLocalizations.of(context)?.locale.languageCode == 'ar';

              if (places.isEmpty) {
                return SizedBox(
                  height: 250,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.location_off, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          AppLocalizations.of(context)?.translate('no_featured_places') ?? 'لا توجد أماكن مميزة',
                          style: TextStyle(color: Colors.grey[600]),
                          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SizedBox(
                height: 250,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: places.length,
                  itemBuilder: (context, index) {
                    final place = places[index];
                    return _buildPlaceCardFromData(place, isArabic);
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceCardFromData(Place place, bool isArabic) {
    final name = isArabic ? place.name : place.nameEn;
    final description = isArabic ? place.description : place.descriptionEn;
    final category = isArabic ? place.category : place.categoryEn;
    final address = isArabic ? place.address : place.addressEn;

    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => PlaceDetailsScreen(
                placeId: place.id,
                name: name,
                description: description,
                category: category,
                rating: place.rating,
                reviews: place.reviews,
                distance: 0, // Will be calculated if needed
                duration: 0, // Will be calculated if needed
                imageUrl: place.imageUrl,
                imageUrls: place.imageUrls,
                latitude: place.latitude,
                longitude: place.longitude,
                address: address ?? '',
                hours: place.hours ?? '',
                phone: place.phone ?? '',
                website: place.website ?? '',
              ),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Image
              Stack(
                children: [
                  Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      gradient: place.imageUrl == null
                          ? LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.blue[300]!,
                                Colors.blue[600]!,
                              ],
                            )
                          : null,
                      image: place.imageUrl != null
                          ? DecorationImage(
                              image: NetworkImage(place.imageUrl!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: place.imageUrl == null
                        ? Center(
                            child: Icon(
                              _getCategoryIcon(place.category),
                              size: 60,
                              color: Colors.white.withOpacity(0.8),
                            ),
                          )
                        : null,
                  ),
                  // Tag
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey[800]!.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        category,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      ),
                    ),
                  ),
                  // Icons
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.favorite_border,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Colors.amber),
                        const SizedBox(width: 3),
                        Text(
                          place.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${place.reviews})',
                          style: TextStyle(
                            fontSize: 10,
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
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    if (category.contains('مطعم') || category.contains('restaurant')) {
      return Icons.restaurant;
    } else if (category.contains('معلم') || category.contains('landmark')) {
      return Icons.location_on;
    } else if (category.contains('فعالية') || category.contains('event')) {
      return Icons.calendar_today;
    } else if (category.contains('تسوق') || category.contains('shopping')) {
      return Icons.shopping_bag;
    }
    return Icons.place;
  }

  Widget _buildInfoChip(IconData icon, String text, String? subText) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: Colors.blue[700]),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
          textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
              ? TextDirection.rtl 
              : TextDirection.ltr,
        ),
        if (subText != null) ...[
          Text(
            subText,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black87,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildQuickActionsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.translate('quick_actions') ?? 'إجراءات سريعة',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                ? TextDirection.rtl 
                : TextDirection.ltr,
          ),
          const SizedBox(height: 16),
          _buildQuickActionButton(
            context,
            AppLocalizations.of(context)?.translate('plan_trip') ?? 'خطط رحلتك',
            AppLocalizations.of(context)?.translate('plan_trip_subtitle') ?? 'إنشاء جدول سياحي مخصص',
            Icons.calendar_today,
            Colors.blue,
            () {
              Navigator.pushNamed(context, '/trips');
            },
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            context,
            AppLocalizations.of(context)?.translate('offline_mode') ?? 'الوضع دون اتصال',
            AppLocalizations.of(context)?.translate('offline_mode_subtitle') ?? 'حفظ الخرائط والمعلومات',
            Icons.location_on,
            Colors.green,
            () {
              Navigator.pushNamed(context, '/offline');
            },
          ),
          const SizedBox(height: 12),
          _buildQuickActionButton(
            context,
            AppLocalizations.of(context)?.translate('live_updates') ?? 'التحديثات المباشرة',
            AppLocalizations.of(context)?.translate('live_updates_subtitle') ?? 'الطقس والفعاليات والمواصلات',
            Icons.trending_up,
            Colors.purple,
            () {
              Navigator.pushNamed(context, '/live_updates');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.8)],
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 20,
            ),
            Expanded(
              child: Row(
                children: [
                  Icon(icon, color: Colors.white, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                              ? TextDirection.rtl 
                              : TextDirection.ltr,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 12,
                          ),
                          textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                              ? TextDirection.rtl 
                              : TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) {
          setState(() {
            _selectedIndex = index;
          });
          switch (index) {
            case 0:
              // Already on home
              break;
            case 1:
              Navigator.of(context).pushReplacementNamed('/map');
              break;
            case 2:
              Navigator.of(context).pushReplacementNamed('/trips');
              break;
            case 3:
              Navigator.of(context).pushReplacementNamed('/recommendations');
              break;
            case 4:
              Navigator.of(context).pushReplacementNamed('/profile');
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color(0xFF030213),
        unselectedItemColor: Colors.grey,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home),
            label: AppLocalizations.of(context)?.translate('home') ?? 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.map),
            label: AppLocalizations.of(context)?.translate('map') ?? 'الخريطة',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.calendar_today),
            label: AppLocalizations.of(context)?.translate('trips') ?? 'الرحلات',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.trending_up),
            label: AppLocalizations.of(context)?.translate('recommendations') ?? 'التوصيات',
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person),
            label: AppLocalizations.of(context)?.translate('profile') ?? 'حسابي',
          ),
        ],
      ),
    );
  }
}

