import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../widgets/app_drawer.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final UserService _userService = UserService();
  int _selectedIndex = 4; // Profile is selected
  User? _currentUser;
  UserData? _userData;
  StreamSubscription<UserData?>? _userDataSubscription;

  @override
  void initState() {
    super.initState();
    _currentUser = _authService.currentUser;
    _loadUserData();
  }

  @override
  void dispose() {
    _userDataSubscription?.cancel();
    super.dispose();
  }

  void _loadUserData() {
    if (_currentUser != null) {
      _userDataSubscription?.cancel();
      _userDataSubscription = _userService.getUserDataStream(_currentUser!.uid).listen(
        (data) {
          if (mounted) {
            setState(() {
              _userData = data;
            });
          }
        },
        onError: (error) {
          // If Firestore fails, use Firebase Auth data
          if (mounted && _currentUser != null) {
            setState(() {
              _userData = UserData.fromFirebaseUser(_currentUser!);
            });
          }
        },
      );
    }
  }

  String _formatMembershipDate(BuildContext context, DateTime? date) {
    final loc = AppLocalizations.of(context);
    if (date == null) return loc?.translate('not_specified') ?? 'غير محدد';
    
    final months = [
      'محرم', 'صفر', 'ربيع الأول', 'ربيع الآخر', 'جمادى الأولى', 'جمادى الآخرة',
      'رجب', 'شعبان', 'رمضان', 'شوال', 'ذو القعدة', 'ذو الحجة'
    ];
    
    // Simple conversion (for demo purposes)
    final hijriYear = date.year - 579; // Approximate conversion
    final monthIndex = date.month - 1;
    
    return '${loc?.translate('member_since') ?? 'عضو منذ'} ${months[monthIndex]} ${hijriYear} هـ';
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        final loc = AppLocalizations.of(context);
        return AlertDialog(
          title: Text(loc?.translate('logout') ?? 'تسجيل الخروج'),
          content: Text(loc?.translate('logout_confirm') ?? 'هل أنت متأكد من تسجيل الخروج؟'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(loc?.translate('cancel') ?? 'إلغاء'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(
                loc?.translate('logout') ?? 'تسجيل الخروج',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
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
              content: Text('${AppLocalizations.of(context)?.translate('logout_error') ?? 'حدث خطأ أثناء تسجيل الخروج'}: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
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
                      children: [
                        // User Info Section
                        _buildUserInfoSection(),
                        
                        // Account Section
                        _buildAccountSection(),
                        
                        // App Settings Section
                        _buildAppSettingsSection(),
                        
                        // Help Section
                        _buildHelpSection(),
                        
                        // App Info
                        _buildAppInfo(),
                        
                        // Activity Summary
                        _buildActivitySummary(),
                        
                        const SizedBox(height: 80), // Space for bottom nav
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomNavigationBar(),
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Theme.of(context).cardColor,
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
            AppLocalizations.of(context)?.translate('profile') ?? 'الملف الشخصي',
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

  Widget _buildUserInfoSection() {
    final loc = AppLocalizations.of(context);
    // Use Firestore data if available, otherwise use Firebase Auth data
    final displayName = _userData?.displayName ?? 
                        _currentUser?.displayName ?? 
                        (loc?.translate('user') ?? 'المستخدم');
    final email = _userData?.email ?? 
                  _currentUser?.email ?? 
                  (loc?.translate('not_specified') ?? 'غير محدد');
    final membershipDate = _userData?.createdAt ?? _currentUser?.metadata.creationTime;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[700]!,
            Colors.purple[700]!,
          ],
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Profile Picture
                Stack(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Theme.of(context).cardColor,
                          width: 3,
                        ),
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
                              size: 40,
                              color: Colors.white.withOpacity(0.8),
                            ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.blue[800],
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: Icon(
                          Icons.camera_alt,
                          size: 14,
                          color: Theme.of(context).cardColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                
                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleLarge?.color,
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
                      const SizedBox(height: 4),
                      Text(
                        _formatMembershipDate(context, membershipDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Statistics
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatCard(Icons.star, '4.7', AppLocalizations.of(context)?.translate('ratings') ?? 'التقييمات'),
                _buildStatCard(Icons.favorite, '28', AppLocalizations.of(context)?.translate('favorites') ?? 'المفضلة'),
                _buildStatCard(Icons.calendar_today, '12', AppLocalizations.of(context)?.translate('trips') ?? 'الرحلات'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context)?.translate('my_account') ?? 'حسابي',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          _buildMenuItem(
            icon: Icons.edit,
            title: AppLocalizations.of(context)?.translate('edit_profile') ?? 'تعديل الملف الشخصي',
            onTap: () async {
              final result = await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const EditProfileScreen(),
                ),
              );
              
              // Reload user data if profile was updated
              if (result == true) {
                _currentUser = _authService.currentUser;
                _loadUserData();
              }
            },
          ),
          _buildMenuItem(
            icon: Icons.notifications,
            title: AppLocalizations.of(context)?.translate('notifications') ?? 'الإشعارات',
            onTap: () {
              Navigator.of(context).pushNamed('/notifications');
            },
          ),
          _buildMenuItem(
            icon: Icons.shield,
            title: AppLocalizations.of(context)?.translate('privacy') ?? 'الخصوصية',
            onTap: () {
              // TODO: Navigate to privacy
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)?.translate('privacy_development') ?? 'ميزة الخصوصية قيد التطوير')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAppSettingsSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context)?.translate('app_settings') ?? 'إعدادات التطبيق',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          _buildMenuItem(
            icon: Icons.language,
            title: AppLocalizations.of(context)?.translate('language') ?? 'اللغة',
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Provider.of<LocaleProvider>(context).isArabic 
                      ? (AppLocalizations.of(context)?.translate('arabic') ?? 'العربية')
                      : (AppLocalizations.of(context)?.translate('english') ?? 'English'),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_left, color: Colors.grey),
              ],
            ),
            onTap: () {
              _showLanguageDialog(context);
            },
          ),
          _buildMenuItem(
            icon: Icons.download,
            title: AppLocalizations.of(context)?.translate('saved_maps') ?? 'الخرائط المحفوظة',
            onTap: () {
              // TODO: Navigate to saved maps
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)?.translate('saved_maps_development') ?? 'ميزة الخرائط المحفوظة قيد التطوير')),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.settings,
            title: AppLocalizations.of(context)?.translate('general_settings') ?? 'الإعدادات العامة',
            onTap: () {
              // TODO: Navigate to general settings
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)?.translate('feature_development') ?? 'ميزة الإعدادات العامة قيد التطوير')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildHelpSection() {
    return Container(
      margin: const EdgeInsets.only(top: 16),
      color: Theme.of(context).cardColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              AppLocalizations.of(context)?.translate('help') ?? 'المساعدة',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
          ),
          _buildMenuItem(
            icon: Icons.help_outline,
            title: AppLocalizations.of(context)?.translate('support') ?? 'الدعم والمساعدة',
            onTap: () {
              // TODO: Navigate to support
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(AppLocalizations.of(context)?.translate('support_development') ?? 'ميزة الدعم والمساعدة قيد التطوير')),
              );
            },
          ),
          _buildMenuItem(
            icon: Icons.logout,
            title: AppLocalizations.of(context)?.translate('logout') ?? 'تسجيل الخروج',
            titleColor: Colors.red,
            onTap: _handleLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    Color? titleColor,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: Colors.grey[200]!),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: titleColor ?? Colors.black87, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  color: titleColor ?? Colors.black87,
                ),
              ),
            ),
            if (trailing != null) trailing,
            if (trailing == null)
              const Icon(Icons.chevron_left, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildAppInfo() {
    return Container(
      margin: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          const Text(
            'SmartTour',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)?.translate('app_tagline') ?? 'دليلك السياحي الذكي',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${AppLocalizations.of(context)?.translate('app_version') ?? 'الإصدار'} 1.0.0',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivitySummary() {
    return Container(
      margin: const EdgeInsets.only(top: 24, left: 16, right: 16, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)?.translate('activity_summary') ?? 'ملخص النشاط',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            AppLocalizations.of(context)?.translate('last_trip') ?? 'آخر رحلة',
            'رحلة الرياض التاريخية',
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            AppLocalizations.of(context)?.translate('favorite_place') ?? 'المكان المفضل',
            'المسجد النبوي الشريف',
          ),
          const SizedBox(height: 12),
          _buildActivityItem(
            AppLocalizations.of(context)?.translate('total_km') ?? 'إجمالي الكيلومترات',
            '245 ${AppLocalizations.of(context)?.translate('km') ?? 'كم'}',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
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
              Navigator.of(context).pushReplacementNamed('/trips');
              break;
            case 3:
              Navigator.of(context).pushReplacementNamed('/recommendations');
              break;
            case 4:
              // Already on profile
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

  void _showLanguageDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Consumer<LocaleProvider>(
        builder: (context, localeProvider, child) {
          final localizations = AppLocalizations.of(context);
          return AlertDialog(
            title: Text(localizations?.translate('language') ?? 'اللغة'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RadioListTile<Locale>(
                  title: Text(localizations?.translate('arabic') ?? 'العربية'),
                  value: const Locale('ar'),
                  groupValue: localeProvider.locale,
                  onChanged: (Locale? value) {
                    if (value != null) {
                      localeProvider.setLocale(value);
                      Navigator.of(context).pop();
                    }
                  },
                ),
                RadioListTile<Locale>(
                  title: Text(localizations?.translate('english') ?? 'English'),
                  value: const Locale('en'),
                  groupValue: localeProvider.locale,
                  onChanged: (Locale? value) {
                    if (value != null) {
                      localeProvider.setLocale(value);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(localizations?.translate('cancel') ?? 'إلغاء'),
              ),
            ],
          );
        },
      ),
    );
  }
}

