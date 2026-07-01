import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:ui' as ui;
import '../widgets/app_drawer.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';
import '../services/help_service.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final HelpService _helpService = HelpService();
  String _searchQuery = '';
  String _activeCategory = 'all';
  final Map<String, bool> _expandedItems = {};

  List<String> _getCategories(BuildContext context) {
    final loc = AppLocalizations.of(context);
    return [
      'all',
      'general',
      'account',
      'trips',
      'places',
      'technical',
    ];
  }

  String _getCategoryName(String category, BuildContext context) {
    final loc = AppLocalizations.of(context);
    final isArabic = loc?.locale.languageCode == 'ar';
    
    switch (category) {
      case 'all':
        return loc?.translate('all') ?? 'الكل';
      case 'general':
        return loc?.translate('general') ?? 'عام';
      case 'account':
        return loc?.translate('account') ?? 'الحساب';
      case 'trips':
        return loc?.translate('trips') ?? 'الرحلات';
      case 'places':
        return loc?.translate('places') ?? 'الأماكن';
      case 'technical':
        return loc?.translate('technical') ?? 'تقني';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, child) {
        final loc = AppLocalizations.of(context);
        final isArabic = loc?.locale.languageCode == 'ar';

        return Scaffold(
          drawer: const AppDrawer(),
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: AppBar(
            title: Text(
              loc?.translate('help_support') ?? 'المساعدة والدعم',
              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Search Bar
              Container(
                padding: const EdgeInsets.all(16),
                color: Theme.of(context).cardColor,
                child: TextField(
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value;
                    });
                  },
                  textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                  decoration: InputDecoration(
                    hintText: loc?.translate('search_help') ?? 'ابحث في المساعدة...',
                    hintTextDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Theme.of(context).dividerColor),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ),

              // Category Filter
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                height: 50,
                color: Theme.of(context).cardColor,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _getCategories(context).length,
                  itemBuilder: (context, index) {
                    final category = _getCategories(context)[index];
                    final isActive = _activeCategory == category;

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(_getCategoryName(category, context)),
                        selected: isActive,
                        onSelected: (selected) {
                          setState(() {
                            _activeCategory = category;
                          });
                        },
                        selectedColor: Theme.of(context).colorScheme.primary,
                        labelStyle: TextStyle(
                          color: isActive 
                              ? Theme.of(context).colorScheme.onPrimary
                              : Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 13,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                    );
                  },
                ),
              ),

              // FAQs List
              Expanded(
                child: _searchQuery.isNotEmpty
                    ? FutureBuilder<List<FAQ>>(
                        future: _helpService.searchFAQs(_searchQuery, isArabic ? 'ar' : 'en'),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${snapshot.error}',
                                textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                              ),
                            );
                          }

                          final faqs = snapshot.data ?? [];
                          if (faqs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.search_off,
                                    size: 64,
                                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    loc?.translate('no_results') ?? 'لا توجد نتائج',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                    textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: faqs.length,
                            itemBuilder: (context, index) {
                              final faq = faqs[index];
                              return _buildFAQCard(faq, isArabic);
                            },
                          );
                        },
                      )
                    : StreamBuilder<List<FAQ>>(
                        stream: _activeCategory == 'all'
                            ? _helpService.getFAQs()
                            : _helpService.getFAQsByCategory(_activeCategory),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }

                          if (snapshot.hasError) {
                            return Center(
                              child: Text(
                                'Error: ${snapshot.error}',
                                textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                              ),
                            );
                          }

                          final faqs = snapshot.data ?? [];
                          if (faqs.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.help_outline,
                                    size: 64,
                                    color: Theme.of(context).iconTheme.color?.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    loc?.translate('no_faqs') ?? 'لا توجد أسئلة متاحة',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Theme.of(context).textTheme.bodyLarge?.color,
                                    ),
                                    textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: faqs.length,
                            itemBuilder: (context, index) {
                              final faq = faqs[index];
                              return _buildFAQCard(faq, isArabic);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFAQCard(FAQ faq, bool isArabic) {
    final question = isArabic ? faq.questionAr : faq.questionEn;
    final answer = isArabic ? faq.answerAr : faq.answerEn;
    final isExpanded = _expandedItems[faq.id] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        title: Text(
          question,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).textTheme.titleMedium?.color,
          ),
          textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
        ),
        leading: Icon(
          Icons.help_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
        trailing: Icon(
          isExpanded ? Icons.expand_less : Icons.expand_more,
          color: Theme.of(context).iconTheme.color,
        ),
        onExpansionChanged: (expanded) {
          setState(() {
            _expandedItems[faq.id] = expanded;
          });
        },
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                height: 1.5,
              ),
              textDirection: isArabic ? ui.TextDirection.rtl : ui.TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }
}




