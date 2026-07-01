# SmartTour - دليلك السياحي الذكي
## SmartTour - Your Smart Tourist Guide

---

## 📋 جدول المحتويات | Table of Contents

1. [نظرة عامة | Overview](#نظرة-عامة--overview)
2. [أهداف المشروع | Project Objectives](#أهداف-المشروع--project-objectives)
3. [الميزات الرئيسية | Key Features](#الميزات-الرئيسية--key-features)
4. [التقنيات المستخدمة | Technologies Used](#التقنيات-المستخدمة--technologies-used)
5. [البنية المعمارية | Architecture](#البنية-المعمارية--architecture)
6. [الشاشات والواجهات | Screens & UI](#الشاشات-والواجهات--screens--ui)
7. [قاعدة البيانات والتخزين | Database & Storage](#قاعدة-البيانات-والتخزين--database--storage)
8. [نظام الترجمة | Localization System](#نظام-الترجمة--localization-system)
9. [التكامل مع الخدمات الخارجية | External Services Integration](#التكامل-مع-الخدمات-الخارجية--external-services-integration)
10. [التركيب والتشغيل | Installation & Setup](#التركيب-والتشغيل--installation--setup)
11. [الخطوات المستقبلية | Future Enhancements](#الخطوات-المستقبلية--future-enhancements)

---

## 🎯 نظرة عامة | Overview

**SmartTour** هو تطبيق جوال ذكي مصمم ليكون دليلاً سياحياً شاملاً يساعد المستخدمين على استكشاف المدن والمواقع السياحية بطريقة تفاعلية ومبتكرة. التطبيق يوفر تجربة سياحية متكاملة تجمع بين المعلومات التفصيلية عن الأماكن، التخطيط للرحلات، التوصيات الذكية، والخرائط التفاعلية.

**SmartTour** is a smart mobile application designed to be a comprehensive tourist guide that helps users explore cities and tourist sites in an interactive and innovative way. The app provides an integrated tourist experience that combines detailed information about places, trip planning, smart recommendations, and interactive maps.

---

## 🎯 أهداف المشروع | Project Objectives

### الأهداف الرئيسية | Main Objectives:

1. **توفير دليل سياحي شامل**: تقديم معلومات تفصيلية عن المعالم السياحية، المطاعم، الفعاليات، وأماكن التسوق
2. **تخطيط الرحلات**: تمكين المستخدمين من إنشاء وإدارة خطط رحلاتهم بشكل منظم
3. **التوصيات الذكية**: تقديم توصيات مخصصة بناءً على تفضيلات المستخدم
4. **الخرائط التفاعلية**: عرض الأماكن على الخرائط مع إمكانية التنقل والبحث
5. **دعم متعدد اللغات**: دعم اللغة العربية والإنجليزية مع إمكانية التبديل بينهما
6. **تجربة مستخدم ممتازة**: واجهة مستخدم عصرية وسهلة الاستخدام

### Main Objectives:

1. **Provide Comprehensive Tourist Guide**: Offer detailed information about tourist attractions, restaurants, events, and shopping places
2. **Trip Planning**: Enable users to create and manage their trip plans in an organized manner
3. **Smart Recommendations**: Provide personalized recommendations based on user preferences
4. **Interactive Maps**: Display places on maps with navigation and search capabilities
5. **Multi-language Support**: Support Arabic and English with the ability to switch between them
6. **Excellent User Experience**: Modern and user-friendly interface

---

## ✨ الميزات الرئيسية | Key Features

### 1. نظام المصادقة | Authentication System
- تسجيل الدخول باستخدام البريد الإلكتروني وكلمة المرور
- إنشاء حساب جديد
- تسجيل الدخول باستخدام Google
- استعادة كلمة المرور
- تذكر بيانات المستخدم

### 2. شاشة البداية | Splash Screen
- شاشة ترحيبية مع شعار التطبيق
- تحميل تلقائي للبيانات الأساسية
- انتقال سلس إلى شاشة الترحيب

### 3. شاشات الترحيب | Onboarding Screens
- 4 شاشات تعليمية تشرح ميزات التطبيق
- تصميم جذاب مع أيقونات وألوان مميزة
- إمكانية التخطي أو الانتقال خطوة بخطوة

### 4. الصفحة الرئيسية | Home Screen
- شريط علوي مع إشعارات، بحث، الطقس، والموقع
- قسم "استكشف المدينة" مع فئات مختلفة (مطاعم، معالم، فعاليات، تسوق)
- قسم "الأماكن المميزة" مع بطاقات تفاعلية
- قسم "الإجراءات السريعة" (تخطيط الرحلة، الوضع دون اتصال، التحديثات المباشرة)
- شريط تنقل سفلي للوصول السريع للشاشات الرئيسية

### 5. شاشة الخرائط | Map Screen
- خريطة تفاعلية تعرض الأماكن القريبة
- بحث عن الأماكن
- فلاتر حسب الفئات (معالم، مطاعم، فعاليات، تسوق)
- عرض قائمة بالأماكن القريبة
- زر للعودة إلى الموقع الحالي
- علامات ملونة على الخريطة حسب نوع المكان
- نافذة معلومات عند الضغط على العلامات

### 6. شاشة الرحلات | Trips Screen
- عرض الرحلات المخططة، الجارية، والمكتملة
- إنشاء رحلة جديدة مع تحديد التواريخ والوصف
- تعديل وحذف الرحلات
- مشاركة الرحلات
- نصائح للتخطيط
- عرض تفاصيل كل رحلة (الأماكن، المدة، التواريخ)

### 7. شاشة التوصيات | Recommendations Screen
- توصيات ذكية مخصصة للمستخدم
- بحث متقدم عن الأماكن
- فلاتر متعددة (الفئة، السعر، المسافة، الوقت)
- ترتيب النتائج حسب التقييم، المسافة، أو السعر
- عرض بطاقات تفاعلية للأماكن الموصى بها

### 8. شاشة تفاصيل المكان | Place Details Screen
- صورة كبيرة للمكان مع إمكانية التمرير
- معلومات شاملة (التقييم، المراجعات، المسافة، العنوان)
- أزرار إجراءات (التنقل، الواقع المعزز، الدليل الصوتي)
- إضافة المكان إلى خطة الرحلة
- أقسام تفصيلية:
  - عن المكان
  - التاريخ
  - المرافق المتاحة
  - نصائح للزيارة
  - معلومات الاتصال
  - التقييمات والمراجعات

### 9. الملف الشخصي | Profile Screen
- معلومات المستخدم (الصورة، الاسم، البريد الإلكتروني)
- إحصائيات النشاط (التقييمات، المفضلة، الرحلات)
- إعدادات الحساب (تعديل الملف، الإشعارات، الخصوصية)
- إعدادات التطبيق (اللغة، الخرائط المحفوظة، الإعدادات العامة)
- قسم المساعدة والدعم
- تسجيل الخروج

### 10. القائمة الجانبية | Side Drawer
- معلومات المستخدم
- روابط سريعة للشاشات الرئيسية
- إعدادات متقدمة
- الوضع الليلي (قيد التطوير)
- معلومات الإصدار

### 11. نظام الترجمة | Localization System
- دعم اللغة العربية والإنجليزية
- تبديل اللغة من الملف الشخصي
- حفظ تفضيلات اللغة
- ترجمة شاملة لجميع عناصر الواجهة

---

## 🛠️ التقنيات المستخدمة | Technologies Used

### Framework & Language
- **Flutter**: إطار عمل متعدد المنصات لتطوير التطبيقات
- **Dart**: لغة البرمجة المستخدمة

### State Management
- **Provider**: لإدارة حالة التطبيق والترجمة

### Backend & Authentication
- **Firebase Core**: البنية الأساسية لـ Firebase
- **Firebase Authentication**: نظام المصادقة
  - تسجيل الدخول بالبريد الإلكتروني
  - تسجيل الدخول بـ Google
- **Google Sign-In**: تكامل مع Google للمصادقة

### Maps & Location
- **flutter_map**: مكتبة الخرائط التفاعلية
- **latlong2**: معالجة الإحداثيات الجغرافية
- **geolocator**: الحصول على الموقع الحالي للمستخدم

### Localization
- **flutter_localizations**: دعم الترجمة المدمج في Flutter
- **intl**: تنسيق التواريخ والأرقام حسب اللغة
- **shared_preferences**: حفظ تفضيلات اللغة

### UI/UX Libraries
- **Material Design 3**: تصميم Material الحديث
- **Custom Widgets**: مكونات مخصصة للواجهة

### Development Tools
- **Android Studio / VS Code**: بيئة التطوير
- **Gradle**: نظام بناء Android
- **Git**: إدارة الإصدارات

---

## 🏗️ البنية المعمارية | Architecture

### هيكل المشروع | Project Structure

```
smarttour/
├── android/                 # إعدادات Android
├── ios/                     # إعدادات iOS (قيد التطوير)
├── lib/
│   ├── l10n/               # ملفات الترجمة
│   │   └── app_localizations.dart
│   ├── providers/          # State Management
│   │   └── locale_provider.dart
│   ├── screens/            # الشاشات
│   │   ├── splash_screen.dart
│   │   ├── onboarding_screen.dart
│   │   ├── login_screen.dart
│   │   ├── signup_screen.dart
│   │   ├── home_screen.dart
│   │   ├── map_screen.dart
│   │   ├── trips_screen.dart
│   │   ├── recommendations_screen.dart
│   │   ├── profile_screen.dart
│   │   └── place_details_screen.dart
│   ├── services/           # الخدمات
│   │   └── auth_service.dart
│   ├── widgets/            # المكونات المخصصة
│   │   └── app_drawer.dart
│   ├── theme/              # الثيمات والألوان
│   │   └── app_colors.dart
│   └── main.dart           # نقطة البداية
└── pubspec.yaml            # التبعيات والأصول
```

### نمط التصميم | Design Pattern

التطبيق يستخدم **Model-View-Controller (MVC)** مع **Provider** لإدارة الحالة:

- **Model**: هياكل البيانات (Place, Trip, User)
- **View**: الشاشات والواجهات (Screens)
- **Controller**: الخدمات ومقدمي الحالة (Services, Providers)

---

## 📱 الشاشات والواجهات | Screens & UI

### 1. Splash Screen
- **الغرض**: شاشة البداية عند فتح التطبيق
- **الميزات**: 
  - شعار التطبيق
  - رسالة ترحيبية
  - تحميل تلقائي
  - انتقال تلقائي بعد 3 ثوانٍ

### 2. Onboarding Screens
- **الغرض**: تعريف المستخدمين الجدد بميزات التطبيق
- **عدد الشاشات**: 4
- **الميزات**:
  - PageView للتمرير بين الشاشات
  - مؤشرات الصفحات
  - أزرار التنقل (التالي، السابق، تخطي، ابدأ الآن)

### 3. Login Screen
- **الحقول**: البريد الإلكتروني، كلمة المرور
- **الميزات**:
  - تذكرني
  - نسيت كلمة المرور
  - تسجيل الدخول بـ Google
  - رابط للانتقال إلى التسجيل

### 4. Sign Up Screen
- **الحقول**: الاسم الكامل، البريد الإلكتروني، رقم الهاتف، كلمة المرور، تأكيد كلمة المرور
- **الميزات**:
  - التحقق من صحة البيانات
  - التسجيل بـ Google
  - شروط الخدمة وسياسة الخصوصية
  - رابط للانتقال إلى تسجيل الدخول

### 5. Home Screen
- **المكونات الرئيسية**:
  - Top Bar: إشعارات، بحث، طقس، موقع، قائمة
  - Explore City: بطاقات الفئات
  - Featured Places: قائمة الأماكن المميزة
  - Quick Actions: أزرار الإجراءات السريعة
  - Bottom Navigation: شريط التنقل السفلي

### 6. Map Screen
- **المكونات الرئيسية**:
  - خريطة تفاعلية
  - شريط البحث
  - فلاتر الفئات
  - قائمة الأماكن القريبة
  - زر الموقع الحالي
  - علامات ملونة على الخريطة

### 7. Trips Screen
- **الأقسام**:
  - Tab Bar: مخططة، جارية، مكتملة
  - قائمة الرحلات
  - زر إنشاء رحلة جديدة
  - نصائح التخطيط

### 8. Recommendations Screen
- **المكونات**:
  - شريط البحث
  - فلاتر الفئات
  - قسم التوصيات الذكية
  - قسم المزيد من الأماكن
  - فلاتر متقدمة (السعر، المسافة، الوقت)

### 9. Place Details Screen
- **الأقسام**:
  - صورة المكان
  - معلومات أساسية
  - أزرار الإجراءات
  - عن المكان
  - التاريخ
  - المرافق
  - نصائح الزيارة
  - معلومات الاتصال
  - التقييمات

### 10. Profile Screen
- **الأقسام**:
  - معلومات المستخدم
  - إحصائيات النشاط
  - حسابي
  - إعدادات التطبيق
  - المساعدة
  - معلومات التطبيق

---

## 💾 قاعدة البيانات والتخزين | Database & Storage

### Firebase Services

#### Authentication
- **Email/Password Authentication**: تسجيل الدخول والتسجيل
- **Google Sign-In**: تسجيل الدخول باستخدام حساب Google
- **Password Reset**: استعادة كلمة المرور

#### Future Database Integration (قيد التطوير)
- **Cloud Firestore**: لتخزين بيانات المستخدمين، الرحلات، والأماكن
- **Cloud Storage**: لتخزين الصور والملفات

### Local Storage
- **SharedPreferences**: حفظ تفضيلات اللغة وإعدادات المستخدم

---

## 🌐 نظام الترجمة | Localization System

### اللغات المدعومة
- **العربية (ar)**: اللغة الافتراضية
- **الإنجليزية (en)**: اللغة الثانوية

### الميزات
- تبديل اللغة ديناميكياً من الملف الشخصي
- حفظ تفضيلات اللغة محلياً
- دعم RTL (Right-to-Left) للعربية
- ترجمة شاملة لجميع عناصر الواجهة

### المفاتيح المترجمة
- عناصر التنقل
- رسائل المصادقة
- عناصر الواجهة
- رسائل الخطأ والنجاح
- التسميات والأزرار

---

## 🔌 التكامل مع الخدمات الخارجية | External Services Integration

### Firebase
- **Firebase Core**: التهيئة الأساسية
- **Firebase Auth**: المصادقة وإدارة المستخدمين
- **Google Sign-In**: تسجيل الدخول الاجتماعي

### Maps Services
- **flutter_map**: عرض الخرائط التفاعلية
- **OpenStreetMap**: مصدر بيانات الخرائط
- **Google Maps API**: (قيد التكامل) للخرائط المتقدمة

### Location Services
- **Geolocator**: الحصول على الموقع الحالي
- **Permissions**: إدارة أذونات الموقع

---

## 🚀 التركيب والتشغيل | Installation & Setup

### المتطلبات | Requirements

- Flutter SDK (3.0 أو أحدث)
- Dart SDK (3.0 أو أحدث)
- Android Studio / VS Code
- Android SDK (API 23 أو أحدث)
- حساب Firebase
- حساب Google Cloud (لخرائط Google - اختياري)

### خطوات التركيب | Installation Steps

1. **استنساخ المشروع**
   ```bash
   git clone <repository-url>
   cd smarttour
   ```

2. **تثبيت التبعيات**
   ```bash
   flutter pub get
   ```

3. **إعداد Firebase**
   - إنشاء مشروع Firebase جديد
   - إضافة تطبيق Android
   - تنزيل ملف `google-services.json`
   - وضعه في `android/app/`

4. **إعداد Google Sign-In**
   - تفعيل Google Sign-In في Firebase Console
   - إضافة SHA-1 fingerprint

5. **إعداد Google Maps (اختياري)**
   - الحصول على API Key من Google Cloud Console
   - إضافته في `AndroidManifest.xml`

6. **تشغيل التطبيق**
   ```bash
   flutter run
   ```

---

## 📊 المخططات والرسوم البيانية | Diagrams & Charts

### مخطط تدفق المستخدم | User Flow Diagram

```
Splash Screen
    ↓
Onboarding (First Time)
    ↓
Login/Sign Up
    ↓
Home Screen
    ├──→ Map Screen
    ├──→ Trips Screen
    ├──→ Recommendations Screen
    └──→ Profile Screen
         └──→ Place Details Screen
```

### مخطط البنية المعمارية | Architecture Diagram

```
┌─────────────────────────────────────┐
│         Presentation Layer          │
│  (Screens, Widgets, UI Components)  │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│        State Management              │
│      (Provider, LocaleProvider)      │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│         Business Logic               │
│      (Services, Auth Service)        │
└──────────────┬──────────────────────┘
               │
┌──────────────▼──────────────────────┐
│      External Services               │
│  (Firebase, Maps, Location APIs)    │
└─────────────────────────────────────┘
```

### مخطط قاعدة البيانات | Database Schema (Future)

```
Users
├── uid (Primary Key)
├── email
├── displayName
├── photoURL
└── createdAt

Trips
├── tripId (Primary Key)
├── userId (Foreign Key)
├── name
├── startDate
├── endDate
├── description
└── places[]

Places
├── placeId (Primary Key)
├── name
├── category
├── latitude
├── longitude
├── rating
├── reviews
└── details
```

---

## 🔮 الخطوات المستقبلية | Future Enhancements

### الميزات المخطط لها | Planned Features

1. **قاعدة البيانات الكاملة**
   - تكامل Firestore لتخزين البيانات
   - مزامنة البيانات بين الأجهزة

2. **المزيد من طرق المصادقة**
   - تسجيل الدخول بـ Facebook
   - تسجيل الدخول بـ Apple

3. **الميزات المتقدمة**
   - الواقع المعزز (AR) لاستكشاف الأماكن
   - الدليل الصوتي للمعالم السياحية
   - التنقل المباشر مع التوجيهات
   - وضع عدم الاتصال الكامل

4. **الميزات الاجتماعية**
   - مشاركة الرحلات مع الأصدقاء
   - التقييمات والمراجعات التفاعلية
   - إنشاء مجموعات سفر

5. **الذكاء الاصطناعي**
   - توصيات أكثر ذكاءً بناءً على سلوك المستخدم
   - تخطيط تلقائي للرحلات
   - ترجمة فورية للنصوص

6. **الميزات الإضافية**
   - الإشعارات الفورية
   - التقويم الهجري
   - معلومات الطقس التفصيلية
   - دعم المزيد من اللغات

---

## 📝 الخلاصة | Conclusion

**SmartTour** هو تطبيق شامل يهدف إلى تحسين تجربة السفر والسياحة من خلال توفير أدوات ذكية ومبتكرة. التطبيق يجمع بين المعلومات التفصيلية، التخطيط الذكي، والتوصيات المخصصة لإنشاء تجربة سياحية فريدة.

المشروع يستخدم أحدث التقنيات في تطوير التطبيقات الجوالة ويوفر واجهة مستخدم عصرية وسهلة الاستخدام. مع إمكانيات التوسع المستقبلية، يمكن أن يصبح SmartTour منصة سياحية رائدة في المنطقة.

---

## 👥 فريق العمل | Team

- **المطور الرئيسي**: [اسم المطور]
- **المشرف**: [اسم المشرف]
- **السنة الدراسية**: [السنة]
- **الجامعة**: [اسم الجامعة]
- **القسم**: [اسم القسم]

---

## 📄 الترخيص | License

هذا المشروع هو جزء من مشروع تخرج أكاديمي.

This project is part of an academic graduation project.

---

## 📧 التواصل | Contact

للمزيد من المعلومات أو الاستفسارات:
For more information or inquiries:

- **البريد الإلكتروني**: [email@example.com]
- **GitHub**: [github.com/username/smarttour]

---

**تم التحديث**: [التاريخ]
**Last Updated**: [Date]






