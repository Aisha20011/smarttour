# إعداد الطقس والموقع | Weather & Location Setup

## 📋 المتطلبات | Requirements

### 1. OpenWeatherMap API Key

للحصول على API key مجاني:

1. اذهب إلى: https://openweathermap.org/api
2. سجل حساب جديد (مجاني)
3. بعد التسجيل، اذهب إلى API Keys
4. انسخ API Key الخاص بك
5. افتح ملف `lib/services/weather_service.dart`
6. استبدل `YOUR_API_KEY_HERE` بـ API Key الخاص بك:

```dart
static const String _apiKey = 'YOUR_ACTUAL_API_KEY_HERE';
```

### 2. أذونات الموقع | Location Permissions

الأذونات موجودة بالفعل في `AndroidManifest.xml`:
- `ACCESS_FINE_LOCATION`
- `ACCESS_COARSE_LOCATION`

## 🔧 الميزات | Features

### ✅ الطقس الحقيقي | Real Weather
- جلب بيانات الطقس من OpenWeatherMap API
- عرض درجة الحرارة والأيقونة
- حفظ البيانات في Firebase Firestore
- استخدام البيانات المخزنة عند فشل الاتصال

### ✅ الموقع الحقيقي | Real Location
- تحديد الموقع الحالي باستخدام GPS
- تحويل الإحداثيات إلى اسم المدينة
- حفظ الموقع في Firebase Firestore
- عرض اسم المدينة الحقيقي بدلاً من "الرياض"

### ✅ ربط Firebase | Firebase Integration
- حفظ بيانات الطقس في `weather_cache` collection
- حفظ بيانات الموقع في `user_locations` collection
- حفظ الموقع العام في `location_cache` collection

## 📊 هيكل البيانات في Firebase | Firebase Data Structure

### Weather Cache
```
weather_cache/{cityName}
  - temperature: number
  - description: string
  - icon: string
  - city: string
  - humidity: number (optional)
  - windSpeed: number (optional)
  - timestamp: timestamp
```

### User Locations
```
user_locations/{userId}
  - latitude: number
  - longitude: number
  - city: string
  - country: string (optional)
  - address: string (optional)
  - timestamp: timestamp
```

### Location Cache
```
location_cache/current
  - latitude: number
  - longitude: number
  - city: string
  - country: string (optional)
  - address: string (optional)
  - timestamp: timestamp
```

## 🚀 الاستخدام | Usage

بعد إضافة API Key، سيعمل التطبيق تلقائياً:

1. **عند فتح Home Screen:**
   - يتم طلب إذن الموقع (إذا لم يكن موجوداً)
   - يتم جلب الموقع الحالي
   - يتم جلب بيانات الطقس بناءً على الموقع
   - يتم حفظ البيانات في Firebase

2. **عند فشل الاتصال:**
   - يتم استخدام البيانات المخزنة في Firebase
   - يتم عرض آخر موقع معروف

## ⚠️ ملاحظات مهمة | Important Notes

1. **API Key مجاني:**
   - 60 طلب في الدقيقة
   - 1,000,000 طلب في الشهر
   - كافي للاستخدام الشخصي

2. **الأذونات:**
   - التطبيق سيطلب إذن الموقع عند أول استخدام
   - يمكن للمستخدم رفض الإذن، وسيتم استخدام "الرياض" كافتراضي

3. **الأمان:**
   - لا تشارك API Key في الكود العام
   - يمكن استخدام Environment Variables في الإنتاج

## 🔄 التحديث التلقائي | Auto Refresh

يمكن إضافة تحديث تلقائي للطقس:
- كل 10 دقائق
- عند فتح التطبيق
- عند سحب للأسفل (Pull to Refresh)

## 📝 الخطوات التالية | Next Steps

1. ✅ إضافة API Key من OpenWeatherMap
2. ✅ اختبار الموقع والطقس
3. ✅ التحقق من حفظ البيانات في Firebase
4. (اختياري) إضافة تحديث تلقائي
5. (اختياري) إضافة Pull to Refresh





