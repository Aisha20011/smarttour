import 'package:flutter/material.dart';
import 'dart:ui' as ui;
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notification_service.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _notificationService = NotificationService();
  int _selectedIndex = 4; // Profile is selected

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
              loc?.translate('notifications') ?? 'الإشعارات',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            backgroundColor: Colors.white,
            foregroundColor: Colors.black87,
            elevation: 0.5,
            centerTitle: true,
            actions: [
              StreamBuilder<int>(
                stream: _notificationService.getUnreadCount(),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  if (unreadCount > 0) {
                    return TextButton(
                      onPressed: () async {
                        await _notificationService.markAllAsRead();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                loc?.translate('all_marked_read') ?? 'تم تحديد جميع الإشعارات كمقروءة',
                                textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                              ),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                      child: Text(
                        loc?.translate('mark_all_read') ?? 'تحديد الكل كمقروء',
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 14,
                        ),
                        textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
          body: StreamBuilder<List<NotificationData>>(
            stream: _notificationService.getUserNotifications(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        loc?.translate('error_loading_notifications') ?? 'حدث خطأ في تحميل الإشعارات',
                        style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
                        textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                    ],
                  ),
                );
              }

              final notifications = snapshot.data ?? [];

              if (notifications.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_none, size: 64, color: Theme.of(context).iconTheme.color?.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        loc?.translate('no_notifications') ?? 'لا توجد إشعارات',
                        style: TextStyle(
                          fontSize: 18,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w500,
                        ),
                        textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        loc?.translate('no_notifications_desc') ?? 'ستظهر الإشعارات هنا عند وصولها',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                        textAlign: TextAlign.center,
                        textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: notifications.length,
                itemBuilder: (context, index) {
                  final notification = notifications[index];
                  return _buildNotificationItem(notification, loc, isArabic);
                },
              );
            },
          ),
          bottomNavigationBar: _buildBottomNavigationBar(context),
        );
      },
    );
  }

  Widget _buildNotificationItem(
    NotificationData notification,
    AppLocalizations? loc,
    bool isArabic,
  ) {
    final dateFormat = DateFormat('MMM dd, yyyy • HH:mm', isArabic ? 'ar' : 'en');
    final timeAgo = _getTimeAgo(notification.timestamp, loc, isArabic);

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (direction) {
        _notificationService.deleteNotification(notification.id);
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        elevation: notification.isRead ? 0 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () async {
            if (!notification.isRead) {
              await _notificationService.markAsRead(notification.id);
            }
            // Navigate based on notification type
            _handleNotificationTap(notification);
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: notification.isRead 
                  ? Theme.of(context).cardColor 
                  : Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: notification.isRead 
                    ? Theme.of(context).dividerColor 
                    : Theme.of(context).colorScheme.primary.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _getNotificationColor(notification.type).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getNotificationIcon(notification.type),
                    color: _getNotificationColor(notification.type),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                                color: Theme.of(context).textTheme.titleMedium?.color,
                              ),
                              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.blue,
                                shape: BoxShape.circle,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeAgo,
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime, AppLocalizations? loc, bool isArabic) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 7) {
      final dateFormat = DateFormat('MMM dd, yyyy', isArabic ? 'ar' : 'en');
      return dateFormat.format(dateTime);
    } else if (difference.inDays > 0) {
      return isArabic
          ? 'منذ ${difference.inDays} ${difference.inDays == 1 ? 'يوم' : 'أيام'}'
          : '${difference.inDays} ${difference.inDays == 1 ? 'day' : 'days'} ago';
    } else if (difference.inHours > 0) {
      return isArabic
          ? 'منذ ${difference.inHours} ${difference.inHours == 1 ? 'ساعة' : 'ساعات'}'
          : '${difference.inHours} ${difference.inHours == 1 ? 'hour' : 'hours'} ago';
    } else if (difference.inMinutes > 0) {
      return isArabic
          ? 'منذ ${difference.inMinutes} ${difference.inMinutes == 1 ? 'دقيقة' : 'دقائق'}'
          : '${difference.inMinutes} ${difference.inMinutes == 1 ? 'minute' : 'minutes'} ago';
    } else {
      return loc?.translate('just_now') ?? 'الآن';
    }
  }

  IconData _getNotificationIcon(String? type) {
    switch (type) {
      case 'trip':
        return Icons.calendar_today;
      case 'weather':
        return Icons.wb_sunny;
      case 'place':
        return Icons.location_on;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(String? type) {
    switch (type) {
      case 'trip':
        return Colors.blue;
      case 'weather':
        return Colors.orange;
      case 'place':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _handleNotificationTap(NotificationData notification) {
    // Navigate based on notification type
    switch (notification.type) {
      case 'trip':
        if (notification.data != null && notification.data!.isNotEmpty) {
          Navigator.of(context).pushReplacementNamed('/trips');
        }
        break;
      case 'place':
        if (notification.data != null && notification.data!.isNotEmpty) {
          // Navigate to place details
          // Navigator.push(...)
        }
        break;
      default:
        break;
    }
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.2),
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
              Navigator.of(context).pushReplacementNamed('/profile');
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
}

