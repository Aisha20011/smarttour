import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../../services/admin_service.dart';
import '../../services/auth_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import 'manage_places_screen.dart';
import 'manage_trips_screen.dart';
import 'manage_categories_screen.dart';
import 'manage_faqs_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();
  Map<String, dynamic> _statistics = {};

  @override
  void initState() {
    super.initState();
    _loadStatistics();
  }

  Future<void> _loadStatistics() async {
    final stats = await _adminService.getStatistics();
    setState(() {
      _statistics = stats;
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
              loc?.translate('admin_dashboard') ?? 'لوحة التحكم',
              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () async {
                  try {
                    final authService = AuthService();
                    await authService.signOut();
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
                },
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: _loadStatistics,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Cards
                  Text(
                    loc?.translate('statistics') ?? 'الإحصائيات',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                    textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.3,
                    children: [
                      _buildStatCard(
                        context,
                        loc?.translate('places') ?? 'الأماكن',
                        _statistics['places']?.toString() ?? '0',
                        Icons.place,
                        Colors.blue,
                        isArabic,
                      ),
                      _buildStatCard(
                        context,
                        loc?.translate('trips') ?? 'الرحلات',
                        _statistics['trips']?.toString() ?? '0',
                        Icons.flight,
                        Colors.green,
                        isArabic,
                      ),
                      _buildStatCard(
                        context,
                        loc?.translate('users') ?? 'المستخدمون',
                        _statistics['users']?.toString() ?? '0',
                        Icons.people,
                        Colors.orange,
                        isArabic,
                      ),
                      _buildStatCard(
                        context,
                        loc?.translate('faqs') ?? 'الأسئلة الشائعة',
                        _statistics['faqs']?.toString() ?? '0',
                        Icons.help_outline,
                        Colors.purple,
                        isArabic,
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Management Sections
                  Text(
                    loc?.translate('management') ?? 'الإدارة',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                    textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                  const SizedBox(height: 16),
                  _buildManagementCard(
                    context,
                    loc?.translate('manage_places') ?? 'إدارة الأماكن',
                    loc?.translate('manage_places_desc') ?? 'إضافة وتعديل وحذف الأماكن',
                    Icons.place,
                    Colors.blue,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManagePlacesScreen()),
                    ),
                    isArabic,
                  ),
                  const SizedBox(height: 12),
                  _buildManagementCard(
                    context,
                    loc?.translate('manage_trips') ?? 'إدارة الرحلات',
                    loc?.translate('manage_trips_desc') ?? 'عرض وإدارة رحلات المستخدمين',
                    Icons.flight,
                    Colors.green,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageTripsScreen()),
                    ),
                    isArabic,
                  ),
                  const SizedBox(height: 12),
                  _buildManagementCard(
                    context,
                    loc?.translate('manage_categories') ?? 'إدارة الفئات',
                    loc?.translate('manage_categories_desc') ?? 'إدارة فئات الأماكن',
                    Icons.category,
                    Colors.orange,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageCategoriesScreen()),
                    ),
                    isArabic,
                  ),
                  const SizedBox(height: 12),
                  _buildManagementCard(
                    context,
                    loc?.translate('manage_faqs') ?? 'إدارة الأسئلة الشائعة',
                    loc?.translate('manage_faqs_desc') ?? 'إضافة وتعديل الأسئلة الشائعة',
                    Icons.help_outline,
                    Colors.purple,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageFAQsScreen()),
                    ),
                    isArabic,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
    bool isArabic,
  ) {
    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 6),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).textTheme.bodySmall?.color,
                ),
                textAlign: TextAlign.center,
                textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildManagementCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap,
    bool isArabic,
  ) {
    return Card(
      elevation: 2,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Theme.of(context).iconTheme.color,
        ),
        onTap: onTap,
      ),
    );
  }
}

