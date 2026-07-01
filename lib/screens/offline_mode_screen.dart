import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import 'dart:ui' as ui;
import '../l10n/app_localizations.dart';
import '../services/offline_service.dart';

class OfflineModeScreen extends StatefulWidget {
  const OfflineModeScreen({super.key});

  @override
  State<OfflineModeScreen> createState() => _OfflineModeScreenState();
}

class _OfflineModeScreenState extends State<OfflineModeScreen> {
  final OfflineService _offlineService = OfflineService();
  bool _isOfflineEnabled = false;
  bool _isLoading = false;
  bool _isSyncing = false;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadOfflineStatus();
  }

  Future<void> _loadOfflineStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _offlineService.initialize();
      final enabled = await _offlineService.isOfflineModeEnabled();
      final stats = await _offlineService.getOfflineStats();

      setState(() {
        _isOfflineEnabled = enabled;
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading offline status: $e')),
        );
      }
    }
  }

  Future<void> _toggleOfflineMode(bool value) async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _offlineService.setOfflineModeEnabled(value);
      final stats = await _offlineService.getOfflineStats();

      setState(() {
        _isOfflineEnabled = value;
        _stats = stats;
        _isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              value
                  ? AppLocalizations.of(context)?.translate('offline_mode_enabled') ??
                      'تم تفعيل الوضع دون اتصال'
                  : AppLocalizations.of(context)?.translate('offline_mode_disabled') ??
                      'تم إلغاء تفعيل الوضع دون اتصال',
            ),
            backgroundColor: value ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _syncData() async {
    setState(() {
      _isSyncing = true;
    });

    try {
      await _offlineService.syncFromFirebase();
      final stats = await _offlineService.getOfflineStats();

      setState(() {
        _stats = stats;
        _isSyncing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.translate('sync_completed') ??
                  'تم مزامنة البيانات بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isSyncing = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.translate('sync_failed') ?? 'فشلت المزامنة'}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _clearData() async {
    final isArabic = AppLocalizations.of(context)?.locale.languageCode == 'ar';
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)?.translate('clear_offline_data') ??
              'مسح البيانات المحلية',
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
        content: Text(
          AppLocalizations.of(context)?.translate('clear_offline_data_confirmation') ??
              'هل أنت متأكد من مسح جميع البيانات المحلية؟ لن تتمكن من الوصول إليها بدون اتصال.',
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              AppLocalizations.of(context)?.translate('cancel') ?? 'إلغاء',
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              AppLocalizations.of(context)?.translate('clear') ?? 'مسح',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        _isLoading = true;
      });

      try {
        await _offlineService.clearOfflineData();
        final stats = await _offlineService.getOfflineStats();

        setState(() {
          _stats = stats;
          _isOfflineEnabled = false;
          _isLoading = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.translate('data_cleared') ??
                    'تم مسح البيانات بنجاح',
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return '-';
    try {
      final date = DateTime.parse(dateString);
      final isArabic = AppLocalizations.of(context)?.locale.languageCode == 'ar';
      return DateFormat(isArabic ? 'yyyy/MM/dd HH:mm' : 'MM/dd/yyyy HH:mm')
          .format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isArabic = AppLocalizations.of(context)?.locale.languageCode == 'ar';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.translate('offline_mode') ?? 'الوضع دون اتصال',
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Offline Mode Toggle
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  AppLocalizations.of(context)
                                          ?.translate('enable_offline_mode') ??
                                      'تفعيل الوضع دون اتصال',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textDirection: isArabic
                                      ? ui.TextDirection.rtl
                                      : ui.TextDirection.ltr,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  AppLocalizations.of(context)
                                          ?.translate('offline_mode_description') ??
                                      'احفظ البيانات محلياً للوصول إليها بدون اتصال بالإنترنت',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  textDirection: isArabic
                                      ? ui.TextDirection.rtl
                                      : ui.TextDirection.ltr,
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isOfflineEnabled,
                            onChanged: _toggleOfflineMode,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Statistics
                  Text(
                    AppLocalizations.of(context)?.translate('offline_statistics') ??
                        'إحصائيات البيانات المحلية',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textDirection:
                        isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    context,
                    Icons.place,
                    AppLocalizations.of(context)?.translate('saved_places') ??
                        'الأماكن المحفوظة',
                    '${_stats['placesCount'] ?? 0}',
                    Colors.blue,
                  ),
                  const SizedBox(height: 12),
                  _buildStatCard(
                    context,
                    Icons.flight_takeoff,
                    AppLocalizations.of(context)?.translate('saved_trips') ??
                        'الرحلات المحفوظة',
                    '${_stats['tripsCount'] ?? 0}',
                    Colors.orange,
                  ),
                  const SizedBox(height: 24),

                  // Last Sync Info
                  if (_stats['lastFullSync'] != null)
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AppLocalizations.of(context)
                                      ?.translate('last_sync') ??
                                  'آخر مزامنة',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                              textDirection: isArabic
                                  ? ui.TextDirection.rtl
                                  : ui.TextDirection.ltr,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatDate(_stats['lastFullSync'] as String?),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                              textDirection: isArabic
                                  ? ui.TextDirection.rtl
                                  : ui.TextDirection.ltr,
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _isSyncing ? null : _syncData,
                          icon: _isSyncing
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.sync),
                          label: Text(
                            AppLocalizations.of(context)?.translate('sync_now') ??
                                'مزامنة الآن',
                            textDirection: isArabic
                                ? ui.TextDirection.rtl
                                : ui.TextDirection.ltr,
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _clearData,
                          icon: const Icon(Icons.delete_outline),
                          label: Text(
                            AppLocalizations.of(context)?.translate('clear_data') ??
                                'مسح البيانات',
                            textDirection: isArabic
                                ? ui.TextDirection.rtl
                                : ui.TextDirection.ltr,
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            foregroundColor: Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Info
                  Card(
                    color: Colors.blue[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.blue[700]),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              AppLocalizations.of(context)
                                      ?.translate('offline_mode_info') ??
                                  'سيتم حفظ الأماكن المميزة والرحلات محلياً للوصول إليها بدون اتصال.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.blue[900],
                              ),
                              textDirection: isArabic
                                  ? ui.TextDirection.rtl
                                  : ui.TextDirection.ltr,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    Color color,
  ) {
    final isArabic = AppLocalizations.of(context)?.locale.languageCode == 'ar';

    return Card(
      elevation: 1,
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
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textDirection:
                        isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    textDirection:
                        isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}




