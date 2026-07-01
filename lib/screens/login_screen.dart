import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/auth_service.dart';
import '../services/admin_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _adminService = AdminService();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkAuthState();
    _loadRememberedEmail();
  }

  // Check if user is already logged in
  void _checkAuthState() {
    // Use a small delay to ensure the widget is fully built
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted && _authService.currentUser != null) {
        // User is already logged in, navigate to home
        Navigator.of(context).pushReplacementNamed('/home');
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Load remembered email from SharedPreferences
  Future<void> _loadRememberedEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rememberedEmail = prefs.getString('remembered_email');
      final rememberMe = prefs.getBool('remember_me') ?? false;
      final rememberedPassword = prefs.getString('remembered_password');
      
      if (rememberedEmail != null && rememberMe) {
        setState(() {
          _rememberMe = true;
          _emailController.text = rememberedEmail;
          if (rememberedPassword != null) {
            _passwordController.text = rememberedPassword;
          }
        });
        
        // Auto login if remember me is enabled
        if (rememberedPassword != null && rememberedPassword.isNotEmpty) {
          // Wait a bit for UI to settle
          await Future.delayed(const Duration(milliseconds: 500));
          if (mounted) {
            await _autoLogin(rememberedEmail, rememberedPassword);
          }
        }
      }
    } catch (e) {
      // Silently fail if there's an error loading preferences
      print('Error loading remembered email: $e');
    }
  }

  // Auto login with remembered credentials
  Future<void> _autoLogin(String email, String password) async {
    try {
      setState(() {
        _isLoading = true;
      });

      await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (mounted) {
        // Check if user is admin
        final isAdmin = await _adminService.isAdmin();
        if (isAdmin) {
          Navigator.of(context).pushReplacementNamed('/admin');
        } else {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      // If auto login fails, just clear the password and let user login manually
      if (mounted) {
        setState(() {
          _passwordController.clear();
          _isLoading = false;
        });
        // Don't show error dialog for auto login failures
        print('Auto login failed: $e');
      }
    }
  }

  // Save email and password to SharedPreferences
  Future<void> _saveRememberedEmail(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_rememberMe) {
        await prefs.setString('remembered_email', email);
        await prefs.setString('remembered_password', password);
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('remembered_email');
        await prefs.remove('remembered_password');
        await prefs.setBool('remember_me', false);
      }
    } catch (e) {
      print('Error saving remembered email: $e');
    }
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final email = _emailController.text.trim();
        await _authService.signInWithEmailAndPassword(
          email: email,
          password: _passwordController.text,
        );

        // Save email and password if "Remember Me" is checked
        await _saveRememberedEmail(email, _passwordController.text);

        if (mounted) {
          // Check if user is admin
          final isAdmin = await _adminService.isAdmin();
          if (isAdmin) {
            Navigator.of(context).pushReplacementNamed('/admin');
          } else {
            Navigator.of(context).pushReplacementNamed('/home');
          }
        }
      } catch (e) {
        if (mounted) {
          _showErrorDialog(e.toString());
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
  
  void _showErrorDialog(String errorCode) {
    final loc = AppLocalizations.of(context);
    String errorMessage;
    IconData errorIcon;
    Color errorColor;
    
    // Map error codes to user-friendly messages
    switch (errorCode) {
      case 'user-not-found':
        errorMessage = loc?.translate('user_not_found') ?? 'المستخدم غير موجود. يرجى التحقق من البريد الإلكتروني';
        errorIcon = Icons.person_off_outlined;
        errorColor = Colors.orange;
        break;
      case 'wrong-password':
        errorMessage = loc?.translate('wrong_password') ?? 'كلمة المرور غير صحيحة. يرجى المحاولة مرة أخرى';
        errorIcon = Icons.lock_outline;
        errorColor = Colors.red;
        break;
      case 'invalid-email-format':
        errorMessage = loc?.translate('invalid_email_format') ?? 'صيغة البريد الإلكتروني غير صحيحة';
        errorIcon = Icons.email_outlined;
        errorColor = Colors.orange;
        break;
      case 'user-disabled':
        errorMessage = loc?.translate('user_disabled') ?? 'تم تعطيل هذا الحساب. يرجى الاتصال بالدعم';
        errorIcon = Icons.block_outlined;
        errorColor = Colors.red;
        break;
      case 'too-many-requests':
        errorMessage = loc?.translate('too_many_requests') ?? 'تم إرسال طلبات كثيرة جداً. يرجى المحاولة لاحقاً';
        errorIcon = Icons.schedule_outlined;
        errorColor = Colors.orange;
        break;
      case 'network-error':
        errorMessage = loc?.translate('network_error') ?? 'فشل الاتصال بالشبكة. يرجى التحقق من اتصالك بالإنترنت';
        errorIcon = Icons.wifi_off_outlined;
        errorColor = Colors.red;
        break;
      case 'operation-not-allowed':
        errorMessage = loc?.translate('operation_not_allowed') ?? 'هذه العملية غير مسموحة';
        errorIcon = Icons.block_outlined;
        errorColor = Colors.red;
        break;
      default:
        errorMessage = loc?.translate('login_failed') ?? 'فشل تسجيل الدخول. يرجى المحاولة مرة أخرى';
        errorIcon = Icons.error_outline;
        errorColor = Colors.red;
    }
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(errorIcon, color: errorColor, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                loc?.translate('error_occurred') ?? 'حدث خطأ',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                    ? TextDirection.rtl 
                    : TextDirection.ltr,
              ),
            ),
          ],
        ),
        content: Text(
          errorMessage,
          style: const TextStyle(fontSize: 14),
          textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
              ? TextDirection.rtl 
              : TextDirection.ltr,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              loc?.translate('agree') ?? 'موافق',
              style: TextStyle(color: errorColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleGoogleLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _authService.signInWithGoogle();
      
      if (result != null && mounted) {
        Navigator.of(context).pushReplacementNamed('/home');
      } else if (mounted) {
        // User canceled
        final loc = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              loc?.translate('google_signin_cancelled') ?? 'تم إلغاء تسجيل الدخول',
              textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                  ? TextDirection.rtl 
                  : TextDirection.ltr,
            ),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        _showErrorDialog(e.toString());
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleForgotPassword() async {
      if (_emailController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.translate('enter_email_first') ?? 'يرجى إدخال البريد الإلكتروني أولاً'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

    try {
      await _authService.resetPassword(_emailController.text.trim());
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.translate('password_reset_sent') ?? 'تم إرسال رابط إعادة تعيين كلمة المرور إلى بريدك الإلكتروني'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final loc = AppLocalizations.of(context);
        String errorMessage = loc?.translate('password_reset_failed') ?? 'فشل إرسال رابط إعادة تعيين كلمة المرور';
        
        // Try to get a more specific error message
        if (e.toString().contains('user-not-found')) {
          errorMessage = loc?.translate('user_not_found') ?? 'المستخدم غير موجود. يرجى التحقق من البريد الإلكتروني';
        } else if (e.toString().contains('invalid-email')) {
          errorMessage = loc?.translate('invalid_email_format') ?? 'صيغة البريد الإلكتروني غير صحيحة';
        } else if (e.toString().contains('network')) {
          errorMessage = loc?.translate('network_error') ?? 'فشل الاتصال بالشبكة. يرجى التحقق من اتصالك بالإنترنت';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage,
                    textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                        ? TextDirection.rtl 
                        : TextDirection.ltr,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }

  void _navigateToSignUp() {
    Navigator.of(context).pushReplacementNamed('/signup');
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
                    AppLocalizations.of(context)?.translate('login_title') ?? 'تسجيل الدخول',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.right,
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
                    AppLocalizations.of(context)?.translate('login_subtitle') ?? 'سجل دخولك للمتابعة واستكشاف الأماكن المذهلة',
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

                  // Google Sign In Button
                  OutlinedButton(
                    onPressed: _isLoading ? null : _handleGoogleLogin,
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
                        // Google Logo - Simple G icon
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(2),
                            border: Border.all(color: Colors.grey[400]!, width: 1),
                          ),
                          child: Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF4285F4),
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

                  // Email Field
                  Text(
                    AppLocalizations.of(context)?.translate('email') ?? 'البريد الإلكتروني',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.right,
                    textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                        ? TextDirection.rtl 
                        : TextDirection.ltr,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: 'example@gmail.com',
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

                  // Password Field
                  Text(
                    AppLocalizations.of(context)?.translate('password') ?? 'كلمة المرور',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                    textAlign: TextAlign.right,
                    textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                        ? TextDirection.rtl 
                        : TextDirection.ltr,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.right,
                    decoration: InputDecoration(
                      hintText: AppLocalizations.of(context)?.translate('enter_password') ?? 'أدخل كلمة المرور',
                      hintTextDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                          ? TextDirection.rtl 
                          : TextDirection.ltr,
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
                  const SizedBox(height: 16),

                  // Remember Me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Forgot Password
                      TextButton(
                        onPressed: _handleForgotPassword,
                        child: Text(
                          AppLocalizations.of(context)?.translate('forgot_password') ?? 'نسيت كلمة المرور؟',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                          textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                              ? TextDirection.rtl 
                              : TextDirection.ltr,
                        ),
                      ),
                      // Remember Me
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            AppLocalizations.of(context)?.translate('remember_me') ?? 'تذكرني',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                            textDirection: AppLocalizations.of(context)?.locale.languageCode == 'ar' 
                                ? TextDirection.rtl 
                                : TextDirection.ltr,
                          ),
                          const SizedBox(width: 8),
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) async {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                              // Update saved preference immediately
                              if (!_rememberMe) {
                                // If unchecked, remove saved email
                                final prefs = await SharedPreferences.getInstance();
                                await prefs.remove('remembered_email');
                                await prefs.setBool('remember_me', false);
                              }
                            },
                            activeColor: const Color(0xFF030213),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Login Button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
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
                            AppLocalizations.of(context)?.translate('login') ?? 'تسجيل الدخول',
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

                  // Sign Up Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      TextButton(
                        onPressed: _navigateToSignUp,
                        child: Text(
                          AppLocalizations.of(context)?.translate('sign_up') ?? 'إنشاء حساب جديد',
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
                        AppLocalizations.of(context)?.translate('dont_have_account') ?? 'ليس لديك حساب؟',
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


