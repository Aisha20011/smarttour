import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:ui' as ui;
import '../../services/places_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';

class AddEditPlaceScreen extends StatefulWidget {
  final Place? place;

  const AddEditPlaceScreen({super.key, this.place});

  @override
  State<AddEditPlaceScreen> createState() => _AddEditPlaceScreenState();
}

class _AddEditPlaceScreenState extends State<AddEditPlaceScreen> {
  final _formKey = GlobalKey<FormState>();
  final PlacesService _placesService = PlacesService();
  
  // Controllers
  final _nameArController = TextEditingController();
  final _nameEnController = TextEditingController();
  final _descriptionArController = TextEditingController();
  final _descriptionEnController = TextEditingController();
  final _categoryController = TextEditingController();
  final _categoryEnController = TextEditingController();
  final _addressArController = TextEditingController();
  final _addressEnController = TextEditingController();
  final _phoneController = TextEditingController();
  final _websiteController = TextEditingController();
  final _hoursController = TextEditingController();
  final _visitHoursController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _audioGuideUrlController = TextEditingController();
  final _arImageUrlController = TextEditingController();
  
  // Location
  double _latitude = 24.7136; // Default to Riyadh
  double _longitude = 46.6753;
  LatLng? _selectedLocation;
  final MapController _mapController = MapController();
  
  // Image URLs list
  List<String> _imageUrls = [];
  final _imageUrlInputController = TextEditingController();
  
  // Rating and reviews
  double _rating = 0.0;
  int _reviews = 0;
  bool _isFeatured = false;
  
  bool _isLoading = false;
  
  // Categories
  final List<Map<String, String>> _categories = [
    {'ar': 'معالم', 'en': 'Landmarks'},
    {'ar': 'مطاعم', 'en': 'Restaurants'},
    {'ar': 'تسوق', 'en': 'Shopping'},
    {'ar': 'فعاليات', 'en': 'Events'},
    {'ar': 'ترفيه', 'en': 'Entertainment'},
    {'ar': 'فنادق', 'en': 'Hotels'},
  ];
  String? _selectedCategory;
  String? _selectedCategoryEn;

  @override
  void initState() {
    super.initState();
    if (widget.place != null) {
      _loadPlaceData();
    } else {
      _selectedLocation = LatLng(_latitude, _longitude);
    }
  }

  void _loadPlaceData() {
    final place = widget.place!;
    _nameArController.text = place.name;
    _nameEnController.text = place.nameEn;
    _descriptionArController.text = place.description;
    _descriptionEnController.text = place.descriptionEn;
    _categoryController.text = place.category;
    _categoryEnController.text = place.categoryEn;
    _selectedCategory = place.category;
    _selectedCategoryEn = place.categoryEn;
    _addressArController.text = place.address ?? '';
    _addressEnController.text = place.addressEn ?? '';
    _phoneController.text = place.phone ?? '';
    _websiteController.text = place.website ?? '';
    _hoursController.text = place.hours ?? '';
    _visitHoursController.text = place.visitHours ?? '';
    _imageUrlController.text = place.imageUrl ?? '';
    _audioGuideUrlController.text = place.audioGuideUrl ?? '';
    _arImageUrlController.text = place.arImageUrl ?? '';
    _imageUrls = place.imageUrls ?? [];
    _latitude = place.latitude;
    _longitude = place.longitude;
    _selectedLocation = LatLng(_latitude, _longitude);
    _rating = place.rating;
    _reviews = place.reviews;
    _isFeatured = place.isFeatured;
  }

  @override
  void dispose() {
    _nameArController.dispose();
    _nameEnController.dispose();
    _descriptionArController.dispose();
    _descriptionEnController.dispose();
    _categoryController.dispose();
    _categoryEnController.dispose();
    _addressArController.dispose();
    _addressEnController.dispose();
    _phoneController.dispose();
    _websiteController.dispose();
    _hoursController.dispose();
    _visitHoursController.dispose();
    _imageUrlController.dispose();
    _audioGuideUrlController.dispose();
    _arImageUrlController.dispose();
    _imageUrlInputController.dispose();
    super.dispose();
  }

  Future<void> _savePlace() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedLocation == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('يرجى اختيار الموقع على الخريطة')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final place = Place(
        id: widget.place?.id ?? '',
        name: _nameArController.text.trim(),
        nameEn: _nameEnController.text.trim(),
        description: _descriptionArController.text.trim(),
        descriptionEn: _descriptionEnController.text.trim(),
        category: _selectedCategory ?? _categoryController.text.trim(),
        categoryEn: _selectedCategoryEn ?? _categoryEnController.text.trim(),
        rating: _rating,
        reviews: _reviews,
        latitude: _selectedLocation!.latitude,
        longitude: _selectedLocation!.longitude,
        address: _addressArController.text.trim().isEmpty ? null : _addressArController.text.trim(),
        addressEn: _addressEnController.text.trim().isEmpty ? null : _addressEnController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        website: _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
        hours: _hoursController.text.trim().isEmpty ? null : _hoursController.text.trim(),
        visitHours: _visitHoursController.text.trim().isEmpty ? null : _visitHoursController.text.trim(),
        imageUrl: _imageUrlController.text.trim().isEmpty ? null : _imageUrlController.text.trim(),
        imageUrls: _imageUrls.isEmpty ? null : _imageUrls,
        audioGuideUrl: _audioGuideUrlController.text.trim().isEmpty ? null : _audioGuideUrlController.text.trim(),
        arImageUrl: _arImageUrlController.text.trim().isEmpty ? null : _arImageUrlController.text.trim(),
        isFeatured: _isFeatured,
        createdAt: widget.place?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.place != null) {
        await _placesService.updatePlace(place.id, place.toMap());
      } else {
        await _placesService.createPlace(place);
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.place != null ? 'تم تحديث المكان بنجاح' : 'تم إضافة المكان بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateAddressFromLocation(LatLng location) async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Get Arabic address using OpenStreetMap Nominatim API
      String? addressAr;
      try {
        final responseAr = await http.get(
          Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&accept-language=ar',
          ),
        ).timeout(const Duration(seconds: 5));

        if (responseAr.statusCode == 200) {
          final data = json.decode(responseAr.body);
          if (data['display_name'] != null) {
            addressAr = data['display_name'] as String;
          }
        }
      } catch (e) {
        print('Error getting Arabic address: $e');
      }

      // Get English address using OpenStreetMap Nominatim API
      String? addressEn;
      try {
        final responseEn = await http.get(
          Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=json&lat=${location.latitude}&lon=${location.longitude}&accept-language=en',
          ),
        ).timeout(const Duration(seconds: 5));

        if (responseEn.statusCode == 200) {
          final data = json.decode(responseEn.body);
          if (data['display_name'] != null) {
            addressEn = data['display_name'] as String;
          }
        }
      } catch (e) {
        print('Error getting English address: $e');
      }

      // Fallback to geocoding package if API fails
      if (addressAr == null || addressEn == null) {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          location.latitude,
          location.longitude,
        );

        if (placemarks.isNotEmpty) {
          final placemark = placemarks[0];
          
          // Build address parts
          final addressParts = <String>[];
          if (placemark.street != null && placemark.street!.isNotEmpty) {
            addressParts.add(placemark.street!);
          }
          if (placemark.subLocality != null && placemark.subLocality!.isNotEmpty) {
            addressParts.add(placemark.subLocality!);
          }
          if (placemark.locality != null && placemark.locality!.isNotEmpty) {
            addressParts.add(placemark.locality!);
          }
          if (placemark.administrativeArea != null && placemark.administrativeArea!.isNotEmpty) {
            addressParts.add(placemark.administrativeArea!);
          }
          if (placemark.country != null && placemark.country!.isNotEmpty) {
            addressParts.add(placemark.country!);
          }
          
          final fallbackAddress = addressParts.join(', ');
          
          if (addressAr == null) {
            addressAr = fallbackAddress;
          }
          if (addressEn == null) {
            addressEn = fallbackAddress;
          }
        }
      }

      setState(() {
        if (addressAr != null) {
          _addressArController.text = addressAr;
        }
        if (addressEn != null) {
          _addressEnController.text = addressEn;
        }
      });
    } catch (e) {
      print('Error getting address: $e');
      // Don't show error to user, just log it
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _addImageUrl() {
    if (_imageUrlInputController.text.trim().isNotEmpty) {
      setState(() {
        _imageUrls.add(_imageUrlInputController.text.trim());
        _imageUrlInputController.clear();
      });
    }
  }

  void _removeImageUrl(int index) {
    setState(() {
      _imageUrls.removeAt(index);
    });
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
              widget.place != null
                  ? (loc?.translate('edit_place') ?? 'تعديل المكان')
                  : (loc?.translate('add_place') ?? 'إضافة مكان'),
              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
            actions: [
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                IconButton(
                  icon: const Icon(Icons.save),
                  onPressed: _savePlace,
                ),
            ],
          ),
          body: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name Arabic
                  Text(
                    'الاسم (عربي) *',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameArController,
                    textDirection: ui.TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'أدخل الاسم بالعربية',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال الاسم';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Name English
                  Text(
                    'Name (English) *',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameEnController,
                    decoration: InputDecoration(
                      hintText: 'Enter name in English',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description Arabic
                  Text(
                    'الوصف (عربي) *',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionArController,
                    textDirection: ui.TextDirection.rtl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'أدخل الوصف بالعربية',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى إدخال الوصف';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Description English
                  Text(
                    'Description (English) *',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionEnController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Enter description in English',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Category
                  Text(
                    'النوع / الفئة *',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    items: _categories.map((cat) {
                      return DropdownMenuItem(
                        value: cat['ar'],
                        child: Text('${cat['ar']} / ${cat['en']}'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                        _selectedCategoryEn = _categories.firstWhere((c) => c['ar'] == value)['en'];
                        _categoryController.text = value ?? '';
                        _categoryEnController.text = _selectedCategoryEn ?? '';
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'يرجى اختيار الفئة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Location Map
                  Text(
                    'الموقع *',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _selectedLocation ?? LatLng(_latitude, _longitude),
                          initialZoom: 13,
                          onTap: (tapPosition, point) async {
                            setState(() {
                              _selectedLocation = point;
                              _latitude = point.latitude;
                              _longitude = point.longitude;
                            });
                            _mapController.move(point, 13);
                            // Update address automatically
                            await _updateAddressFromLocation(point);
                          },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName: 'com.smarttour.app',
                          ),
                          if (_selectedLocation != null)
                            MarkerLayer(
                              markers: [
                                Marker(
                                  point: _selectedLocation!,
                                  width: 40,
                                  height: 40,
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Colors.red,
                                    size: 40,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'اضغط على الخريطة لاختيار الموقع',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 16),

                  // Address Arabic
                  Text(
                    'العنوان (عربي)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _addressArController,
                    textDirection: ui.TextDirection.rtl,
                    decoration: InputDecoration(
                      hintText: 'أدخل العنوان بالعربية',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address English
                  Text(
                    'Address (English)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _addressEnController,
                    decoration: InputDecoration(
                      hintText: 'Enter address in English',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Phone
                  Text(
                    'الهاتف',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: '05xxxxxxxx',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Website
                  Text(
                    'الموقع الإلكتروني',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _websiteController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      hintText: 'https://example.com',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Working Hours
                  Text(
                    'ساعات العمل',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _hoursController,
                    decoration: InputDecoration(
                      hintText: 'مثال: 9:00 ص - 5:00 م',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Visit Hours
                  Text(
                    'ساعات الزيارة',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _visitHoursController,
                    decoration: InputDecoration(
                      hintText: 'مثال: 9:00 ص - 5:00 م',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Main Image URL
                  Text(
                    'رابط الصورة الرئيسية',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _imageUrlController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      hintText: 'https://example.com/image.jpg',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.add_photo_alternate),
                        onPressed: () {
                          // TODO: Add image picker
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Additional Images
                  Text(
                    'روابط الصور الإضافية',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _imageUrlInputController,
                          keyboardType: TextInputType.url,
                          decoration: InputDecoration(
                            hintText: 'أدخل رابط الصورة',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.add),
                        onPressed: _addImageUrl,
                      ),
                    ],
                  ),
                  if (_imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _imageUrls.asMap().entries.map((entry) {
                        return Chip(
                          label: Text(
                            entry.value.length > 30
                                ? '${entry.value.substring(0, 30)}...'
                                : entry.value,
                            style: const TextStyle(fontSize: 12),
                          ),
                          onDeleted: () => _removeImageUrl(entry.key),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 16),

                  // Audio Guide URL
                  Text(
                    'رابط الدليل الصوتي',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _audioGuideUrlController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      hintText: 'https://example.com/audio.mp3',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // AR Image URL
                  Text(
                    'رابط صورة الواقع المعزز',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _arImageUrlController,
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      hintText: 'https://example.com/ar-image.jpg',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Rating
                  Text(
                    'التقييم',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                          value: _rating,
                          min: 0,
                          max: 5,
                          divisions: 50,
                          label: _rating.toStringAsFixed(1),
                          onChanged: (value) {
                            setState(() {
                              _rating = value;
                            });
                          },
                        ),
                      ),
                      Text(
                        _rating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Reviews Count
                  Text(
                    'عدد المراجعات',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                    textDirection: ui.TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    keyboardType: TextInputType.number,
                    initialValue: _reviews.toString(),
                    decoration: InputDecoration(
                      hintText: '0',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      _reviews = int.tryParse(value) ?? 0;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Is Featured
                  CheckboxListTile(
                    title: Text(
                      'مكان مميز',
                      textDirection: ui.TextDirection.rtl,
                    ),
                    value: _isFeatured,
                    onChanged: (value) {
                      setState(() {
                        _isFeatured = value ?? false;
                      });
                    },
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _savePlace,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              widget.place != null ? 'تحديث' : 'حفظ',
                              style: const TextStyle(fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

