import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../l10n/app_localizations.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/events_service.dart';
import '../services/transportation_service.dart';

class LiveUpdatesScreen extends StatefulWidget {
  const LiveUpdatesScreen({super.key});

  @override
  State<LiveUpdatesScreen> createState() => _LiveUpdatesScreenState();
}

class _LiveUpdatesScreenState extends State<LiveUpdatesScreen>
    with SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  final LocationService _locationService = LocationService();
  final EventsService _eventsService = EventsService();
  final TransportationService _transportationService = TransportationService();

  late TabController _tabController;
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Refresh weather and location
      await _locationService.getCurrentLocation();
      final location = await _locationService.getCurrentLocation();
      if (location != null) {
        await _weatherService.getWeatherByCoordinates(
          location.latitude,
          location.longitude,
        );
      }
    } catch (e) {
      print('Error refreshing data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLocalizations.of(context)?.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.translate('live_updates') ??
              'التحديثات المباشرة',
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _refreshData,
            tooltip: AppLocalizations.of(context)?.translate('refresh') ??
                'تحديث',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              text: AppLocalizations.of(context)?.translate('weather') ?? 'الطقس',
            ),
            Tab(
              text: AppLocalizations.of(context)?.translate('events') ?? 'الفعاليات',
            ),
            Tab(
              text: AppLocalizations.of(context)?.translate('transportation') ??
                  'المواصلات',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWeatherTab(),
          _buildEventsTab(),
          _buildTransportationTab(),
        ],
      ),
    );
  }

  Widget _buildWeatherTab() {
    final isArabic =
        AppLocalizations.of(context)?.locale.languageCode == 'ar';

    return FutureBuilder<LocationData?>(
      future: _locationService.getCurrentLocation(),
      builder: (context, locationSnapshot) {
        if (!locationSnapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final location = locationSnapshot.data;
        if (location == null) {
          return Center(
            child: Text(
              AppLocalizations.of(context)?.translate('location_unavailable') ??
                  'الموقع غير متاح',
              textDirection:
                  isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
          );
        }

        return FutureBuilder<WeatherData?>(
          future: _weatherService.getWeatherByCoordinates(
            location.latitude,
            location.longitude,
          ),
          builder: (context, weatherSnapshot) {
            if (weatherSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final weather = weatherSnapshot.data;
            if (weather == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.cloud_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      AppLocalizations.of(context)
                              ?.translate('weather_unavailable') ??
                          'بيانات الطقس غير متاحة',
                      textDirection:
                          isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current Weather Card
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue[400]!, Colors.blue[600]!],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    weather.city,
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                    textDirection: isArabic
                                        ? ui.TextDirection.rtl
                                        : ui.TextDirection.ltr,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    weather.description,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    textDirection: isArabic
                                        ? ui.TextDirection.rtl
                                        : ui.TextDirection.ltr,
                                  ),
                                ],
                              ),
                              Text(
                                WeatherService.getWeatherIcon(weather.icon),
                                style: const TextStyle(fontSize: 64),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '${weather.temperature.toStringAsFixed(1)}°',
                                style: const TextStyle(
                                  fontSize: 48,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          if (weather.humidity != null || weather.windSpeed != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 24),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  if (weather.humidity != null)
                                    _buildWeatherDetail(
                                      Icons.water_drop,
                                      '${weather.humidity!.toStringAsFixed(0)}%',
                                      AppLocalizations.of(context)
                                              ?.translate('humidity') ??
                                          'الرطوبة',
                                      isArabic,
                                    ),
                                  if (weather.windSpeed != null)
                                    _buildWeatherDetail(
                                      Icons.air,
                                      '${weather.windSpeed!.toStringAsFixed(1)} km/h',
                                      AppLocalizations.of(context)
                                              ?.translate('wind_speed') ??
                                          'سرعة الرياح',
                                      isArabic,
                                    ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Location Info
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.location_on, color: Colors.blue),
                      title: Text(
                        AppLocalizations.of(context)?.translate('current_location') ??
                            'الموقع الحالي',
                        textDirection:
                            isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                      subtitle: Text(
                        location.address ?? location.city,
                        textDirection:
                            isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildWeatherDetail(
    IconData icon,
    String value,
    String label,
    bool isArabic,
  ) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
      ],
    );
  }

  Widget _buildEventsTab() {
    final isArabic =
        AppLocalizations.of(context)?.locale.languageCode == 'ar';

    return StreamBuilder<List<Event>>(
      stream: _eventsService.getActiveEvents(limit: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              textDirection:
                  isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
          );
        }

        final events = snapshot.data ?? [];

        if (events.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)?.translate('no_events') ??
                      'لا توجد فعاليات متاحة',
                  textDirection:
                      isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            return _buildEventCard(event, isArabic);
          },
        );
      },
    );
  }

  Widget _buildEventCard(Event event, bool isArabic) {
    final title = isArabic ? event.title : event.titleEn;
    final description = isArabic ? event.description : event.descriptionEn;
    final location = isArabic ? event.location : event.locationEn;
    final category = isArabic ? event.category : event.categoryEn;

    final dateFormat = DateFormat(isArabic ? 'yyyy/MM/dd HH:mm' : 'MM/dd/yyyy HH:mm');
    final startDateStr = dateFormat.format(event.startDate);
    final endDateStr = dateFormat.format(event.endDate);

    Color statusColor;
    String statusText;
    if (event.isOngoing) {
      statusColor = Colors.green;
      statusText = AppLocalizations.of(context)?.translate('ongoing') ?? 'جارية';
    } else if (event.isUpcoming) {
      statusColor = Colors.blue;
      statusText = AppLocalizations.of(context)?.translate('upcoming') ?? 'قادمة';
    } else {
      statusColor = Colors.grey;
      statusText = AppLocalizations.of(context)?.translate('past') ?? 'منتهية';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection:
                        isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection:
                        isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  '$startDateStr - $endDateStr',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  textDirection:
                      isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    location,
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    textDirection:
                        isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTransportationTab() {
    final isArabic =
        AppLocalizations.of(context)?.locale.languageCode == 'ar';

    return StreamBuilder<List<TransportationInfo>>(
      stream: _transportationService.getTransportationUpdates(limit: 20),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              textDirection:
                  isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
          );
        }

        final transportation = snapshot.data ?? [];

        if (transportation.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_transit, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 16),
                Text(
                  AppLocalizations.of(context)?.translate('no_transportation_updates') ??
                      'لا توجد تحديثات للمواصلات',
                  textDirection:
                      isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: transportation.length,
          itemBuilder: (context, index) {
            final info = transportation[index];
            return _buildTransportationCard(info, isArabic);
          },
        );
      },
    );
  }

  Widget _buildTransportationCard(TransportationInfo info, bool isArabic) {
    final type = isArabic ? info.type : info.typeEn;
    final route = isArabic ? info.route : info.routeEn;
    final status = isArabic ? (info.status ?? '') : (info.statusEn ?? '');
    final description = isArabic ? info.description : info.descriptionEn;

    IconData typeIcon;
    Color typeColor;
    switch (info.type.toLowerCase()) {
      case 'metro':
        typeIcon = Icons.train;
        typeColor = Colors.blue;
        break;
      case 'bus':
        typeIcon = Icons.directions_bus;
        typeColor = Colors.green;
        break;
      case 'taxi':
        typeIcon = Icons.local_taxi;
        typeColor = Colors.yellow[700]!;
        break;
      default:
        typeIcon = Icons.directions_transit;
        typeColor = Colors.grey;
    }

    Color statusColor = Colors.green;
    if (status.toLowerCase().contains('delayed')) {
      statusColor = Colors.orange;
    } else if (status.toLowerCase().contains('suspended')) {
      statusColor = Colors.red;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(typeIcon, color: typeColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection:
                        isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    route,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    textDirection:
                        isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                  if (status.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        textDirection: isArabic
                            ? ui.TextDirection.rtl
                            : ui.TextDirection.ltr,
                      ),
                    ),
                  ],
                  if (description != null && description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textDirection:
                          isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}




