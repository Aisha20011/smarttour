import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';

class AppDrawer extends StatefulWidget {
  const AppDrawer({super.key});

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  final AuthService _authService = AuthService();

  User? get _currentUser => _authService.currentUser;

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من تسجيل الخروج؟'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'تسجيل الخروج',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _authService.signOut();
        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('حدث خطأ أثناء تسجيل الخروج: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayName = _currentUser?.displayName ?? 'المستخدم';
    final email = _currentUser?.email ?? 'user@google.com';
    final isGoogleUser = _currentUser?.providerData.any((p) => p.providerId == 'google.com') ?? false;

    return Drawer(
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: Border(
                bottom: BorderSide(color: Theme.of(context).dividerColor),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'القائمة الرئيسية',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.titleLarge?.color,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_forward),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // User Info Banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.blue[900]!,
                  Colors.purple[900]!,
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: _currentUser?.photoURL != null
                      ? ClipOval(
                          child: Image.network(
                            _currentUser!.photoURL!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          size: 30,
                          color: Colors.white.withOpacity(0.8),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isGoogleUser ? 'مستخدم google' : displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: const Text(
                          'مستخدم نشط',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // Account Section
                _buildSectionHeader('الحساب'),
                _buildMenuItem(
                  icon: Icons.person,
                  title: 'الملف الشخصي',
                  subtitle: 'إدارة معلومات الحساب',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacementNamed('/profile');
                  },
                ),
                _buildMenuItem(
                  icon: Icons.favorite,
                  title: AppLocalizations.of(context)?.translate('favorites') ?? 'المفضلة',
                  subtitle: AppLocalizations.of(context)?.translate('saved_places') ?? 'أماكنك المحفوظة',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/favorites');
                  },
                ),
                _buildMenuItem(
                  icon: Icons.calendar_today,
                  title: 'رحلاتي',
                  subtitle: 'خطط الرحلات المحفوظة',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacementNamed('/trips');
                  },
                ),

                // Services Section
                _buildSectionHeader('الخدمات'),
                _buildMenuItem(
                  icon: Icons.trending_up,
                  title: 'التوصيات الذكية',
                  subtitle: 'اكتشف أماكن جديدة',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacementNamed('/recommendations');
                  },
                ),
                _buildMenuItem(
                  icon: Icons.map,
                  title: 'الخريطة التفاعلية',
                  subtitle: 'استكشف المنطقة',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushReplacementNamed('/map');
                  },
                ),
                _buildMenuItem(
                  icon: Icons.download,
                  title: AppLocalizations.of(context)?.translate('offline_mode') ?? 'الوضع دون اتصال',
                  subtitle: AppLocalizations.of(context)?.translate('offline_mode_subtitle') ?? 'تحميل الخرائط والبيانات',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/offline');
                  },
                ),
                _buildMenuItem(
                  icon: Icons.notifications,
                  title: 'الإشعارات',
                  subtitle: 'إعدادات التنبيهات',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/notifications');
                  },
                ),

                // Settings Section
                _buildSectionHeader('الإعدادات'),
                _buildMenuItem(
                  icon: Icons.settings,
                  title: AppLocalizations.of(context)?.translate('general_settings') ?? 'الإعدادات العامة',
                  subtitle: AppLocalizations.of(context)?.translate('language_preferences') ?? 'اللغة والتفضيلات',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/settings');
                  },
                ),
                _buildMenuItem(
                  icon: Icons.shield,
                  title: AppLocalizations.of(context)?.translate('privacy_security') ?? 'الخصوصية والأمان',
                  subtitle: AppLocalizations.of(context)?.translate('data_protection') ?? 'إدارة البيانات والحماية',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/privacy');
                  },
                ),
                Consumer<ThemeProvider>(
                  builder: (context, themeProvider, child) {
                    return _buildMenuItem(
                      icon: Icons.dark_mode,
                      title: AppLocalizations.of(context)?.translate('night_mode') ?? 'الوضع الليلي',
                      subtitle: AppLocalizations.of(context)?.translate('change_appearance') ?? 'تغيير مظهر التطبيق',
                      trailing: Switch(
                        value: themeProvider.isDarkMode,
                        onChanged: (value) {
                          themeProvider.toggleTheme();
                        },
                      ),
                      onTap: () {
                        themeProvider.toggleTheme();
                      },
                    );
                  },
                ),

                // Help Section
                _buildSectionHeader('المساعدة والدعم'),
                _buildMenuItem(
                  icon: Icons.help_outline,
                  title: AppLocalizations.of(context)?.translate('help_faq') ?? 'المساعدة والأسئلة الشائعة',
                  subtitle: AppLocalizations.of(context)?.translate('get_help') ?? 'احصل على المساعدة',
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pushNamed('/help');
                  },
                ),
                _buildMenuItem(
                  icon: Icons.chat_bubble_outline,
                  title: 'اتصل بنا',
                  subtitle: 'تواصل مع فريق الدعم',
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: Navigate to contact
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ميزة الاتصال بنا قيد التطوير')),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.star_outline,
                  title: 'قيم التطبيق',
                  subtitle: 'شاركنا رأيك',
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: Rate app
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ميزة تقييم التطبيق قيد التطوير')),
                    );
                  },
                ),
                _buildMenuItem(
                  icon: Icons.share,
                  title: 'شارك التطبيق',
                  subtitle: 'ادع أصدقاءك',
                  onTap: () {
                    Navigator.of(context).pop();
                    // TODO: Share app
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('ميزة مشاركة التطبيق قيد التطوير')),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ElevatedButton.icon(
                    onPressed: _handleLogout,
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'تسجيل الخروج',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // App Info
                const Center(
                  child: Column(
                    children: [
                      Text(
                        'SmartTour v1.0.0',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'دليلك السياحي الذكي',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(
              bottom: BorderSide(color: Theme.of(context).dividerColor),
            ),
          ),
        child: Row(
          children: [
            Icon(icon, color: Theme.of(context).iconTheme.color, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).textTheme.titleMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            if (badge != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  badge,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (trailing != null) trailing,
            if (trailing == null && badge == null)
              const Icon(Icons.chevron_left, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}

