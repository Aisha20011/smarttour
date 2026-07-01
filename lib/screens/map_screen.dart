import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import '../widgets/app_drawer.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/places_service.dart';
import 'place_details_screen.dart';

class MapScreen extends StatefulWidget {
  final double? targetLatitude;
  final double? targetLongitude;
  final String? targetPlaceName;

  const MapScreen({
    super.key,
    this.targetLatitude,
    this.targetLongitude,
    this.targetPlaceName,
  });

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  final PlacesService _placesService = PlacesService();
  String _searchQuery = '';
  String _activeFilter = 'all';
  Position? _currentPosition;
  final List<MapPlace> _nearbyPlaces = [];
  final Map<String, MapPlace> _nearbyByCategory = {}; // category -> nearest place
  List<Place> _allPlaces = [];
  bool _isLoadingPlaces = true;
  int _selectedIndex = 1; // Map is selected

  // Default location (Riyadh)
  static const double _defaultLat = 24.7136;
  static const double _defaultLng = 46.6753;

  List<MapFilter> _getFilters(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isArabic = loc?.locale.languageCode == 'ar';
    
    return [
      MapFilter(id: 'all', name: loc?.translate('all') ?? 'الكل', count: _allPlaces.length),
      MapFilter(
        id: 'landmarks',
        name: loc?.translate('landmarks') ?? 'المعالم',
        count: _allPlaces.where((p) {
          final cat = isArabic ? p.category : p.categoryEn;
          return cat.toLowerCase().contains('landmark') || 
                 cat.contains('معلم') || 
                 cat.toLowerCase().contains('monument');
        }).length,
      ),
      MapFilter(
        id: 'restaurants',
        name: loc?.translate('restaurants') ?? 'المطاعم',
        count: _allPlaces.where((p) {
          final cat = isArabic ? p.category : p.categoryEn;
          return cat.contains('مطعم') || 
                 cat.toLowerCase().contains('restaurant') ||
                 cat.contains('مقهى') ||
                 cat.toLowerCase().contains('cafe');
        }).length,
      ),
      MapFilter(
        id: 'shopping',
        name: loc?.translate('shopping') ?? 'التسوق',
        count: _allPlaces.where((p) {
          final cat = isArabic ? p.category : p.categoryEn;
          return cat.contains('تسوق') || 
                 cat.toLowerCase().contains('shopping') ||
                 cat.toLowerCase().contains('mall');
        }).length,
      ),
      MapFilter(
        id: 'events',
        name: loc?.translate('events') ?? 'الفعاليات',
        count: _allPlaces.where((p) {
          final cat = isArabic ? p.category : p.categoryEn;
          return cat.contains('فعالية') || 
                 cat.toLowerCase().contains('event') ||
                 cat.toLowerCase().contains('festival');
        }).length,
      ),
    ];
  }

  @override
  void initState() {
    super.initState();
    _loadPlaces();
    if (widget.targetLatitude != null && widget.targetLongitude != null) {
      // Navigate to target location
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _navigateToTarget();
      });
    } else {
      _getCurrentLocation();
    }
  }

  void _navigateToTarget() {
    if (widget.targetLatitude != null && widget.targetLongitude != null) {
      final targetLocation = LatLng(widget.targetLatitude!, widget.targetLongitude!);
      _mapController.move(targetLocation, 15.0);
      setState(() {
        _currentPosition = Position(
          latitude: widget.targetLatitude!,
          longitude: widget.targetLongitude!,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
      });
    }
  }

  Future<void> _loadPlaces() async {
    try {
      setState(() {
        _isLoadingPlaces = true;
      });

      // Get all places from Firebase
      final placesStream = _placesService.getAllPlaces(limit: 100);
      await for (final places in placesStream) {
        if (mounted) {
          setState(() {
            _allPlaces = places;
            _isLoadingPlaces = false;
          });
          // Calculate nearby places after loading
          _calculateNearbyPlaces();
        }
        break; // Get first batch
      }
    } catch (e) {
      print('Error loading places: $e');
      if (mounted) {
        setState(() {
          _isLoadingPlaces = false;
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Use default location
        _currentPosition = Position(
          latitude: _defaultLat,
          longitude: _defaultLng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        _calculateNearbyPlaces();
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          // Use default location
          _currentPosition = Position(
            latitude: _defaultLat,
            longitude: _defaultLng,
            timestamp: DateTime.now(),
            accuracy: 0,
            altitude: 0,
            altitudeAccuracy: 0,
            heading: 0,
            headingAccuracy: 0,
            speed: 0,
            speedAccuracy: 0,
          );
          _calculateNearbyPlaces();
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Use default location
        _currentPosition = Position(
          latitude: _defaultLat,
          longitude: _defaultLng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          altitudeAccuracy: 0,
          heading: 0,
          headingAccuracy: 0,
          speed: 0,
          speedAccuracy: 0,
        );
        _calculateNearbyPlaces();
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );

      setState(() {
        _currentPosition = position;
      });

      _calculateNearbyPlaces();

      // Move map to current location
      if (mounted) {
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          14.0,
        );
      }
    } catch (e) {
      // Use default location
      _currentPosition = Position(
        latitude: _defaultLat,
        longitude: _defaultLng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
      _calculateNearbyPlaces();
    }
  }

  void _calculateNearbyPlaces() {
    if (_allPlaces.isEmpty || _currentPosition == null) return;

    final currentLat = _currentPosition!.latitude;
    final currentLng = _currentPosition!.longitude;
    final isArabic = AppLocalizations.of(context)?.locale.languageCode == 'ar';

    // Calculate distance for each place
    final placesWithDistance = _allPlaces.map((place) {
      final distance = Geolocator.distanceBetween(
        currentLat,
        currentLng,
        place.latitude,
        place.longitude,
      );
      return {
        'place': place,
        'distance': distance,
      };
    }).toList();

    // Sort by distance
    placesWithDistance.sort((a, b) => 
      (a['distance'] as double).compareTo(b['distance'] as double));
    
    // Find nearest place for each category
    final Map<String, MapPlace> nearbyByCategory = {};
    final List<MapPlace> allNearby = [];
    
    for (var item in placesWithDistance) {
      final place = item['place'] as Place;
      final distance = item['distance'] as double;
      final category = isArabic ? place.category : place.categoryEn;
      
      final mapPlace = MapPlace(
        id: place.id,
        name: isArabic ? place.name : place.nameEn,
        category: category,
        lat: place.latitude,
        lng: place.longitude,
        rating: place.rating,
        distance: _formatDistance(distance),
        color: _getCategoryColor(place.category),
      );
      
      allNearby.add(mapPlace);
      
      // Determine category type
      String? categoryType;
      if (category.toLowerCase().contains('landmark') || 
          category.contains('معلم') || 
          category.toLowerCase().contains('monument')) {
        categoryType = 'landmarks';
      } else if (category.contains('مطعم') || 
                 category.toLowerCase().contains('restaurant') ||
                 category.contains('مقهى') ||
                 category.toLowerCase().contains('cafe')) {
        categoryType = 'restaurants';
      } else if (category.contains('تسوق') || 
                 category.toLowerCase().contains('shopping') ||
                 category.toLowerCase().contains('mall')) {
        categoryType = 'shopping';
      } else if (category.contains('فعالية') || 
                 category.toLowerCase().contains('event') ||
                 category.toLowerCase().contains('festival')) {
        categoryType = 'events';
      }
      
      // Store nearest place for each category
      if (categoryType != null && !nearbyByCategory.containsKey(categoryType)) {
        nearbyByCategory[categoryType] = mapPlace;
      }
    }
    
    setState(() {
      _nearbyPlaces.clear();
      _nearbyPlaces.addAll(allNearby.take(10)); // Keep top 10 for general list
      _nearbyByCategory.clear();
      _nearbyByCategory.addAll(nearbyByCategory);
    });
  }

  Color _getCategoryColor(String category) {
    if (category.contains('مطعم') || category.toLowerCase().contains('restaurant')) {
      return Colors.orange;
    } else if (category.contains('معلم') || category.toLowerCase().contains('landmark')) {
      return Colors.blue;
    } else if (category.contains('فعالية') || category.toLowerCase().contains('event')) {
      return Colors.purple;
    } else if (category.contains('تسوق') || category.toLowerCase().contains('shopping')) {
      return Colors.green;
    }
    return Colors.grey;
  }

  String _formatDistance(double distanceInMeters) {
    if (distanceInMeters < 1000) {
      return '${distanceInMeters.round()} م';
    } else {
      return '${(distanceInMeters / 1000).toStringAsFixed(1)} كم';
    }
  }

  List<MapPlace> get _filteredPlaces {
    final isArabic = AppLocalizations.of(context)?.locale.languageCode == 'ar';
    
    return _allPlaces.where((place) {
      final name = isArabic ? place.name : place.nameEn;
      final category = isArabic ? place.category : place.categoryEn;
      
      bool matchesSearch = _searchQuery.isEmpty ||
          name.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesFilter = _activeFilter == 'all' ||
          (_activeFilter == 'landmarks' && (
            category.toLowerCase().contains('landmark') || 
            category.contains('معلم') || 
            category.toLowerCase().contains('monument')
          )) ||
          (_activeFilter == 'restaurants' && (
            category.contains('مطعم') || 
            category.toLowerCase().contains('restaurant') ||
            category.contains('مقهى') ||
            category.toLowerCase().contains('cafe')
          )) ||
          (_activeFilter == 'shopping' && (
            category.contains('تسوق') || 
            category.toLowerCase().contains('shopping') ||
            category.toLowerCase().contains('mall')
          )) ||
          (_activeFilter == 'events' && (
            category.contains('فعالية') || 
            category.toLowerCase().contains('event') ||
            category.toLowerCase().contains('festival')
          ));
      
      return matchesSearch && matchesFilter;
    }).map((place) {
      final isArabic = AppLocalizations.of(context)?.locale.languageCode == 'ar';
      final currentLat = _currentPosition?.latitude ?? _defaultLat;
      final currentLng = _currentPosition?.longitude ?? _defaultLng;
      final distance = Geolocator.distanceBetween(
        currentLat,
        currentLng,
        place.latitude,
        place.longitude,
      );
      
      return MapPlace(
        id: place.id,
        name: isArabic ? place.name : place.nameEn,
        category: isArabic ? place.category : place.categoryEn,
        lat: place.latitude,
        lng: place.longitude,
        rating: place.rating,
        distance: _formatDistance(distance),
        color: _getCategoryColor(place.category),
      );
    }).toList();
  }

  Color _getMarkerColor(Color color) {
    return color;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        final currentLat = widget.targetLatitude ?? _currentPosition?.latitude ?? _defaultLat;
        final currentLng = widget.targetLongitude ?? _currentPosition?.longitude ?? _defaultLng;
        final loc = AppLocalizations.of(context);
        final isArabic = loc?.locale.languageCode == 'ar';

        return Scaffold(
      drawer: const AppDrawer(),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              decoration: InputDecoration(
                hintText: loc?.translate('search_place_map') ?? 'ابحث عن مكان...',
                hintTextDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                filled: true,
                fillColor: Colors.grey[50],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _getFilters(context).map((filter) {
                  bool isActive = _activeFilter == filter.id;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: FilterChip(
                      label: Text(
                        '${filter.name} (${filter.count})',
                        style: TextStyle(
                          color: isActive ? Colors.white : Colors.grey[700],
                          fontSize: 12,
                        ),
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      ),
                      selected: isActive,
                      onSelected: (selected) {
                        setState(() {
                          _activeFilter = filter.id;
                        });
                      },
                      selectedColor: const Color(0xFF030213),
                      backgroundColor: Theme.of(context).cardColor,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Map
          Expanded(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(currentLat, currentLng),
                    initialZoom: widget.targetLatitude != null && widget.targetLongitude != null ? 15.0 : 13.0,
                    minZoom: 5.0,
                    maxZoom: 18.0,
                  ),
                  children: [
                    // OpenStreetMap Tile Layer
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.smarttour',
                    ),
                    // Markers Layer
                    MarkerLayer(
                      markers: [
                        // Target Location Marker (if navigating to a place)
                        if (widget.targetLatitude != null && widget.targetLongitude != null)
                          Marker(
                            point: LatLng(widget.targetLatitude!, widget.targetLongitude!),
                            width: 60,
                            height: 60,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.red.withOpacity(0.5),
                                    spreadRadius: 4,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.place,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ),
                        // Current Location Marker (only if not navigating to target)
                        if (widget.targetLatitude == null || widget.targetLongitude == null)
                          Marker(
                            point: LatLng(currentLat, currentLng),
                            width: 50,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.5),
                                    spreadRadius: 4,
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.my_location,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        // Places Markers
                        ..._filteredPlaces.map((place) {
                          return Marker(
                            point: LatLng(place.lat, place.lng),
                            width: 40,
                            height: 40,
                            child: GestureDetector(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => PlaceDetailsScreen(
                                      placeId: place.id,
                                      name: place.name,
                                      description: 'وصف تفصيلي عن ${place.name}',
                                      category: place.category,
                                      rating: 4.5,
                                      reviews: 1234,
                                      distance: double.tryParse(place.distance.replaceAll(' كم', '').replaceAll('km', '').trim()) ?? 0.0,
                                      duration: 2,
                                      address: 'المدينة المنورة، المملكة العربية السعودية',
                                      hours: 'مفتوح 24 ساعة',
                                      phone: '+966 14 123 4567',
                                      website: 'www.example.com',
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _getMarkerColor(place.color),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 2),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.3),
                                      spreadRadius: 2,
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.location_on,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ],
                ),

                // Map Controls
                Positioned(
                  top: 16,
                  left: 16,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.3),
                              spreadRadius: 1,
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.add),
                              onPressed: () {
                                _mapController.move(
                                  _mapController.camera.center,
                                  _mapController.camera.zoom + 1,
                                );
                              },
                            ),
                            const Divider(height: 1),
                            IconButton(
                              icon: const Icon(Icons.remove),
                              onPressed: () {
                                _mapController.move(
                                  _mapController.camera.center,
                                  _mapController.camera.zoom - 1,
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Current Location Button
                Positioned(
                  bottom: 200,
                  left: 16,
                  child: FloatingActionButton(
                    mini: true,
                    backgroundColor: const Color(0xFF030213),
                    onPressed: _getCurrentLocation,
                    child: const Icon(Icons.my_location, color: Colors.white),
                  ),
                ),

                // Filter Summary
                if (_activeFilter != 'all')
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey.withOpacity(0.3),
                            spreadRadius: 1,
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: Color(0xFF030213),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${_filteredPlaces.length} ${_filteredPlaces.length == 1 ? (loc?.translate('place_count') ?? 'مكان') : (loc?.translate('places_count') ?? 'أماكن')}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Nearby Places by Category
          Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    loc?.translate('nearby_places') ?? 'الأماكن القريبة',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                  ),
                ),
                // Category sections
                if (_nearbyByCategory.containsKey('landmarks'))
                  _buildCategorySection(
                    context,
                    loc?.translate('landmarks') ?? 'المعالم',
                    Icons.location_on,
                    Colors.blue,
                    _nearbyByCategory['landmarks']!,
                    isArabic,
                  ),
                if (_nearbyByCategory.containsKey('restaurants'))
                  _buildCategorySection(
                    context,
                    loc?.translate('restaurants') ?? 'المطاعم',
                    Icons.restaurant,
                    Colors.orange,
                    _nearbyByCategory['restaurants']!,
                    isArabic,
                  ),
                if (_nearbyByCategory.containsKey('shopping'))
                  _buildCategorySection(
                    context,
                    loc?.translate('shopping') ?? 'التسوق',
                    Icons.shopping_bag,
                    Colors.green,
                    _nearbyByCategory['shopping']!,
                    isArabic,
                  ),
                if (_nearbyByCategory.containsKey('events'))
                  _buildCategorySection(
                    context,
                    loc?.translate('events') ?? 'الفعاليات',
                    Icons.calendar_today,
                    Colors.purple,
                    _nearbyByCategory['events']!,
                    isArabic,
                  ),
                if (_nearbyByCategory.isEmpty && !_isLoadingPlaces)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        loc?.translate('no_nearby_places') ?? 'لا توجد أماكن قريبة',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      ),
                    ),
                  ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
        );
      },
    );
  }

  Widget _buildCategorySection(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    MapPlace place,
    bool isArabic,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
                textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPlaceCard(place, isCompact: true),
        ],
      ),
    );
  }

  Widget _buildPlaceCard(MapPlace place, {bool isCompact = false}) {
    final isArabic = AppLocalizations.of(context)?.locale.languageCode == 'ar';
    
    return InkWell(
      onTap: () {
        // Get place details from Firebase
        _placesService.getPlaceById(place.id).then((placeData) {
          if (placeData != null && mounted) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PlaceDetailsScreen(
                  placeId: place.id,
                  name: isArabic ? placeData.name : placeData.nameEn,
                  description: isArabic ? placeData.description : placeData.descriptionEn,
                  category: isArabic ? placeData.category : placeData.categoryEn,
                  rating: placeData.rating,
                  reviews: placeData.reviews,
                  distance: double.tryParse(place.distance.replaceAll(' كم', '').replaceAll('km', '').replaceAll(' م', '').replaceAll('m', '').trim()) ?? 0.0,
                  duration: 2,
                  address: isArabic ? (placeData.address ?? '') : (placeData.addressEn ?? ''),
                  hours: placeData.hours ?? '',
                  phone: placeData.phone ?? '',
                  website: placeData.website ?? '',
                ),
              ),
            );
          }
        });
      },
      child: Container(
        width: isCompact ? double.infinity : 280,
        margin: EdgeInsets.only(left: isCompact ? 0 : 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: isCompact ? [] : [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.amber[700]),
                      const SizedBox(width: 4),
                      Text(
                        place.rating.toStringAsFixed(1),
                        style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        place.distance,
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (!isCompact)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: place.color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  place.category,
                  style: TextStyle(
                    fontSize: 10,
                    color: place.color,
                    fontWeight: FontWeight.w600,
                  ),
                  textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                ),
              ),
          ],
        ),
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
              // Already on map
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

class MapPlace {
  final String id;
  final String name;
  final String category;
  final double lat;
  final double lng;
  final double rating;
  final String distance;
  final Color color;

  MapPlace({
    required this.id,
    required this.name,
    required this.category,
    required this.lat,
    required this.lng,
    required this.rating,
    required this.distance,
    required this.color,
  });
}

class MapPlaceWithDistance {
  final MapPlace place;
  final double distanceInMeters;

  MapPlaceWithDistance({
    required this.place,
    required this.distanceInMeters,
  });
}

class MapFilter {
  final String id;
  final String name;
  final int count;

  MapFilter({
    required this.id,
    required this.name,
    required this.count,
  });
}
