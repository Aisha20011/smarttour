import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:ui' as ui;
import '../widgets/app_drawer.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../services/favorites_service.dart';
import '../services/trips_service.dart';

class PrivacySecurityScreen extends StatefulWidget {
  const PrivacySecurityScreen({super.key});

  @override
  State<PrivacySecurityScreen> createState() => _PrivacySecurityScreenState();
}

class _PrivacySecurityScreenState extends State<PrivacySecurityScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  final FavoritesService _favoritesService = FavoritesService();
  final TripsService _tripsService = TripsService();
  bool _isDeleting = false;

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
              loc?.translate('privacy_security') ?? 'الخصوصية والأمان',
              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
            centerTitle: true,
          ),
          body: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Security
                _buildSection(
                  context,
                  loc?.translate('account_security') ?? 'أمان الحساب',
                  [
                    _buildInfoTile(
                      context,
                      icon: Icons.lock,
                      title: loc?.translate('password') ?? 'كلمة المرور',
                      subtitle: loc?.translate('change_password_desc') ??
                          'تغيير كلمة المرور لحسابك',
                      trailing: const Icon(Icons.chevron_left, color: Colors.grey),
                      onTap: () {
                        _showChangePasswordDialog(context);
                      },
                      isArabic: isArabic,
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.email,
                      title: loc?.translate('email') ?? 'البريد الإلكتروني',
                      subtitle: _authService.currentUser?.email ?? '',
                      trailing: const Icon(Icons.chevron_left, color: Colors.grey),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              loc?.translate('email_change_info') ??
                                  'للتغيير، يرجى استخدام إعدادات Firebase',
                            ),
                          ),
                        );
                      },
                      isArabic: isArabic,
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.verified_user,
                      title: loc?.translate('account_verification') ?? 'التحقق من الحساب',
                      subtitle: loc?.translate('account_verification_desc') ??
                          'حالة التحقق من بريدك الإلكتروني',
                      trailing: _authService.currentUser?.emailVerified == true
                          ? Icon(Icons.check_circle, color: Colors.green)
                          : Icon(Icons.cancel, color: Colors.orange),
                      onTap: () {
                        if (_authService.currentUser?.emailVerified != true) {
                          _sendVerificationEmail(context);
                        }
                      },
                      isArabic: isArabic,
                    ),
                  ],
                ),

                // Data Management
                _buildSection(
                  context,
                  loc?.translate('data_management') ?? 'إدارة البيانات',
                  [
                    _buildInfoTile(
                      context,
                      icon: Icons.download,
                      title: loc?.translate('export_data') ?? 'تصدير البيانات',
                      subtitle: loc?.translate('export_data_desc') ??
                          'تحميل نسخة من بياناتك',
                      trailing: const Icon(Icons.chevron_left, color: Colors.grey),
                      onTap: () {
                        _exportUserData(context);
                      },
                      isArabic: isArabic,
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.delete_sweep,
                      title: loc?.translate('clear_cache') ?? 'مسح الذاكرة المؤقتة',
                      subtitle: loc?.translate('clear_cache_desc') ??
                          'حذف البيانات المحلية المؤقتة',
                      trailing: const Icon(Icons.chevron_left, color: Colors.grey),
                      onTap: () {
                        _clearCache(context);
                      },
                      isArabic: isArabic,
                    ),
                  ],
                ),

                // Privacy Settings
                _buildSection(
                  context,
                  loc?.translate('privacy_settings') ?? 'إعدادات الخصوصية',
                  [
                    _buildInfoTile(
                      context,
                      icon: Icons.location_off,
                      title: loc?.translate('location_privacy') ?? 'خصوصية الموقع',
                      subtitle: loc?.translate('location_privacy_desc') ??
                          'إدارة كيفية استخدام موقعك',
                      trailing: const Icon(Icons.chevron_left, color: Colors.grey),
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              loc?.translate('location_privacy_info') ??
                                  'يمكنك إدارة أذونات الموقع من إعدادات الجهاز',
                            ),
                          ),
                        );
                      },
                      isArabic: isArabic,
                    ),
                    _buildInfoTile(
                      context,
                      icon: Icons.analytics,
                      title: loc?.translate('data_analytics') ?? 'تحليل البيانات',
                      subtitle: loc?.translate('data_analytics_desc') ??
                          'مساعدة في تحسين التطبيق',
                      trailing: Switch(
                        value: true, // Default enabled
                        onChanged: (value) {
                          // TODO: Implement analytics toggle
                        },
                      ),
                      onTap: () {
                        // Toggle analytics
                      },
                      isArabic: isArabic,
                    ),
                  ],
                ),

                // Danger Zone
                _buildSection(
                  context,
                  loc?.translate('danger_zone') ?? 'منطقة الخطر',
                  [
                    _buildDangerTile(
                      context,
                      icon: Icons.delete_forever,
                      title: loc?.translate('delete_account') ?? 'حذف الحساب',
                      subtitle: loc?.translate('delete_account_desc') ??
                          'حذف حسابك وكل بياناتك بشكل دائم',
                      onTap: () {
                        _showDeleteAccountDialog(context);
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

  Widget _buildInfoTile(
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

  Widget _buildDangerTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
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
            Icon(icon, color: Colors.red, size: 24),
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
                      color: Colors.red,
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
            const Icon(Icons.chevron_left, color: Colors.red),
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isArabic = loc?.locale.languageCode == 'ar';
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          loc?.translate('change_password') ?? 'تغيير كلمة المرور',
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: loc?.translate('new_password') ?? 'كلمة المرور الجديدة',
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: loc?.translate('confirm_new_password') ?? 'تأكيد كلمة المرور',
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc?.translate('cancel') ?? 'إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              if (passwordController.text.isEmpty ||
                  passwordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      loc?.translate('password_mismatch') ??
                          'كلمات المرور غير متطابقة',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              try {
                await _authService.currentUser?.updatePassword(passwordController.text);
                if (mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        loc?.translate('password_changed') ?? 'تم تغيير كلمة المرور بنجاح',
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
            child: Text(loc?.translate('change') ?? 'تغيير'),
          ),
        ],
      ),
    );
  }

  Future<void> _sendVerificationEmail(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    try {
      await _authService.currentUser?.sendEmailVerification();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc?.translate('verification_email_sent') ??
                  'تم إرسال بريد التحقق',
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
  }

  Future<void> _exportUserData(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    try {
      final user = _authService.currentUser;
      if (user == null) return;

      // Get user data
      final userData = await _userService.getUserData(user.uid);
      final favorites = await _favoritesService.getFavoritesCount();
      final trips = await _tripsService.getTripsByStatus('all');

      // In a real app, you would create a JSON file and allow download
      // For now, just show a message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc?.translate('data_export_info') ??
                  'سيتم إضافة ميزة تصدير البيانات قريباً',
            ),
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
  }

  Future<void> _clearCache(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    final isArabic = loc?.locale.languageCode == 'ar';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          loc?.translate('clear_cache') ?? 'مسح الذاكرة المؤقتة',
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
        content: Text(
          loc?.translate('clear_cache_confirmation') ??
              'هل أنت متأكد من مسح الذاكرة المؤقتة؟',
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(loc?.translate('cancel') ?? 'إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(
              loc?.translate('clear') ?? 'مسح',
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      // Clear SharedPreferences cache (except important settings)
      try {
        final prefs = await SharedPreferences.getInstance();
        // Keep language and auth settings
        await prefs.remove('offline_enabled');
        // Add more cache clearing as needed

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                loc?.translate('cache_cleared') ?? 'تم مسح الذاكرة المؤقتة',
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
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isArabic = loc?.locale.languageCode == 'ar';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          loc?.translate('delete_account') ?? 'حذف الحساب',
          style: const TextStyle(color: Colors.red),
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
        content: Text(
          loc?.translate('delete_account_warning') ??
              'تحذير: سيتم حذف حسابك وكل بياناتك بشكل دائم ولا يمكن التراجع عن هذا الإجراء.',
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(loc?.translate('cancel') ?? 'إلغاء'),
          ),
          TextButton(
            onPressed: _isDeleting ? null : () => _deleteAccount(context),
            child: _isDeleting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    loc?.translate('delete') ?? 'حذف',
                    style: const TextStyle(color: Colors.red),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final loc = AppLocalizations.of(context);
    setState(() {
      _isDeleting = true;
    });

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      // Delete user data from Firestore
      await _userService.deleteUserData(user.uid);

      // Delete user account from Firebase Auth
      await user.delete();

      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc?.translate('account_deleted') ?? 'تم حذف الحساب بنجاح',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isDeleting = false;
      });

      if (mounted) {
        Navigator.of(context).pop(); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${loc?.translate('delete_account_error') ?? 'خطأ في حذف الحساب'}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

