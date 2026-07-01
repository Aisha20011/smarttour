import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<OnboardingData> _getPages(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return [
      OnboardingData(
        icon: Icons.location_on,
        title: loc?.translate('onboarding_title_1') ?? 'اكتشف الأماكن المذهلة',
        description: loc?.translate('onboarding_desc_1') ?? 'استكشف المعالم التاريخية والثقافية مع دليل سياحي ذكي يساعدك على اكتشاف كنوز مدينتك',
        color: const Color(0xFF3B82F6), // Blue
      ),
      OnboardingData(
        icon: Icons.camera_alt,
        title: loc?.translate('onboarding_title_2') ?? 'تجربة الواقع المعزز',
        description: loc?.translate('onboarding_desc_2') ?? 'وجه كاميرتك نحو أي معلم واحصل على معلومات تفاعلية وغنية بالوسائط المتعددة',
        color: const Color(0xFFA855F7), // Purple
      ),
      OnboardingData(
        icon: Icons.calendar_today,
        title: loc?.translate('onboarding_title_3') ?? 'خطط رحلتك المثالية',
        description: loc?.translate('onboarding_desc_3') ?? 'أنشئ جدولاً سياحياً مخصصاً واحصل على توصيات ذكية بناءً على تفضيلاتك',
        color: const Color(0xFF10B981), // Green
      ),
      OnboardingData(
        icon: Icons.favorite,
        title: loc?.translate('onboarding_title_4') ?? 'احفظ مفضلاتك',
        description: loc?.translate('onboarding_desc_4') ?? 'أضف الأماكن المميزة إلى قائمة المفضلة واستمتع بتجربة سياحية شخصية ومخصصة',
        color: const Color(0xFFEF4444), // Red
      ),
    ];
  }

  void _nextPage(BuildContext context) {
    final pages = _getPages(context);
    if (_currentPage < pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _completeOnboarding() async {
    // Mark onboarding as completed
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_completed', true);
    } catch (e) {
      print('Error saving onboarding status: $e');
    }
    
    // Navigate to login
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Main Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: _getPages(context).length,
                itemBuilder: (context, index) {
                  return _buildPage(_getPages(context)[index]);
                },
              ),
            ),

            // Navigation Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Column(
                children: [
                  // Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _getPages(context).length,
                      (index) => _buildPageIndicator(index == _currentPage),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Navigation Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Previous Button
                      TextButton(
                        onPressed: _currentPage > 0 ? _previousPage : null,
                        style: TextButton.styleFrom(
                          foregroundColor: _currentPage > 0
                              ? Colors.grey[700]
                              : Colors.grey[400],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.chevron_right,
                              size: 20,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              AppLocalizations.of(context)?.translate('previous') ?? 'السابق',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ],
                        ),
                      ),

                      // Next/Start Button
                      ElevatedButton(
                        onPressed: () => _nextPage(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF030213),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _currentPage == _getPages(context).length - 1
                                  ? (AppLocalizations.of(context)?.translate('get_started') ?? 'ابدأ الآن')
                                  : (AppLocalizations.of(context)?.translate('next') ?? 'التالي'),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.chevron_left,
                              size: 20,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // Skip Button
                  if (_currentPage < _getPages(context).length - 1)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: TextButton(
                        onPressed: _skipOnboarding,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.grey[500],
                        ),
                        child: Text(
                          AppLocalizations.of(context)?.translate('skip') ?? 'تخطي',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
        );
      },
    );
  }

  Widget _buildPage(OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icon
          Container(
            width: 128,
            height: 128,
            decoration: BoxDecoration(
              color: data.color,
              shape: BoxShape.circle,
            ),
            child: Icon(
              data.icon,
              size: 64,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 48),

          // Title
          Text(
            data.title,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
            textAlign: TextAlign.center,
            textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                ? TextDirection.rtl 
                : TextDirection.ltr,
          ),
          const SizedBox(height: 16),

          // Description
          Text(
            data.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              height: 1.5,
            ),
            textAlign: TextAlign.center,
            textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                ? TextDirection.rtl 
                : TextDirection.ltr,
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(bool isActive) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.symmetric(horizontal: 4),
      height: 8,
      width: isActive ? 32 : 8,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF030213) : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class OnboardingData {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  OnboardingData({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}

