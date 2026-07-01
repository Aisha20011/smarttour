import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';

extension LocalizationExtension on BuildContext {
  AppLocalizations? get l10n => AppLocalizations.of(this);
  
  String translate(String key) {
    return AppLocalizations.of(this)?.translate(key) ?? key;
  }
}







