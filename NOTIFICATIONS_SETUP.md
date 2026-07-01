# إعداد الإشعارات | Notifications Setup

## ✅ ما تم إنجازه | What's Been Done

### 1. إضافة Packages
- ✅ `firebase_messaging` - للإشعارات من Firebase
- ✅ `flutter_local_notifications` - للإشعارات المحلية

### 2. الأذونات | Permissions
تم إضافة الأذونات التالية في `AndroidManifest.xml`:
- ✅ `POST_NOTIFICATIONS` - لإرسال الإشعارات
- ✅ `VIBRATE` - للاهتزاز
- ✅ `RECEIVE_BOOT_COMPLETED` - لاستقبال الإشعارات بعد إعادة التشغيل

### 3. الخدمات | Services
- ✅ `NotificationService` - خدمة شاملة لإدارة الإشعارات
  - تهيئة الإشعارات
  - حفظ FCM Token في Firebase
  - معالجة الإشعارات (Foreground, Background, Terminated)
  - حفظ الإشعارات في Firestore
  - جلب الإشعارات من Firestore
  - تحديد الإشعارات كمقروءة
  - حذف الإشعارات

### 4. صفحة الإشعارات | Notifications Screen
- ✅ صفحة كاملة لعرض الإشعارات
- ✅ عرض عدد الإشعارات غير المقروءة
- ✅ تحديد الكل كمقروء
- ✅ حذف الإشعارات (سحب للأسفل)
- ✅ تنقل تلقائي حسب نوع الإشعار
- ✅ دعم RTL للعربية
- ✅ ترجمة كاملة

### 5. الربط | Integration
- ✅ ربط زر الإشعارات في Home Screen
- ✅ ربط زر الإشعارات في Profile Screen
- ✅ ربط زر الإشعارات في App Drawer
- ✅ عرض عدد الإشعارات غير المقروءة في Home Screen
- ✅ تهيئة الإشعارات في `main.dart`

## 📊 هيكل البيانات في Firebase | Firebase Data Structure

### User Tokens
```
user_tokens/{userId}
  - token: string (FCM Token)
  - updatedAt: timestamp
```

### Notifications
```
notifications/{notificationId}
  - userId: string
  - title: string
  - body: string
  - type: string ('trip', 'weather', 'place', 'general')
  - data: string (Additional data)
  - isRead: boolean
  - timestamp: timestamp
```

## 🚀 كيفية الإرسال | How to Send Notifications

### من Firebase Console:
1. اذهب إلى Firebase Console
2. Cloud Messaging
3. Send your first message
4. أدخل العنوان والرسالة
5. اختر Target (All users أو User segment)
6. Send

### من الكود (Cloud Functions):
```javascript
const admin = require('firebase-admin');

// Get user token from Firestore
const userDoc = await admin.firestore()
  .collection('user_tokens')
  .doc(userId)
  .get();
const token = userDoc.data().token;

// Send notification
await admin.messaging().send({
  token: token,
  notification: {
    title: 'عنوان الإشعار',
    body: 'نص الإشعار',
  },
  data: {
    type: 'trip',
    data: 'tripId123',
  },
});
```

## 📱 أنواع الإشعارات | Notification Types

1. **trip** - إشعارات الرحلات
   - بدء رحلة جديدة
   - تذكير برحلة قادمة
   - تحديثات الرحلة

2. **weather** - إشعارات الطقس
   - تحذيرات الطقس
   - تغييرات الطقس

3. **place** - إشعارات الأماكن
   - أماكن جديدة
   - توصيات

4. **general** - إشعارات عامة
   - تحديثات التطبيق
   - إشعارات عامة

## 🔧 الميزات | Features

### ✅ الإشعارات في Foreground
- تظهر كإشعار محلي عند وصول إشعار أثناء فتح التطبيق

### ✅ الإشعارات في Background
- تظهر تلقائياً في شريط الإشعارات

### ✅ الإشعارات عند إغلاق التطبيق
- تظهر تلقائياً في شريط الإشعارات

### ✅ حفظ الإشعارات
- جميع الإشعارات محفوظة في Firestore
- يمكن للمستخدم مراجعتها لاحقاً

### ✅ عداد الإشعارات غير المقروءة
- يظهر عدد الإشعارات غير المقروءة في Home Screen

## 📝 ملاحظات مهمة | Important Notes

1. **FCM Token:**
   - يتم حفظه تلقائياً في Firestore عند تسجيل الدخول
   - يتم تحديثه تلقائياً عند التغيير

2. **الأذونات:**
   - التطبيق سيطلب إذن الإشعارات عند أول استخدام
   - يمكن للمستخدم رفض الإذن

3. **Firebase Console:**
   - يجب تفعيل Cloud Messaging في Firebase Console
   - يجب إضافة Server Key في Firebase Console

## 🎯 الخطوات التالية | Next Steps

1. ✅ تم إعداد النظام بالكامل
2. (اختياري) إضافة Cloud Functions لإرسال الإشعارات التلقائية
3. (اختياري) إضافة إشعارات مجدولة (Scheduled Notifications)
4. (اختياري) إضافة إشعارات محلية مجدولة

## ✅ النظام جاهز للاستخدام!

يمكنك الآن:
- إرسال إشعارات من Firebase Console
- استقبال الإشعارات في التطبيق
- عرض الإشعارات في صفحة الإشعارات
- رؤية عدد الإشعارات غير المقروءة





