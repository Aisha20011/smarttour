import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import '../widgets/app_drawer.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/notification_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final NotificationService _notificationService = NotificationService();
  bool _notificationsEnabled = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _saveNotificationSetting(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('notifications_enabled', value);
      setState(() {
        _notificationsEnabled = value;
      });
    } catch (e) {
      print('Error saving notification setting: $e');
    }
  }

  void _showLanguageDialog(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
    final isArabic = localeProvider.isArabic;
    final loc = AppLocalizations.of(context);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          loc?.translate('select_language') ?? 'اختر اللغة',
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(
                loc?.translate('arabic') ?? 'العربية',
                textDirection: ui.TextDirection.rtl,
              ),
              trailing: isArabic ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () async {
                await localeProvider.setLocale(const Locale('ar'));
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.language),
              title: Text(
                loc?.translate('english') ?? 'English',
                textDirection: ui.TextDirection.ltr,
              ),
              trailing: !isArabic ? const Icon(Icons.check, color: Colors.blue) : null,
              onTap: () async {
                await localeProvider.setLocale(const Locale('en'));
                if (mounted) {
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
        ),
      ),
    );
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
          appBar: AppBar(
            title: Text(
              loc?.translate('general_settings') ?? 'الإعدادات العامة',
              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
            centerTitle: true,
          ),
          body: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Language Settings
                      _buildSection(
                        context,
                        loc?.translate('language_preferences') ?? 'اللغة والتفضيلات',
                        [
                          _buildSettingTile(
                            context,
                            icon: Icons.language,
                            title: loc?.translate('language') ?? 'اللغة',
                            subtitle: localeProvider.isArabic
                                ? (loc?.translate('arabic') ?? 'العربية')
                                : (loc?.translate('english') ?? 'English'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  localeProvider.isArabic
                                      ? (loc?.translate('arabic') ?? 'العربية')
                                      : (loc?.translate('english') ?? 'English'),
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.chevron_left, color: Colors.grey),
                              ],
                            ),
                            onTap: () => _showLanguageDialog(context),
                            isArabic: isArabic,
                          ),
                        ],
                      ),

                      // Notification Settings
                      _buildSection(
                        context,
                        loc?.translate('notification_settings') ?? 'إعدادات الإشعارات',
                        [
                          _buildSettingTile(
                            context,
                            icon: Icons.notifications,
                            title: loc?.translate('enable_notifications') ?? 'تفعيل الإشعارات',
                            subtitle: loc?.translate('enable_notifications_desc') ??
                                'تلقي إشعارات حول التحديثات والفعاليات',
                            trailing: Switch(
                              value: _notificationsEnabled,
                              onChanged: _saveNotificationSetting,
                            ),
                            onTap: () {
                              _saveNotificationSetting(!_notificationsEnabled);
                            },
                            isArabic: isArabic,
                          ),
                        ],
                      ),

                      // App Preferences
                      _buildSection(
                        context,
                        loc?.translate('app_preferences') ?? 'تفضيلات التطبيق',
                        [
                          _buildSettingTile(
                            context,
                            icon: Icons.location_on,
                            title: loc?.translate('location_services') ?? 'خدمات الموقع',
                            subtitle: loc?.translate('location_services_desc') ??
                                'استخدام الموقع لتقديم توصيات أفضل',
                            trailing: const Icon(Icons.chevron_left, color: Colors.grey),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    loc?.translate('location_settings_info') ??
                                        'يمكنك إدارة إعدادات الموقع من إعدادات الجهاز',
                                  ),
                                ),
                              );
                            },
                            isArabic: isArabic,
                          ),
                          _buildSettingTile(
                            context,
                            icon: Icons.storage,
                            title: loc?.translate('storage_management') ?? 'إدارة التخزين',
                            subtitle: loc?.translate('storage_management_desc') ??
                                'إدارة مساحة التخزين والبيانات المحلية',
                            trailing: const Icon(Icons.chevron_left, color: Colors.grey),
                            onTap: () {
                              Navigator.of(context).pushNamed('/offline');
                            },
                            isArabic: isArabic,
                          ),
                        ],
                      ),

                      // About Section
                      _buildSection(
                        context,
                        loc?.translate('about') ?? 'حول التطبيق',
                        [
                          _buildSettingTile(
                            context,
                            icon: Icons.info_outline,
                            title: loc?.translate('app_version') ?? 'إصدار التطبيق',
                            subtitle: 'SmartTour v1.0.0',
                            trailing: const Icon(Icons.chevron_left, color: Colors.grey),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    loc?.translate('app_version_info') ??
                                        'SmartTour v1.0.0 - دليلك السياحي الذكي',
                                  ),
                                ),
                              );
                            },
                            isArabic: isArabic,
                          ),
                          _buildSettingTile(
                            context,
                            icon: Icons.description,
                            title: loc?.translate('terms_of_service') ?? 'شروط الخدمة',
                            subtitle: loc?.translate('terms_of_service_desc') ?? 'اقرأ شروط استخدام التطبيق',
                            trailing: const Icon(Icons.chevron_left, color: Colors.grey),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    loc?.translate('terms_coming_soon') ??
                                        'شروط الخدمة قريباً',
                                  ),
                                ),
                              );
                            },
                            isArabic: isArabic,
                          ),
                          _buildSettingTile(
                            context,
                            icon: Icons.privacy_tip,
                            title: loc?.translate('privacy_policy') ?? 'سياسة الخصوصية',
                            subtitle: loc?.translate('privacy_policy_desc') ?? 'اقرأ سياسة الخصوصية',
                            trailing: const Icon(Icons.chevron_left, color: Colors.grey),
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    loc?.translate('privacy_coming_soon') ??
                                        'سياسة الخصوصية قريباً',
                                  ),
                                ),
                              );
                            },
                            isArabic: isArabic,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
        );
      },
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    final isArabic = AppLocalizations.of(context)?.locale.languageCode == 'ar';

    return Container(
      margin: const EdgeInsets.only(top: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    required VoidCallback onTap,
    required bool isArabic,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.black87, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                    textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}

