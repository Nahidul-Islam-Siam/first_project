import 'package:flutter/material.dart';

import 'package:first_project/features/hadith/models/hadith_item.dart';
import 'package:first_project/features/hadith/services/hadith_service.dart';
import 'package:first_project/shared/services/app_globals.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  final HadithService _hadithService = HadithService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  String _query = '';
  List<HadithItem> _hadiths = const [];

  bool get _isBangla => appLanguageNotifier.value == AppLanguage.bangla;

  String _text(String english, String bangla) => _isBangla ? bangla : english;

  @override
  void initState() {
    super.initState();
    appLanguageNotifier.addListener(_onLanguageChanged);
    _searchController.addListener(_onSearchChanged);
    _loadHadiths();
  }

  @override
  void dispose() {
    appLanguageNotifier.removeListener(_onLanguageChanged);
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onLanguageChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() => _query = _searchController.text.trim().toLowerCase());
  }

  Future<void> _loadHadiths() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final hadiths = await _hadithService.loadHadiths();
      if (!mounted) return;
      setState(() {
        _hadiths = hadiths;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<HadithItem> get _filteredHadiths {
    if (_query.isEmpty) return _hadiths;
    return _hadiths
        .where((item) {
          return item.id.toString().contains(_query) ||
              item.category.toLowerCase().contains(_query) ||
              item.titleEn.toLowerCase().contains(_query) ||
              item.titleBn.toLowerCase().contains(_query) ||
              item.arabic.contains(_query) ||
              item.english.toLowerCase().contains(_query) ||
              item.bangla.toLowerCase().contains(_query) ||
              item.reference.toLowerCase().contains(_query);
        })
        .toList(growable: false);
  }

  String _categoryLabel(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return _text('General', 'সাধারণ');

    if (_isBangla) {
      switch (normalized) {
        case 'revelation':
          return 'ওহী';
        case 'belief':
          return 'ঈমান';
        case 'knowledge':
          return 'জ্ঞান';
        case 'prayers_salat':
          return 'সালাত';
        case 'good_manners_and_form_al_adab':
          return 'আদব';
        default:
          return 'সাধারণ';
      }
    }

    return normalized
        .split('_')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  void _openHadithDetails(HadithItem item) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      builder: (sheetContext) {
        final glass = NoorifyGlassTheme(sheetContext);
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.titleBn.isNotEmpty ? item.titleBn : item.titleEn,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: glass.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.reference,
                  style: TextStyle(
                    fontSize: 12,
                    color: glass.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: glass.isDark
                        ? const Color(0x44112635)
                        : const Color(0xFFEAF3FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: glass.glassBorder),
                  ),
                  child: Text(
                    item.arabic,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: glass.textPrimary,
                      height: 1.45,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  _text('English', 'ইংরেজি'),
                  style: TextStyle(
                    fontSize: 12,
                    color: glass.textMuted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.english,
                  style: TextStyle(fontSize: 14, color: glass.textPrimary),
                ),
                if (item.bangla.trim().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    _text('Bangla', 'বাংলা'),
                    style: TextStyle(
                      fontSize: 12,
                      color: glass.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.bangla,
                    style: TextStyle(fontSize: 14, color: glass.textPrimary),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  void _onTapPlay(HadithItem item) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _text(
            'Hadith audio will be added in a future update.',
            'হাদিস অডিও ভবিষ্যৎ আপডেটে যোগ করা হবে।',
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filteredHadiths;
    final glass = NoorifyGlassTheme(context);

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
                child: NoorifyGlassCard(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  radius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _text('Sahih Bukhari (50)', 'সহিহ বুখারী (৫০)'),
                              style: Theme.of(context).textTheme.headlineSmall
                                  ?.copyWith(
                                    color: glass.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: glass.isDark
                                  ? const Color(0x332EB8E6)
                                  : const Color(0x1F1EA8B8),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(color: glass.glassBorder),
                            ),
                            child: Text(
                              '${filtered.length}/${_hadiths.length}',
                              style: TextStyle(
                                color: glass.textPrimary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _text(
                          'Lightweight offline hadith collection for initial release',
                          'প্রাথমিক রিলিজের জন্য হালকা অফলাইন হাদিস সংগ্রহ',
                        ),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: glass.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        style: TextStyle(color: glass.textPrimary),
                        decoration: InputDecoration(
                          hintText: _text(
                            'Search hadith, category, or reference',
                            'হাদিস, ক্যাটাগরি বা রেফারেন্স খুঁজুন',
                          ),
                          hintStyle: TextStyle(color: glass.textMuted),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: glass.textMuted,
                          ),
                          filled: true,
                          fillColor: glass.isDark
                              ? const Color(0x4412272E)
                              : const Color(0xECFFFFFF),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: glass.glassBorder),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: glass.glassBorder),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: glass.accent),
                      )
                    : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: glass.textSecondary),
                              ),
                              const SizedBox(height: 10),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor: glass.accent,
                                  foregroundColor: glass.isDark
                                      ? const Color(0xFF032F35)
                                      : Colors.white,
                                ),
                                onPressed: _loadHadiths,
                                child: Text(_text('Retry', 'পুনরায় চেষ্টা')),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          final hasAudio = (item.audio ?? '').trim().isNotEmpty;
                          return InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () => _openHadithDetails(item),
                            child: NoorifyGlassCard(
                              radius: BorderRadius.circular(16),
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                10,
                                12,
                                12,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 9,
                                          vertical: 5,
                                        ),
                                        decoration: BoxDecoration(
                                          color: glass.isDark
                                              ? const Color(0x332EB8E6)
                                              : const Color(0x221EA8B8),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                        ),
                                        child: Text(
                                          '#${item.id}',
                                          style: TextStyle(
                                            color: glass.accent,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _categoryLabel(item.category),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            color: glass.textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      IconButton.filledTonal(
                                        tooltip: hasAudio
                                            ? _text('Play audio', 'অডিও চালান')
                                            : _text('No audio yet', 'অডিও নেই'),
                                        onPressed: hasAudio
                                            ? () => _onTapPlay(item)
                                            : null,
                                        style: IconButton.styleFrom(
                                          backgroundColor: glass.isDark
                                              ? const Color(0x3316383E)
                                              : const Color(0x221EA8B8),
                                          foregroundColor: glass.accent,
                                        ),
                                        icon: const Icon(
                                          Icons.play_arrow_rounded,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item.titleBn.isNotEmpty
                                        ? item.titleBn
                                        : item.titleEn,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: glass.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.english,
                                    maxLines: 4,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: glass.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    item.reference,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: glass.accentSoft,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              bottomNav(context, 1),
            ],
          ),
        ),
      ),
    );
  }
}
