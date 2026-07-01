import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/app_drawer.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/favorites_service.dart';
import '../services/places_service.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import 'place_details_screen.dart';

class RecommendationsScreen extends StatefulWidget {
  final String? initialCategory;
  
  const RecommendationsScreen({super.key, this.initialCategory});

  @override
  State<RecommendationsScreen> createState() => _RecommendationsScreenState();
}

class _RecommendationsScreenState extends State<RecommendationsScreen> {
  String _searchQuery = '';
  late String _activeCategory;
  int _selectedIndex = 3; // Recommendations is selected
  final FavoritesService _favoritesService = FavoritesService();
  final PlacesService _placesService = PlacesService();
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  Set<String> _favoriteIds = {};
  Position? _currentPosition;
  
  WeatherData? _weatherData;
  LocationData? _locationData;
  bool _isLoadingWeather = true;
  bool _isLoadingLocation = true;
  
  // Filter variables
  String _sortBy = 'rating';
  RangeValues _priceRange = const RangeValues(0, 500);
  double _distanceRange = 50.0;
  String _timePreference = 'any';

  List<CategoryInfo> _getCategories(BuildContext context, List<Place> places) {
    final loc = AppLocalizations.of(context);
    final isArabic = loc?.locale.languageCode == 'ar';
    
    return [
      CategoryInfo(
        id: 'all',
        name: loc?.translate('all') ?? 'الكل',
        count: places.length,
      ),
      CategoryInfo(
        id: 'restaurants',
        name: loc?.translate('restaurants') ?? 'مطاعم',
        count: places.where((p) {
          final cat = isArabic ? p.category : p.categoryEn;
          return cat.contains('مطعم') || cat.toLowerCase().contains('restaurant');
        }).length,
      ),
      CategoryInfo(
        id: 'landmarks',
        name: loc?.translate('landmarks') ?? 'معالم',
        count: places.where((p) {
          final cat = isArabic ? p.category : p.categoryEn;
          return cat.contains('معلم') || cat.toLowerCase().contains('landmark');
        }).length,
      ),
      CategoryInfo(
        id: 'events',
        name: loc?.translate('events') ?? 'فعاليات',
        count: places.where((p) {
          final cat = isArabic ? p.category : p.categoryEn;
          return cat.contains('فعالية') || cat.toLowerCase().contains('event');
        }).length,
      ),
      CategoryInfo(
        id: 'shopping',
        name: loc?.translate('shopping') ?? 'تسوق',
        count: places.where((p) {
          final cat = isArabic ? p.category : p.categoryEn;
          return cat.contains('تسوق') || cat.toLowerCase().contains('shopping');
        }).length,
      ),
      CategoryInfo(
        id: 'cafes',
        name: loc?.translate('cafes') ?? 'مقاهي',
        count: places.where((p) {
          final cat = isArabic ? p.category : p.categoryEn;
          return cat.contains('مقهى') || cat.toLowerCase().contains('cafe');
        }).length,
      ),
    ];
  }
  
  double _calculateDistance(Place place) {
    if (_currentPosition == null) {
      // If no location, return a default distance (0) so all places pass distance filter
      return 0.0;
    }
    try {
      return Geolocator.distanceBetween(
        _currentPosition!.latitude,
        _currentPosition!.longitude,
        place.latitude,
        place.longitude,
      ) / 1000; // Convert to kilometers
    } catch (e) {
      print('Error calculating distance: $e');
      return 0.0;
    }
  }

  List<Place> _filterPlaces(List<Place> places) {
    final loc = AppLocalizations.of(context);
    final isArabic = loc?.locale.languageCode == 'ar';
    
    var filtered = places.where((place) {
      final placeName = isArabic ? place.name : place.nameEn;
      final placeDesc = isArabic ? place.description : place.descriptionEn;
      final placeCategory = isArabic ? place.category : place.categoryEn;
      
      final matchesSearch = _searchQuery.isEmpty ||
          placeName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          placeDesc.toLowerCase().contains(_searchQuery.toLowerCase());
      
      final matchesCategory = _activeCategory == 'all' ||
          (_activeCategory == 'restaurants' && (placeCategory.contains('مطعم') || placeCategory.toLowerCase().contains('restaurant'))) ||
          (_activeCategory == 'landmarks' && (placeCategory.contains('معلم') || placeCategory.toLowerCase().contains('landmark'))) ||
          (_activeCategory == 'events' && (placeCategory.contains('فعالية') || placeCategory.toLowerCase().contains('event'))) ||
          (_activeCategory == 'shopping' && (placeCategory.contains('تسوق') || placeCategory.toLowerCase().contains('shopping'))) ||
          (_activeCategory == 'cafes' && (placeCategory.contains('مقهى') || placeCategory.toLowerCase().contains('cafe')));
      
      // If no location available, skip distance filter
      final matchesDistance = _currentPosition == null || _calculateDistance(place) <= _distanceRange;
      
      return matchesSearch && matchesCategory && matchesDistance;
    }).toList();
    
    // Sort
    filtered.sort((a, b) {
      switch (_sortBy) {
        case 'rating':
          return b.rating.compareTo(a.rating);
        case 'distance':
          final distA = _calculateDistance(a);
          final distB = _calculateDistance(b);
          return distA.compareTo(distB);
        case 'reviews':
          return b.reviews.compareTo(a.reviews);
        default:
          return 0;
      }
    });
    
    return filtered;
  }

  List<Place> _getRecommendedPlaces(List<Place> places) {
    return places.where((p) => p.isFeatured).toList();
  }

  List<Place> _getOtherPlaces(List<Place> places) {
    return places.where((p) => !p.isFeatured).toList();
  }

  Future<void> _toggleFavorite(String placeId) async {
    try {
      final newStatus = await _favoritesService.toggleFavorite(placeId);
      if (mounted) {
        setState(() {
          if (newStatus) {
            _favoriteIds.add(placeId);
          } else {
            _favoriteIds.remove(placeId);
          }
        });
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

  Color _getCategoryColor(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('معلم') || lowerCategory.contains('landmark')) return Colors.blue;
    if (lowerCategory.contains('فعالية') || lowerCategory.contains('event')) return Colors.purple;
    if (lowerCategory.contains('مطعم') || lowerCategory.contains('restaurant')) return Colors.orange;
    if (lowerCategory.contains('تسوق') || lowerCategory.contains('shopping')) return Colors.green;
    if (lowerCategory.contains('مقهى') || lowerCategory.contains('cafe')) return Colors.brown;
    return Colors.grey;
  }

  @override
  void initState() {
    super.initState();
    // Set initial category from arguments or default to 'all'
    _activeCategory = widget.initialCategory ?? 'all';
    _loadFavorites();
    _loadWeatherAndLocation();
    // Set a larger default distance range to show more places
    _distanceRange = 1000.0; // 1000 km to show all places by default
  }
  
  Future<void> _loadWeatherAndLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _isLoadingWeather = true;
    });

    try {
      final location = await _locationService.getCurrentLocation();
      if (!mounted) return;

      if (location != null) {
        setState(() {
          _locationData = location;
          _currentPosition = Position(
            latitude: location.latitude,
            longitude: location.longitude,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
          _isLoadingLocation = false;
        });

        final weather = await _weatherService.getWeatherByCoordinates(
          location.latitude,
          location.longitude,
        );

        if (!mounted) return;
        setState(() {
          _weatherData = weather;
          _isLoadingWeather = false;
        });
      } else {
        // Fallback to default city if location not available
        setState(() {
          _isLoadingLocation = false;
        });
        final defaultCity = 'Riyadh';
        final weather = await _weatherService.getWeatherByCity(defaultCity);
        if (!mounted) return;
        setState(() {
          _weatherData = weather;
          _isLoadingWeather = false;
        });
      }
    } catch (e) {
      print('Error loading weather/location: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingLocation = false;
        _isLoadingWeather = false;
      });
    }
  }

  void _loadFavorites() {
    _favoritesService.getFavoriteIds().listen((favoriteIds) {
      if (mounted) {
        setState(() {
          _favoriteIds = favoriteIds.toSet();
        });
      }
    });
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
                    // Header Section
                    _buildHeaderSection(),
                    
                    // Search Bar
                    _buildSearchBar(),
                    
                    // Places List
                    StreamBuilder<List<Place>>(
                      stream: _placesService.getAllPlaces(limit: 100),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }
                        
                        if (snapshot.hasError) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Text(
                                'Error: ${snapshot.error}',
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          );
                        }
                        
                        final allPlaces = snapshot.data ?? [];
                        print('Total places from Firebase: ${allPlaces.length}');
                        
                        final filteredPlaces = _filterPlaces(allPlaces);
                        print('Filtered places: ${filteredPlaces.length}');
                        
                        final recommendedPlaces = _getRecommendedPlaces(filteredPlaces);
                        final otherPlaces = _getOtherPlaces(filteredPlaces);
                        
                        print('Recommended places: ${recommendedPlaces.length}');
                        print('Other places: ${otherPlaces.length}');
                        
                        // If no places at all, show message
                        if (allPlaces.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(32.0),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
                                  const SizedBox(height: 16),
                                  Text(
                                    AppLocalizations.of(context)?.translate('no_places') ?? 'لا توجد أماكن متاحة',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }
                        
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Category Chips
                            _buildCategoryChips(allPlaces),
                            
                            // Recommended Section
                            if (recommendedPlaces.isNotEmpty) _buildRecommendedSection(recommendedPlaces),
                            
                            // Other Places Section
                            if (otherPlaces.isNotEmpty) _buildOtherPlacesSection(otherPlaces),
                            
                            // No Results
                            if (filteredPlaces.isEmpty && allPlaces.isNotEmpty) _buildNoResults(),
                          ],
                        );
                      },
                    ),
                    
                    const SizedBox(height: 80), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
        );
      },
    );
  }

  Widget _buildTopBar() {
    final loc = AppLocalizations.of(context);
    final cityLabel = _locationData?.city ?? (loc?.translate('your_location') ?? 'موقعك');
    final tempText = _isLoadingWeather
        ? '...'
        : _weatherData != null
            ? '${_weatherData!.temperature.toStringAsFixed(0)}°C'
            : '--';
    final weatherIcon = _isLoadingWeather
        ? ''
        : _weatherData != null
            ? WeatherService.getWeatherIcon(_weatherData!.icon)
            : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Location & Weather
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.wb_sunny, size: 16, color: Colors.orange),
                const SizedBox(width: 4),
                Text(
                  '$tempText ${weatherIcon.isNotEmpty ? weatherIcon : ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.location_on, size: 16, color: Colors.blue),
                Flexible(
                  child: Text(
                    cityLabel,
                    style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // Title
          Expanded(
            child: Center(
              child: Text(
                AppLocalizations.of(context)?.translate('recommendations') ?? 'التوصيات',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          
          // Balance spacer
          const SizedBox(width: 80),
        ],
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppLocalizations.of(context)?.translate('smart_recommendations') ?? 'التوصيات الذكية',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              _showFiltersDialog();
            },
            icon: const Icon(Icons.tune, size: 18),
            label: Text(AppLocalizations.of(context)?.translate('filters') ?? 'فلاتر'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 1,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
          });
        },
        decoration: InputDecoration(
          hintText: AppLocalizations.of(context)?.translate('search_place_activity') ?? 'ابحث عن مكان أو نشاط...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          filled: true,
          fillColor: Colors.grey[50],
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildCategoryChips(List<Place> places) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      height: 50,
      color: Colors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _getCategories(context, places).length,
        itemBuilder: (context, index) {
          final category = _getCategories(context, places)[index];
          final isActive = _activeCategory == category.id;
          
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: FilterChip(
              label: Text('${category.name} (${category.count})'),
              selected: isActive,
              onSelected: (selected) {
                setState(() {
                  _activeCategory = category.id;
                });
              },
              selectedColor: const Color(0xFF030213),
              labelStyle: TextStyle(
                color: isActive ? Colors.white : Colors.grey[700],
                fontSize: 13,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          );
        },
      ),
    );
  }

  void _showFiltersDialog() {
    String tempSortBy = _sortBy;
    RangeValues tempPriceRange = _priceRange;
    double tempDistanceRange = _distanceRange;
    String tempTimePreference = _timePreference;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)?.translate('filters') ?? 'الفلاتر',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Sort By
                      Text(
                        AppLocalizations.of(context)?.translate('sort_by') ?? 'ترتيب حسب',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: tempSortBy,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            items: [
                              DropdownMenuItem(
                                value: 'rating',
                                child: Text(AppLocalizations.of(context)?.translate('rating') ?? 'التقييم'),
                              ),
                              DropdownMenuItem(
                                value: 'distance',
                                child: Text(AppLocalizations.of(context)?.translate('distance') ?? 'المسافة'),
                              ),
                              DropdownMenuItem(
                                value: 'price',
                                child: Text(AppLocalizations.of(context)?.translate('price') ?? 'السعر'),
                              ),
                              DropdownMenuItem(
                                value: 'reviews',
                                child: Text(AppLocalizations.of(context)?.translate('reviews_count') ?? 'عدد المراجعات'),
                              ),
                            ],
                            onChanged: (value) {
                              setModalState(() {
                                tempSortBy = value!;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Price Range
                      Text(
                        '${AppLocalizations.of(context)?.translate('price_range') ?? 'السعر'}: ${tempPriceRange.start.toInt()} - ${tempPriceRange.end.toInt()} ${AppLocalizations.of(context)?.translate('riyal') ?? 'ريال'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      RangeSlider(
                        values: tempPriceRange,
                        min: 0,
                        max: 500,
                        divisions: 50,
                        labels: RangeLabels(
                          '${tempPriceRange.start.toInt()}',
                          '${tempPriceRange.end.toInt()}',
                        ),
                        onChanged: (values) {
                          setModalState(() {
                            tempPriceRange = values;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Distance Range
                      Text(
                        '${AppLocalizations.of(context)?.translate('distance_range') ?? 'المسافة'}: ${AppLocalizations.of(context)?.translate('up_to') ?? 'حتى'} ${tempDistanceRange.toInt()} ${AppLocalizations.of(context)?.translate('km') ?? 'كم'}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Slider(
                        value: tempDistanceRange,
                        min: 0,
                        max: 50,
                        divisions: 50,
                        label: '${tempDistanceRange.toInt()} كم',
                        onChanged: (value) {
                          setModalState(() {
                            tempDistanceRange = value;
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Time Preference
                      Text(
                        AppLocalizations.of(context)?.translate('visit_time_preference') ?? 'وقت الزيارة المفضل',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: tempTimePreference,
                            isExpanded: true,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            items: [
                              DropdownMenuItem(
                                value: 'any',
                                child: Text(AppLocalizations.of(context)?.translate('any_time') ?? 'أي وقت'),
                              ),
                              DropdownMenuItem(
                                value: 'morning',
                                child: Text(AppLocalizations.of(context)?.translate('morning') ?? 'صباحي'),
                              ),
                              DropdownMenuItem(
                                value: 'afternoon',
                                child: Text(AppLocalizations.of(context)?.translate('afternoon') ?? 'ظهيرة'),
                              ),
                              DropdownMenuItem(
                                value: 'evening',
                                child: Text(AppLocalizations.of(context)?.translate('evening') ?? 'مسائي'),
                              ),
                            ],
                            onChanged: (value) {
                              setModalState(() {
                                tempTimePreference = value!;
                              });
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              
              // Buttons
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      spreadRadius: 1,
                      blurRadius: 4,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setModalState(() {
                            tempSortBy = 'rating';
                            tempPriceRange = const RangeValues(0, 500);
                            tempDistanceRange = 50.0;
                            tempTimePreference = 'any';
                          });
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(AppLocalizations.of(context)?.translate('reset') ?? 'إعادة تعيين'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _sortBy = tempSortBy;
                            _priceRange = tempPriceRange;
                            _distanceRange = tempDistanceRange;
                            _timePreference = tempTimePreference;
                          });
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF030213),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: Text(AppLocalizations.of(context)?.translate('apply') ?? 'تطبيق'),
                      ),
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

  Widget _buildRecommendedSection(List<Place> places) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Text(
                AppLocalizations.of(context)?.translate('recommended_for_you') ?? 'موصى بها لك',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'AI',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.translate('recommended_description') ?? 'بناءً على تفضيلاتك وسلوك الاستخدام، إليك أفضل الاقتراحات',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          ...places.map((place) => _buildPlaceCard(place)),
        ],
      ),
    );
  }

  Widget _buildOtherPlacesSection(List<Place> places) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)?.translate('more_places') ?? 'المزيد من الأماكن',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Text(
                '${places.length} ${AppLocalizations.of(context)?.translate('place_count') ?? 'مكان'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...places.map((place) => _buildPlaceCard(place)),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(Place place) {
    final loc = AppLocalizations.of(context);
    final isArabic = loc?.locale.languageCode == 'ar';
    final isFavorite = _favoriteIds.contains(place.id);
    final categoryColor = _getCategoryColor(isArabic ? place.category : place.categoryEn);
    final distance = _calculateDistance(place);
    final placeName = isArabic ? place.name : place.nameEn;
    final placeDesc = isArabic ? place.description : place.descriptionEn;
    final placeCategory = isArabic ? place.category : place.categoryEn;
    
    return InkWell(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => PlaceDetailsScreen(
              placeId: place.id,
              name: placeName,
              description: placeDesc,
              category: placeCategory,
              rating: place.rating,
              reviews: place.reviews,
              distance: distance,
              duration: 2, // Default duration
              imageUrl: place.imageUrl,
              imageUrls: place.imageUrls,
              latitude: place.latitude,
              longitude: place.longitude,
              address: isArabic ? (place.address ?? '') : (place.addressEn ?? place.address ?? ''),
              hours: place.hours ?? '',
              phone: place.phone ?? '',
              website: place.website ?? '',
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).shadowColor.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          // Image
          Stack(
            children: [
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  color: Colors.grey[200],
                ),
                child: (place.imageUrl != null || (place.imageUrls != null && place.imageUrls!.isNotEmpty))
                    ? ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                        child: Image.network(
                          place.imageUrl ?? place.imageUrls!.first,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: 200,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    categoryColor.withOpacity(0.7),
                                    categoryColor,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: Icon(
                                  Icons.landscape,
                                  size: 60,
                                  color: Colors.white.withOpacity(0.5),
                                ),
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    categoryColor.withOpacity(0.7),
                                    categoryColor,
                                  ],
                                ),
                              ),
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              categoryColor.withOpacity(0.7),
                              categoryColor,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.landscape,
                            size: 60,
                            color: Colors.white.withOpacity(0.5),
                          ),
                        ),
                      ),
              ),
              // Category Tag
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: categoryColor,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    placeCategory,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              // Action Icons
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Colors.white,
                      ),
                      onPressed: () => _toggleFavorite(place.id),
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      onPressed: () {
                        // TODO: Open camera/gallery
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  placeName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                
                // Description
                Text(
                  placeDesc,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // Details
                Row(
                  children: [
                    // Rating
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          '${place.rating} (${place.reviews})',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Distance
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.blue),
                        const SizedBox(width: 4),
                        Text(
                          '${distance.toStringAsFixed(1)} ${loc?.translate('km') ?? 'كم'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Duration
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 16, color: Colors.orange),
                        const SizedBox(width: 4),
                        Text(
                          '2-3 ${loc?.translate('hours') ?? 'ساعات'}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.search, size: 32, color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          Text(
            AppLocalizations.of(context)?.translate('no_results') ?? 'لا توجد نتائج',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context)?.translate('try_adjusting_search') ?? 'جرب تعديل معايير البحث أو الفلاتر',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchQuery = '';
                _activeCategory = 'all';
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF030213),
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context)?.translate('clear_all_filters') ?? 'مسح جميع الفلاتر'),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
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
              Navigator.of(context).pushReplacementNamed('/home');
              break;
            case 1:
              Navigator.of(context).pushReplacementNamed('/map');
              break;
            case 2:
              Navigator.of(context).pushReplacementNamed('/trips');
              break;
            case 3:
              // Already on recommendations
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

class CategoryInfo {
  final String id;
  final String name;
  final int count;

  CategoryInfo({
    required this.id,
    required this.name,
    required this.count,
  });
}

