import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignUp() async {
    if (_formKey.currentState!.validate()) {
      // Validate password match
      if (_passwordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.translate('passwords_not_match') ?? 'كلمات المرور غير متطابقة'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        await _authService.signUpWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context)?.translate('account_created_success') ?? 'تم إنشاء الحساب بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pushReplacementNamed('/home');
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString();
          // Remove "Exception: " prefix if present
          if (errorMessage.startsWith('Exception: ')) {
            errorMessage = errorMessage.substring(11);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
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
  }

  Future<void> _handleGoogleSignUp() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signInWithGoogle();
      
      if (result != null && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted) {
        // User canceled
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacementNamed('/login');
  }

  void _showTermsOfService() {
      // TODO: Navigate to terms of service screen
      final loc = AppLocalizations.of(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            loc?.translate('terms_of_service') ?? 'شروط الخدمة',
            textDirection: loc?.locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          ),
          content: Text(
            loc?.translate('terms_under_development') ?? 'شروط الخدمة قيد التطوير',
            textDirection: loc?.locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                loc?.translate('agree') ?? 'موافق',
                textDirection: loc?.locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              ),
            ),
          ],
        ),
      );
  }

  void _showPrivacyPolicy() {
      // TODO: Navigate to privacy policy screen
      final loc = AppLocalizations.of(context);
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(
            loc?.translate('privacy_policy') ?? 'سياسة الخصوصية',
            textDirection: loc?.locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          ),
          content: Text(
            loc?.translate('privacy_under_development') ?? 'سياسة الخصوصية قيد التطوير',
            textDirection: loc?.locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                loc?.translate('agree') ?? 'موافق',
                textDirection: loc?.locale.languageCode == 'ar' ? TextDirection.rtl : TextDirection.ltr,
              ),
            ),
          ],
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 24),
                  
                  // Header
                  Text(
                    AppLocalizations.of(context)?.translate('signup_title') ?? 'إنشاء حساب جديد',
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
                  const SizedBox(height: 32),

                  // User Icon
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: const Color(0xFF030213),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Welcome Message
                  Text(
                    AppLocalizations.of(context)?.translate('welcome_message') ?? 'مرحباً بك في SmartTour',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                        ? TextDirection.rtl 
                        : TextDirection.ltr,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context)?.translate('signup_subtitle') ?? 'أنشئ حساباً جديداً وابدأ رحلتك السياحية',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    textAlign: TextAlign.center,
                    textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                        ? TextDirection.rtl 
                        : TextDirection.ltr,
                  ),
                  const SizedBox(height: 32),

                  // Google Sign Up Button
                  OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleSignUp,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Google Logo
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: Colors.grey[400]!, width: 1),
                          ),
                          child: const Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4285F4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          AppLocalizations.of(context)?.translate('continue_with_google') ?? 'متابعة بـ Google',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                          textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                              ? TextDirection.rtl 
                              : TextDirection.ltr,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Separator
                  Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey[300])),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          AppLocalizations.of(context)?.translate('or') ?? 'أو',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
                          textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                              ? TextDirection.rtl 
                              : TextDirection.ltr,
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey[300])),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Full Name Field
                  Text(
                    AppLocalizations.of(context)?.translate('full_name') ?? 'الاسم الكامل',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    keyboardType: TextInputType.name,
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'أدخل اسمك الكامل',
                      hintTextDirection: TextDirection.rtl,
                      prefixIcon: Icon(Icons.person_outline, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)?.translate('enter_full_name') ?? 'يرجى إدخال الاسم الكامل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Email Field
                  Text(
                    AppLocalizations.of(context)?.translate('email') ?? 'البريد الإلكتروني',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'example@email.com',
                      hintTextDirection: TextDirection.ltr,
                      prefixIcon: Icon(Icons.email_outlined, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (value) {
                      final loc = AppLocalizations.of(context);
                      if (value == null || value.isEmpty) {
                        return loc?.translate('enter_email') ?? 'يرجى إدخال البريد الإلكتروني';
                      }
                      if (!value.contains('@')) {
                        return loc?.translate('enter_valid_email') ?? 'يرجى إدخال بريد إلكتروني صحيح';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Phone Number Field
                  Text(
                    AppLocalizations.of(context)?.translate('phone') ?? 'رقم الهاتف',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: '+966 50 123 4567',
                      hintTextDirection: TextDirection.ltr,
                      prefixIcon: Icon(Icons.phone_outlined, color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return AppLocalizations.of(context)?.translate('enter_phone') ?? 'يرجى إدخال رقم الهاتف';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Password Field
                  Text(
                    AppLocalizations.of(context)?.translate('password') ?? 'كلمة المرور',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'أدخل كلمة المرور',
                      hintTextDirection: TextDirection.rtl,
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (value) {
                      final loc = AppLocalizations.of(context);
                      if (value == null || value.isEmpty) {
                        return loc?.translate('enter_password') ?? 'يرجى إدخال كلمة المرور';
                      }
                      if (value.length < 6) {
                        return loc?.translate('password_min_length') ?? 'كلمة المرور يجب أن تكون 6 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password Field
                  Text(
                    AppLocalizations.of(context)?.translate('confirm_password') ?? 'تأكيد كلمة المرور',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'أعد إدخال كلمة المرور',
                      hintTextDirection: TextDirection.rtl,
                      prefixIcon: Icon(Icons.lock_outline, color: Colors.grey[400]),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: Colors.grey[400],
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (value) {
                      final loc = AppLocalizations.of(context);
                      if (value == null || value.isEmpty) {
                        return loc?.translate('confirm_password_required') ?? 'يرجى تأكيد كلمة المرور';
                      }
                      if (value != _passwordController.text) {
                        return loc?.translate('passwords_not_match') ?? 'كلمات المرور غير متطابقة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Create Account Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSignUp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF030213),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            AppLocalizations.of(context)?.translate('create_account') ?? 'إنشاء الحساب',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                            textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                                ? TextDirection.rtl 
                                : TextDirection.ltr,
                          ),
                  ),
                  const SizedBox(height: 24),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _navigateToLogin,
                        child: Text(
                          AppLocalizations.of(context)?.translate('login') ?? 'تسجيل الدخول',
                          style: TextStyle(
                            fontSize: 14,
                            color: const Color(0xFF030213),
                            fontWeight: FontWeight.w500,
                          ),
                          textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                              ? TextDirection.rtl 
                              : TextDirection.ltr,
                        ),
                      ),
                      Text(
                        AppLocalizations.of(context)?.translate('already_have_account') ?? 'لديك حساب بالفعل؟',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                        textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                            ? TextDirection.rtl 
                            : TextDirection.ltr,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Terms and Privacy
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      textDirection: TextDirection.rtl,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.translate('by_signing_up_agree') ?? 'بالتسجيل، أنت توافق على ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                              ? TextDirection.rtl 
                              : TextDirection.ltr,
                        ),
                        GestureDetector(
                          onTap: _showTermsOfService,
                          child: Text(
                            AppLocalizations.of(context)?.translate('terms_of_service') ?? 'شروط الخدمة',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF030213),
                              fontWeight: FontWeight.w500,
                            ),
                            textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                                ? TextDirection.rtl 
                                : TextDirection.ltr,
                          ),
                        ),
                        Text(
                          ' ${AppLocalizations.of(context)?.translate('and') ?? 'و'} ',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[500],
                          ),
                          textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                              ? TextDirection.rtl 
                              : TextDirection.ltr,
                        ),
                        GestureDetector(
                          onTap: _showPrivacyPolicy,
                          child: Text(
                            AppLocalizations.of(context)?.translate('privacy_policy') ?? 'سياسة الخصوصية',
                            style: TextStyle(
                              fontSize: 12,
                              color: const Color(0xFF030213),
                              fontWeight: FontWeight.w500,
                            ),
                            textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                                ? TextDirection.rtl 
                                : TextDirection.ltr,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
        );
      },
    );
  }
}

