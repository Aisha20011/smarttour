import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../../services/places_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import 'add_edit_place_screen.dart';

class ManagePlacesScreen extends StatefulWidget {
  const ManagePlacesScreen({super.key});

  @override
  State<ManagePlacesScreen> createState() => _ManagePlacesScreenState();
}

class _ManagePlacesScreenState extends State<ManagePlacesScreen> {
  final PlacesService _placesService = PlacesService();
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        final loc = AppLocalizations.of(context);
        final isArabic = loc?.locale.languageCode == 'ar';

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              loc?.translate('manage_places') ?? 'إدارة الأماكن',
              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showAddPlaceDialog(context),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: loc?.translate('search') ?? 'بحث...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                ),
              ),

              // Places List
              Expanded(
                child: StreamBuilder<List<Place>>(
                  stream: _placesService.getAllPlaces(limit: 100),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }

                    final places = snapshot.data ?? [];
                    if (places.isEmpty) {
                      return Center(
                        child: Text(
                          loc?.translate('no_places') ?? 'لا توجد أماكن',
                          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: places.length,
                      itemBuilder: (context, index) {
                        final place = places[index];
                        return _buildPlaceCard(context, place, isArabic);
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

  Widget _buildPlaceCard(BuildContext context, Place place, bool isArabic) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Theme.of(context).cardColor,
      child: ListTile(
        leading: place.imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  place.imageUrl!,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey[300],
                      child: const Icon(Icons.place),
                    );
                  },
                ),
              )
            : Container(
                width: 60,
                height: 60,
                color: Colors.grey[300],
                child: const Icon(Icons.place),
              ),
        title: Text(
          isArabic ? place.name : place.nameEn,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
        subtitle: Text(
          isArabic ? place.category : place.categoryEn,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditPlaceDialog(context, place),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () => _showDeleteConfirmDialog(context, place),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddPlaceDialog(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddEditPlaceScreen(),
      ),
    ).then((result) {
      if (result == true) {
        // Refresh the list
        setState(() {});
      }
    });
  }

  void _showEditPlaceDialog(BuildContext context, Place place) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditPlaceScreen(place: place),
      ),
    ).then((result) {
      if (result == true) {
        // Refresh the list
        setState(() {});
      }
    });
  }

  void _showDeleteConfirmDialog(BuildContext context, Place place) {
    final loc = AppLocalizations.of(context);
    final isArabic = loc?.locale.languageCode == 'ar';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(loc?.translate('delete') ?? 'حذف'),
        content: Text(
          loc?.translate('delete_place_confirm') ?? 'هل أنت متأكد من حذف هذا المكان؟',
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc?.translate('cancel') ?? 'إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              try {
                await _placesService.deletePlace(place.id);
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(loc?.translate('place_deleted') ?? 'تم حذف المكان'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('حدث خطأ: $e'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              loc?.translate('delete') ?? 'حذف',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

