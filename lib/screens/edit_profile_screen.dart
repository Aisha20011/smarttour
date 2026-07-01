import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/auth_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _userService = UserService();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isLoadingData = true;
  User? _currentUser;
  UserData? _userData;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    try {
      setState(() {
        _isLoadingData = true;
      });

      _currentUser = _authService.currentUser;
      
      if (_currentUser != null) {
        // Try to get data from Firestore first
        _userData = await _userService.getUserData(_currentUser!.uid);
        
        // If no Firestore data, use Firebase Auth data
        if (_userData == null) {
          _userData = UserData.fromFirebaseUser(_currentUser!);
        }

        // Populate form fields
        _nameController.text = _userData?.displayName ?? _currentUser!.displayName ?? '';
        _emailController.text = _userData?.email ?? _currentUser!.email ?? '';
        _phoneController.text = _userData?.phoneNumber ?? _currentUser!.phoneNumber ?? '';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('خطأ في تحميل البيانات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingData = false;
        });
      }
    }
  }

  Future<void> _handleSave() async {
    if (_formKey.currentState!.validate()) {
      if (_currentUser == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.translate('user_not_authenticated') ?? 'المستخدم غير مسجل الدخول'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        final loc = AppLocalizations.of(context);
        
        // Update display name in Firebase Auth
        if (_nameController.text.trim() != _currentUser!.displayName) {
          await _currentUser!.updateDisplayName(_nameController.text.trim());
          await _currentUser!.reload();
          _currentUser = _authService.currentUser;
        }

        // Update user data in Firestore
        await _userService.updateUserData(
          displayName: _nameController.text.trim().isEmpty ? null : _nameController.text.trim(),
          phoneNumber: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(loc?.translate('profile_updated_success') ?? 'تم تحديث الملف الشخصي بنجاح'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(true); // Return true to indicate success
        }
      } catch (e) {
        if (mounted) {
          String errorMessage = e.toString();
          if (errorMessage.startsWith('Exception: ')) {
            errorMessage = errorMessage.substring(11);
          }
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ في تحديث الملف الشخصي: $errorMessage'),
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

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        final loc = AppLocalizations.of(context);
        final isArabic = loc?.locale.languageCode == 'ar';

        return Scaffold(
          appBar: AppBar(
            title: Text(loc?.translate('edit_profile') ?? 'تعديل الملف الشخصي'),
            backgroundColor: const Color(0xFF030213),
            foregroundColor: Colors.white,
          ),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: _isLoadingData
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Profile Picture Section
                        Center(
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.grey[300],
                                backgroundImage: _currentUser?.photoURL != null
                                    ? NetworkImage(_currentUser!.photoURL!)
                                    : null,
                                child: _currentUser?.photoURL == null
                                    ? Icon(
                                        Icons.person,
                                        size: 60,
                                        color: Colors.grey[600],
                                      )
                                    : null,
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF030213),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: TextButton(
                            onPressed: () {
                              // TODO: Implement image picker
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(loc?.translate('feature_development') ?? 'ميزة تغيير الصورة قيد التطوير'),
                                ),
                              );
                            },
                            child: Text(
                              loc?.translate('change_photo') ?? 'تغيير الصورة',
                              style: const TextStyle(color: Color(0xFF030213)),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Full Name Field
                        Text(
                          loc?.translate('full_name') ?? 'الاسم الكامل',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                          decoration: InputDecoration(
                            hintText: loc?.translate('full_name_hint') ?? 'أدخل اسمك الكامل',
                            hintTextDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                            prefixIcon: const Icon(Icons.person),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return loc?.translate('enter_full_name') ?? 'يرجى إدخال الاسم الكامل';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Email Field (Read-only)
                        Text(
                          loc?.translate('email') ?? 'البريد الإلكتروني',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          enabled: false,
                          decoration: InputDecoration(
                            hintText: loc?.translate('email') ?? 'البريد الإلكتروني',
                            prefixIcon: const Icon(Icons.email),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey[200],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          loc?.translate('email_cannot_change') ?? 'لا يمكن تغيير البريد الإلكتروني',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Phone Number Field
                        Text(
                          loc?.translate('phone') ?? 'رقم الهاتف',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _phoneController,
                          textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                          keyboardType: TextInputType.phone,
                          decoration: InputDecoration(
                            hintText: loc?.translate('phone_hint') ?? 'أدخل رقم الهاتف',
                            hintTextDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
                            prefixIcon: const Icon(Icons.phone),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Save Button
                        ElevatedButton(
                          onPressed: _isLoading ? null : _handleSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF030213),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
                                  loc?.translate('save_changes') ?? 'حفظ التغييرات',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }
}



