import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../../services/help_service.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';

class ManageFAQsScreen extends StatelessWidget {
  const ManageFAQsScreen({super.key});

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
              loc?.translate('manage_faqs') ?? 'إدارة الأسئلة الشائعة',
              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () {
                  // TODO: Implement add FAQ
                },
              ),
            ],
          ),
          body: StreamBuilder<List<FAQ>>(
            stream: HelpService().getFAQs(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text('Error: ${snapshot.error}'),
                );
              }

              final faqs = snapshot.data ?? [];
              if (faqs.isEmpty) {
                return Center(
                  child: Text(
                    loc?.translate('no_faqs') ?? 'لا توجد أسئلة',
                    textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: faqs.length,
                itemBuilder: (context, index) {
                  final faq = faqs[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    color: Theme.of(context).cardColor,
                    child: ListTile(
                      title: Text(
                        isArabic ? faq.questionAr : faq.questionEn,
                        textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () {
                              // TODO: Implement edit FAQ
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              // TODO: Implement delete FAQ
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }
}



