import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_drawer.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/trips_service.dart';

class TripsScreen extends StatefulWidget {
  const TripsScreen({super.key});

  @override
  State<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends State<TripsScreen> {
  String _activeTab = 'planned';
  int _selectedIndex = 2; // Trips is selected

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _startDate;
  DateTime? _endDate;

  final TripsService _tripsService = TripsService();
  List<Trip> _trips = [];
  StreamSubscription<List<Trip>>? _tripsSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTrips();
  }

  @override
  void dispose() {
    _tripsSubscription?.cancel();
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadTrips() {
    _tripsSubscription?.cancel();
    _tripsSubscription = _tripsService.getTripsStream().listen(
      (trips) {
        if (mounted) {
          setState(() {
            _trips = trips;
            _isLoading = false;
          });
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تحميل الرحلات: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
  }

  List<Trip> get _filteredTrips {
    return _trips.where((trip) => trip.status == _activeTab).toList();
  }

  List<TabInfo> _getTabs(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return [
      TabInfo(
        id: 'planned',
        name: loc?.translate('planned') ?? 'مخططة',
        count: _trips.where((t) => t.status == 'planned').length,
      ),
      TabInfo(
        id: 'ongoing',
        name: loc?.translate('ongoing') ?? 'جارية',
        count: _trips.where((t) => t.status == 'ongoing').length,
      ),
      TabInfo(
        id: 'completed',
        name: loc?.translate('completed') ?? 'مكتملة',
        count: _trips.where((t) => t.status == 'completed').length,
      ),
    ];
  }

  String _calculateDuration(BuildContext context, DateTime start, DateTime end) {
    final loc = AppLocalizations.of(context);
    final days = end.difference(start).inDays + 1;
    if (days == 1) {
      return loc?.translate('one_day') ?? 'يوم واحد';
    }
    return '$days ${loc?.translate('days') ?? 'أيام'}';
  }

  String _formatDate(DateTime date) {
    final isArabic = AppLocalizations.of(context)?.locale.languageCode == 'ar';
    if (isArabic) {
      // Format in Arabic style
      final months = [
        'يناير', 'فبراير', 'مارس', 'أبريل', 'مايو', 'يونيو',
        'يوليو', 'أغسطس', 'سبتمبر', 'أكتوبر', 'نوفمبر', 'ديسمبر'
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } else {
      // Format in English style
      return DateFormat('MMM dd, yyyy').format(date);
    }
  }

  void _handleCreateTrip() {
    _showCreateTripDialog();
  }

  Future<void> _handleCreateTripSubmit() async {
    final loc = AppLocalizations.of(context);
    if (_nameController.text.isEmpty || _startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc?.translate('fill_all_fields') ?? 'يرجى ملء جميع الحقول المطلوبة'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_endDate!.isBefore(_startDate!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc?.translate('end_date_after_start') ?? 'تاريخ النهاية يجب أن يكون بعد تاريخ البداية'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      setState(() {
        _isLoading = true;
      });

      final newTrip = Trip(
        id: '', // Will be set by Firebase
        name: _nameController.text,
        nameEn: _nameController.text, // TODO: Add English name field
        startDate: _startDate!,
        endDate: _endDate!,
        places: 0,
        status: 'planned',
        description: _descriptionController.text.isEmpty ? null : _descriptionController.text,
        descriptionEn: _descriptionController.text.isEmpty ? null : _descriptionController.text, // TODO: Add English description field
        imageUrl: null,
        userId: _tripsService.currentUserId ?? '',
      );

      await _tripsService.createTrip(newTrip);

      _nameController.clear();
      _descriptionController.clear();
      _startDate = null;
      _endDate = null;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(loc?.translate('trip_created_success') ?? 'تم إنشاء الرحلة بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في إنشاء الرحلة: $e'),
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

  void _handleDeleteTrip(String tripId) {
    showDialog(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(loc?.translate('delete_trip') ?? 'حذف الرحلة'),
          content: Text(loc?.translate('delete_trip_confirm') ?? 'هل أنت متأكد من حذف هذه الرحلة؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc?.translate('cancel') ?? 'إلغاء'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                try {
                  await _tripsService.deleteTrip(tripId);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(loc?.translate('trip_deleted_success') ?? 'تم حذف الرحلة'),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('خطأ في حذف الرحلة: $e'),
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
        );
      },
    );
  }

  void _handleShareTrip(Trip trip) {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${AppLocalizations.of(context)?.translate('share_trip') ?? 'مشاركة'}: ${trip.name}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _handleEditTrip(String tripId) async {
    final trip = _trips.firstWhere((t) => t.id == tripId);
    final loc = AppLocalizations.of(context);
    
    // Pre-fill the form with existing trip data
    _nameController.text = trip.name;
    _descriptionController.text = trip.description ?? '';
    _startDate = trip.startDate;
    _endDate = trip.endDate;
    
    // Show edit dialog
    _showCreateTripDialog(
      isEdit: true,
      tripId: tripId,
      onSubmit: () async {
        try {
          setState(() {
            _isLoading = true;
          });

          await _tripsService.updateTrip(tripId, {
            'name': _nameController.text,
            'description': _descriptionController.text.isEmpty ? '' : _descriptionController.text,
            'startDate': _startDate != null ? Timestamp.fromDate(_startDate!) : null,
            'endDate': _endDate != null ? Timestamp.fromDate(_endDate!) : null,
          });

          _nameController.clear();
          _descriptionController.clear();
          _startDate = null;
          _endDate = null;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(loc?.translate('trip_updated_success') ?? 'تم تحديث الرحلة بنجاح'),
                backgroundColor: Colors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('خطأ في تحديث الرحلة: $e'),
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
      },
    );
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate, {StateSetter? setDialogState}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_startDate ?? DateTime.now())
          : (_endDate ?? _startDate ?? DateTime.now()),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      locale: const Locale('ar', 'SA'),
    );
    if (picked != null) {
      final updateState = setDialogState ?? setState;
      updateState(() {
        if (isStartDate) {
          _startDate = picked;
          if (_endDate != null && _endDate!.isBefore(_startDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
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
                    // Tabs
                    _buildTabs(),
                    
                    // Trips List
                    _buildTripsList(),
                    
                    // Planning Tips
                    if (_filteredTrips.isNotEmpty && _activeTab == 'planned')
                      _buildPlanningTips(),
                    
                    const SizedBox(height: 80), // Space for bottom nav
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateTripDialog();
        },
        backgroundColor: const Color(0xFF030213),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          loc?.translate('new_trip') ?? 'رحلة جديدة',
          style: const TextStyle(color: Colors.white),
        ),
      ),
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
          // Location & Weather
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.wb_sunny, size: 16, color: Colors.orange),
              const SizedBox(width: 4),
              const Text(
                '28°C',
                style: TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.location_on, size: 16, color: Colors.blue),
              Text(
                AppLocalizations.of(context)?.translate('riyadh') ?? 'الرياض',
                style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          
          // Title
          Text(
            AppLocalizations.of(context)?.translate('my_trips') ?? 'رحلاتي',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          const SizedBox(width: 80), // Balance
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: _getTabs(context).map((tab) {
            bool isActive = _activeTab == tab.id;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _activeTab = tab.id;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.2),
                              spreadRadius: 1,
                              blurRadius: 4,
                            ),
                          ]
                        : null,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tab.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                          color: isActive ? const Color(0xFF030213) : Colors.black87,
                        ),
                      ),
                      if (tab.count > 0) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFF030213)
                                : Colors.grey[300],
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              '${tab.count}',
                              style: TextStyle(
                                fontSize: 11,
                                color: isActive ? Colors.white : Colors.grey[700],
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTripsList() {
    if (_filteredTrips.isEmpty) {
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
              child: Icon(Icons.calendar_today, size: 32, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            Text(
              '${AppLocalizations.of(context)?.translate('no_trips_status') ?? 'لا توجد رحلات'} ${_getStatusName(context, _activeTab)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _getEmptyMessage(context, _activeTab),
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: _filteredTrips.map((trip) => _buildTripCard(trip)).toList(),
      ),
    );
  }

  String _getStatusName(BuildContext context, String status) {
    final loc = AppLocalizations.of(context);
    switch (status) {
      case 'planned':
        return loc?.translate('planned') ?? 'مخططة';
      case 'ongoing':
        return loc?.translate('ongoing') ?? 'جارية';
      case 'completed':
        return loc?.translate('completed') ?? 'مكتملة';
      default:
        return '';
    }
  }

  String _getEmptyMessage(BuildContext context, String status) {
    final loc = AppLocalizations.of(context);
    switch (status) {
      case 'planned':
        return loc?.translate('start_creating_trip') ?? 'ابدأ بإنشاء رحلة جديدة لاستكشاف الأماكن المثيرة';
      case 'ongoing':
        return loc?.translate('no_ongoing_trips') ?? 'لا توجد رحلات قيد التنفيذ حالياً';
      case 'completed':
        return loc?.translate('no_completed_trips') ?? 'لم تكمل أي رحلات بعد';
      default:
        return '';
    }
  }

  Widget _buildTripCard(Trip trip) {
    final Color statusColor;
    switch (trip.status) {
      case 'planned':
        statusColor = Colors.blue;
        break;
      case 'ongoing':
        statusColor = Colors.green;
        break;
      case 'completed':
        statusColor = Colors.grey;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Container(
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
          Container(
            height: 160,
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[300]!,
                  Colors.blue[600]!,
                ],
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: Icon(
                    Icons.landscape,
                    size: 60,
                    color: Colors.white.withOpacity(0.5),
                  ),
                ),
                // Status Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _getStatusName(context, trip.status),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Text(
                  trip.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                
                // Details
                _buildDetailRow(Icons.calendar_today, '${_formatDate(trip.startDate)} - ${_formatDate(trip.endDate)}'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.location_on, '${trip.places} ${AppLocalizations.of(context)?.translate('places') ?? 'أماكن'}'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.access_time, _calculateDuration(context, trip.startDate, trip.endDate)),
                const SizedBox(height: 16),
                
                // Actions
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _handleEditTrip(trip.id),
                        icon: const Icon(Icons.edit, size: 18),
                        label: Text(AppLocalizations.of(context)?.translate('edit') ?? 'تعديل'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[100],
                          foregroundColor: Colors.grey[700],
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _handleShareTrip(trip),
                      icon: const Icon(Icons.share),
                      color: Colors.grey[700],
                    ),
                    IconButton(
                      onPressed: () => _handleDeleteTrip(trip.id),
                      icon: const Icon(Icons.delete),
                      color: Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.blue[700]),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  Widget _buildPlanningTips() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[500]!, Colors.blue[600]!],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)?.translate('planning_tips') ?? 'نصائح للتخطيط',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.of(context)?.translate('planning_tips_text') ?? 'احرص على ترك وقت كافٍ بين الأماكن للانتقال والاستمتاع بكل موقع',
              style: TextStyle(
                color: Colors.white.withOpacity(0.9),
                fontSize: 14,
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
              Navigator.of(context).pushReplacementNamed('/map');
              break;
            case 2:
              // Already on trips
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

  void _showCreateTripDialog({bool isEdit = false, String? tripId, VoidCallback? onSubmit}) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEdit 
                  ? (AppLocalizations.of(context)?.translate('edit_trip') ?? 'تعديل الرحلة')
                  : (AppLocalizations.of(context)?.translate('create_new_trip') ?? 'إنشاء رحلة جديدة'),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  if (!isEdit) {
                    _nameController.clear();
                    _descriptionController.clear();
                    _startDate = null;
                    _endDate = null;
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Trip Name
                Text(
                  AppLocalizations.of(context)?.translate('trip_name') ?? 'اسم الرحلة',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)?.translate('trip_name_hint') ?? 'مثل: رحلة الرياض التاريخية',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Start Date
                Text(
                  AppLocalizations.of(context)?.translate('start_date') ?? 'تاريخ البداية',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context, true, setDialogState: setDialogState),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                        Text(
                          _startDate != null
                              ? _formatDate(_startDate!)
                              : (AppLocalizations.of(context)?.translate('select_date') ?? 'اختر التاريخ'),
                          style: TextStyle(
                            color: _startDate != null
                                ? Colors.black87
                                : Colors.grey[500],
                            fontSize: 14,
                          ),
                          textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                              ? ui.TextDirection.rtl 
                              : ui.TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // End Date
                Text(
                  AppLocalizations.of(context)?.translate('end_date') ?? 'تاريخ النهاية',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => _selectDate(context, false, setDialogState: setDialogState),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Icon(Icons.calendar_today, color: Colors.grey[600], size: 20),
                        Text(
                          _endDate != null
                              ? _formatDate(_endDate!)
                              : (AppLocalizations.of(context)?.translate('select_date') ?? 'اختر التاريخ'),
                          style: TextStyle(
                            color: _endDate != null
                                ? Colors.black87
                                : Colors.grey[500],
                            fontSize: 14,
                          ),
                          textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                              ? ui.TextDirection.rtl 
                              : ui.TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Description
                Text(
                  AppLocalizations.of(context)?.translate('trip_description') ?? 'وصف الرحلة (اختياري)',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: AppLocalizations.of(context)?.translate('trip_description_hint') ?? 'وصف موجز عن الرحلة...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                AppLocalizations.of(context)?.translate('cancel') ?? 'إلغاء',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (isEdit && onSubmit != null) {
                  onSubmit();
                } else {
                  _handleCreateTripSubmit();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF030213),
                foregroundColor: Colors.white,
              ),
              child: Text(
                isEdit 
                  ? (AppLocalizations.of(context)?.translate('update_trip') ?? 'تحديث الرحلة')
                  : (AppLocalizations.of(context)?.translate('create_trip_button') ?? 'إنشاء الرحلة'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TabInfo {
  final String id;
  final String name;
  final int count;

  TabInfo({
    required this.id,
    required this.name,
    required this.count,
  });
}

