import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../../services/trips_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';

class ManageTripsScreen extends StatelessWidget {
  const ManageTripsScreen({super.key});

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
              loc?.translate('manage_trips') ?? 'إدارة الرحلات',
              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
          ),
          body: Center(
            child: Text(
              loc?.translate('coming_soon') ?? 'قريباً',
              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
          ),
        );
      },
    );
  }
}



