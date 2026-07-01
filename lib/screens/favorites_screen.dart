import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../widgets/app_drawer.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/favorites_service.dart';
import '../services/places_service.dart';
import 'place_details_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FavoritesService _favoritesService = FavoritesService();
  final PlacesService _placesService = PlacesService();
  String _searchQuery = '';
  String _activeFilter = 'all';

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        final loc = AppLocalizations.of(context);
        final isArabic = loc?.locale.languageCode == 'ar';

        return Scaffold(
          drawer: const AppDrawer(),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              loc?.translate('favorites') ?? 'المفضلة',
              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  // Search functionality can be added here
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).cardColor,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: loc?.translate('search_favorites') ?? 'ابحث في المفضلة...',
                    hintTextDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
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

              // Filter Chips
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                height: 50,
                color: Theme.of(context).cardColor,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _getFilters(context).length,
                  itemBuilder: (context, index) {
                    final filter = _getFilters(context)[index];
                    final isActive = _activeFilter == filter.id;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text('${filter.name} (${filter.count})'),
                        selected: isActive,
                        onSelected: (selected) {
                          setState(() {
                            _activeFilter = filter.id;
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
              ),

              // Favorites List
              Expanded(
                child: StreamBuilder<List<Place>>(
                  stream: _favoritesService.getFavoritePlaces(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                        ),
                      );
                    }

                    final allFavorites = snapshot.data ?? [];
                    final filteredFavorites = _filterFavorites(allFavorites, isArabic);

                    if (filteredFavorites.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite_border,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? (loc?.translate('no_favorites_found') ?? 'لا توجد نتائج')
                                  : (loc?.translate('no_favorites') ?? 'لا توجد أماكن مفضلة'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                loc?.translate('add_favorites_hint') ?? 'أضف الأماكن المفضلة من صفحات الأماكن',
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                                textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredFavorites.length,
                      itemBuilder: (context, index) {
                        final place = filteredFavorites[index];
                        return _buildPlaceCard(place, isArabic);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Place> _filterFavorites(List<Place> favorites, bool isArabic) {
    return favorites.where((place) {
      final name = isArabic ? place.name : place.nameEn;
      final category = isArabic ? place.category : place.categoryEn;

      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          category.toLowerCase().contains(_searchQuery.toLowerCase());

      // Category filter
      bool matchesCategory = _activeFilter == 'all';
      if (!matchesCategory) {
        if (_activeFilter == 'landmarks') {
          matchesCategory = category.toLowerCase().contains('landmark') ||
              category.contains('معلم') ||
              category.toLowerCase().contains('monument');
        } else if (_activeFilter == 'restaurants') {
          matchesCategory = category.contains('مطعم') ||
              category.toLowerCase().contains('restaurant') ||
              category.contains('مقهى') ||
              category.toLowerCase().contains('cafe');
        } else if (_activeFilter == 'shopping') {
          matchesCategory = category.contains('تسوق') ||
              category.toLowerCase().contains('shopping') ||
              category.toLowerCase().contains('mall');
        } else if (_activeFilter == 'events') {
          matchesCategory = category.contains('فعالية') ||
              category.toLowerCase().contains('event') ||
              category.toLowerCase().contains('festival');
        }
      }

      return matchesSearch && matchesCategory;
    }).toList();
  }

  List<FilterInfo> _getFilters(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isArabic = loc?.locale.languageCode == 'ar';

    // We'll get counts from stream, for now use placeholders
    return [
      FilterInfo(
        id: 'all',
        name: loc?.translate('all') ?? 'الكل',
        count: 0, // Will be updated from stream
      ),
      FilterInfo(
        id: 'landmarks',
        name: loc?.translate('landmarks') ?? 'المعالم',
        count: 0,
      ),
      FilterInfo(
        id: 'restaurants',
        name: loc?.translate('restaurants') ?? 'المطاعم',
        count: 0,
      ),
      FilterInfo(
        id: 'shopping',
        name: loc?.translate('shopping') ?? 'التسوق',
        count: 0,
      ),
      FilterInfo(
        id: 'events',
        name: loc?.translate('events') ?? 'الفعاليات',
        count: 0,
      ),
    ];
  }

  Widget _buildPlaceCard(Place place, bool isArabic) {
    final name = isArabic ? place.name : place.nameEn;
    final description = isArabic ? place.description : place.descriptionEn;
    final category = isArabic ? place.category : place.categoryEn;
    final address = isArabic ? place.address : place.addressEn;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
                distance: 0,
                duration: 0,
                address: address ?? '',
                hours: place.hours ?? '',
                phone: place.phone ?? '',
                website: place.website ?? '',
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  gradient: place.imageUrl == null
                      ? LinearGradient(
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
                    ? Icon(
                        Icons.place,
                        size: 40,
                        color: Colors.white.withOpacity(0.8),
                      )
                    : null,
              ),
              const SizedBox(width: 16),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      category,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                      textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text(
                          place.rating.toStringAsFixed(1),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '(${place.reviews})',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Remove button
              IconButton(
                icon: const Icon(Icons.favorite, color: Colors.red),
                onPressed: () async {
                  try {
                    await _favoritesService.removeFromFavorites(place.id);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            AppLocalizations.of(context)?.translate('removed_from_favorites') ??
                                'تم إزالة المكان من المفضلة',
                          ),
                          backgroundColor: Colors.green,
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
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class FilterInfo {
  final String id;
  final String name;
  final int count;

  FilterInfo({
    required this.id,
    required this.name,
    required this.count,
  });
}

