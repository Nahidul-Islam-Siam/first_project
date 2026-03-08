import 'dart:async';

import 'package:flutter/material.dart';

import 'package:first_project/core/theme/brand_colors.dart';
import 'package:first_project/features/quran/models/quran_models.dart';
import 'package:first_project/features/quran/screens/quran_bookmarks_screen.dart';
import 'package:first_project/features/quran/screens/surah_detail_screen.dart';
import 'package:first_project/features/quran/services/quran_api_service.dart';
import 'package:first_project/features/quran/services/quran_bookmarks_service.dart';
import 'package:first_project/features/quran/services/quran_content_cache_service.dart';
import 'package:first_project/features/quran/services/quran_last_read_service.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class QuranScreen extends StatefulWidget {
  const QuranScreen({super.key});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  final QuranApiService _api = QuranApiService();
  final QuranContentCacheService _contentCache = QuranContentCacheService();
  final QuranBookmarksService _bookmarksService = QuranBookmarksService();
  final QuranLastReadService _lastReadService = QuranLastReadService();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ScrollController _surahListController = ScrollController();

  final Set<int> _downloadedSurahNos = {};

  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _filter = 'all';
  bool _showOnlyDownloaded = false;
  int? _lastReadSurahNo;
  int? _lastReadAyahNo;
  List<QuranAyahBookmark> _bookmarks = const [];
  bool _isTopCollapsed = false;
  bool _isBulkCachingText = false;
  int _bulkCacheCompleted = 0;
  int _bulkCacheTotal = 0;

  List<QuranChapter> _chapters = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _surahListController.addListener(_onSurahListScroll);
    _loadBookmarks();
    _restoreLastRead();
    _loadChapters();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _surahListController
      ..removeListener(_onSurahListScroll)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
  }

  void _onSurahListScroll() {
    if (!mounted || _searchFocusNode.hasFocus) return;
    final shouldCollapse =
        _surahListController.hasClients && _surahListController.offset > 28;
    if (shouldCollapse == _isTopCollapsed) return;
    setState(() => _isTopCollapsed = shouldCollapse);
  }

  Future<void> _restoreLastRead() async {
    final saved = await _lastReadService.readLastRead();
    if (!mounted || saved == null) return;
    setState(() {
      _lastReadSurahNo = saved.surahNo;
      _lastReadAyahNo = saved.ayahNo;
    });
  }

  Future<void> _loadBookmarks() async {
    final items = await _bookmarksService.readAll();
    if (!mounted) return;
    setState(() => _bookmarks = items);
  }

  QuranChapter _resolveChapterForBookmark(QuranAyahBookmark bookmark) {
    for (final chapter in _chapters) {
      if (chapter.surahNo == bookmark.surahNo) {
        return chapter;
      }
    }
    final fallbackName = bookmark.surahName.trim();
    final surahName = fallbackName.isEmpty
        ? 'Surah ${bookmark.surahNo}'
        : fallbackName;
    return QuranChapter(
      surahNo: bookmark.surahNo,
      surahName: surahName,
      surahNameArabic: '...',
      surahNameArabicLong: '...',
      surahNameTranslation: '',
      revelationPlace: '',
      totalAyah: 0,
    );
  }

  QuranAyahBookmark? _firstBookmarkForSurah(int surahNo) {
    for (final bookmark in _bookmarks) {
      if (bookmark.surahNo == surahNo) return bookmark;
    }
    return null;
  }

  ({int ayahNo, double progress}) _lastReadProgressForSurah(
    QuranChapter chapter,
  ) {
    if (chapter.totalAyah <= 0) {
      return (ayahNo: 0, progress: 0);
    }

    var bestAyah = 0;
    if (_lastReadSurahNo == chapter.surahNo && (_lastReadAyahNo ?? 0) > 0) {
      bestAyah = _lastReadAyahNo!;
    }

    if (bestAyah <= 0) {
      for (final bookmark in _bookmarks) {
        if (bookmark.surahNo == chapter.surahNo && bookmark.ayahNo > bestAyah) {
          bestAyah = bookmark.ayahNo;
        }
      }
    }

    final safeAyah = bestAyah.clamp(0, chapter.totalAyah);
    return (ayahNo: safeAyah, progress: safeAyah / chapter.totalAyah);
  }

  Future<void> _loadChapters() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final chapters = await _api.fetchChapters();
      final fromCache = _api.lastReadFromCache;
      if (!mounted) return;
      setState(() {
        _chapters = chapters;
        _isLoading = false;
      });
      final downloaded = await _refreshDownloadedFlags();
      if (!mounted) return;
      if (!fromCache) {
        unawaited(_autoCacheAllTextIfNeeded(chapters, downloaded));
      }
      if (fromCache) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No internet. Showing saved content.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load Quran list.';
        _isLoading = false;
      });
    }
  }

  Future<Set<int>> _refreshDownloadedFlags() async {
    final chapters = List<QuranChapter>.from(_chapters);
    final downloaded = <int>{};

    for (final chapter in chapters) {
      final detail = await _contentCache.readSurahDetail(
        chapter.surahNo,
        lang: 'bn',
      );
      if (detail != null) {
        downloaded.add(chapter.surahNo);
      }
    }

    if (!mounted) return downloaded;
    setState(() {
      _downloadedSurahNos
        ..clear()
        ..addAll(downloaded);
    });
    return downloaded;
  }

  Future<void> _autoCacheAllTextIfNeeded(
    List<QuranChapter> chapters,
    Set<int> downloaded,
  ) async {
    if (_isBulkCachingText) return;

    final missing = chapters
        .where((chapter) => !downloaded.contains(chapter.surahNo))
        .toList(growable: false);
    if (missing.isEmpty) return;

    if (!mounted) return;
    setState(() {
      _isBulkCachingText = true;
      _bulkCacheTotal = chapters.length;
      _bulkCacheCompleted = downloaded.length;
    });

    var failed = 0;
    for (final chapter in missing) {
      try {
        await _api.fetchSurahDetail(chapter.surahNo, lang: 'bn');
        downloaded.add(chapter.surahNo);
      } catch (_) {
        failed += 1;
      }

      if (!mounted) return;
      setState(() {
        _bulkCacheCompleted = downloaded.length;
        _downloadedSurahNos
          ..clear()
          ..addAll(downloaded);
      });
    }

    if (!mounted) return;
    setState(() => _isBulkCachingText = false);

    final successCount = downloaded.length;
    if (failed == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Quran text cached for offline reading ($successCount/${chapters.length}).',
          ),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Offline text cached $successCount/${chapters.length}. Retry later for remaining $failed.',
        ),
      ),
    );
  }

  bool get _showBulkCacheProgress =>
      _isBulkCachingText ||
      (_bulkCacheTotal > 0 && _bulkCacheCompleted < _bulkCacheTotal);

  double get _bulkCacheProgressValue {
    if (_bulkCacheTotal <= 0) return 0;
    final value = _bulkCacheCompleted / _bulkCacheTotal;
    return value.clamp(0.0, 1.0).toDouble();
  }

  List<QuranChapter> get _filteredChapters {
    return _chapters
        .where((chapter) {
          if (_showOnlyDownloaded &&
              !_downloadedSurahNos.contains(chapter.surahNo)) {
            return false;
          }

          if (_filter == 'meccan' && !chapter.isMeccan) return false;
          if (_filter == 'medinan' && !chapter.isMedinan) return false;

          if (_searchQuery.isEmpty) return true;
          return chapter.surahNo.toString() == _searchQuery ||
              chapter.surahName.toLowerCase().contains(_searchQuery) ||
              chapter.surahNameArabic.contains(_searchQuery) ||
              chapter.surahNameTranslation.toLowerCase().contains(_searchQuery);
        })
        .toList(growable: false);
  }

  String _revelationLabel(String place) {
    final lower = place.toLowerCase();
    if (lower.contains('mecca')) return 'Makkah';
    if (lower.contains('medina')) return 'Madinah';
    return place;
  }

  Future<void> _showSurahDetail(
    QuranChapter chapter, {
    bool autoStartAudio = false,
    int? initialAyahNo,
  }) async {
    if (_lastReadSurahNo != chapter.surahNo) {
      setState(() {
        _lastReadSurahNo = chapter.surahNo;
        _lastReadAyahNo = 1;
      });
      unawaited(
        _lastReadService.saveLastRead(surahNo: chapter.surahNo, ayahNo: 1),
      );
    }

    final downloaded = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => SurahDetailScreen(
          chapter: chapter,
          autoStartAudio: autoStartAudio,
          initialAyahNo: initialAyahNo,
        ),
      ),
    );
    await _restoreLastRead();
    await _loadBookmarks();
    if (!mounted) return;
    if (downloaded == true) {
      setState(() => _downloadedSurahNos.add(chapter.surahNo));
    }
  }

  Future<void> _openBookmarksScreen() async {
    await _loadBookmarks();
    if (!mounted) return;
    if (_bookmarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved ayah bookmarks yet')),
      );
      return;
    }

    final selected = await Navigator.of(context).push<QuranAyahBookmark>(
      MaterialPageRoute<QuranAyahBookmark>(
        builder: (_) => QuranBookmarksScreen(bookmarks: _bookmarks),
      ),
    );

    if (selected == null || !mounted) return;
    final chapter = _resolveChapterForBookmark(selected);
    await _showSurahDetail(chapter, initialAyahNo: selected.ayahNo);
  }

  Widget _buildHeader() {
    final fallbackChapter = _chapters.isNotEmpty
        ? _chapters.first
        : QuranChapter(
            surahNo: 2,
            surahName: 'Al-Baqara',
            surahNameArabic: '\u0627\u0644\u0628\u0642\u0631\u0629',
            surahNameArabicLong:
                '\u0633\u0648\u0631\u0629 \u0627\u0644\u0628\u0642\u0631\u0629',
            surahNameTranslation: 'The Cow',
            revelationPlace: 'Medina',
            totalAyah: 286,
          );
    final lastReadChapter = _chapters.firstWhere(
      (chapter) =>
          chapter.surahNo == (_lastReadSurahNo ?? fallbackChapter.surahNo),
      orElse: () => fallbackChapter,
    );
    final lastReadProgress = _lastReadProgressForSurah(lastReadChapter);
    final completionPercent = (lastReadProgress.progress * 100).round();
    final progressLabel = lastReadProgress.ayahNo <= 0
        ? 'Start reading to track progress'
        : '$completionPercent% Complete \u2022 Ayat ${lastReadProgress.ayahNo}/${lastReadChapter.totalAyah}';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF091A2A), Color(0xFF0E2B3D), Color(0xFF144B64)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(46),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(46),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -36,
              top: -36,
              child: Container(
                width: 144,
                height: 144,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x1FFFFFFF),
                ),
              ),
            ),
            Positioned(
              left: -52,
              bottom: -72,
              child: Container(
                width: 190,
                height: 190,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x18FFFFFF),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                children: [
                  const Text(
                    '\u0627\u0644\u0642\u0631\u0622\u0646 \u0627\u0644\u0643\u0631\u064a\u0645',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Quran',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 44,
                      fontWeight: FontWeight.w300,
                      height: 0.92,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Read | Listen | Offline',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Color(0xD7FFFFFF),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 11, 12, 10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0x2AFFFFFF), Color(0x12000000)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.26),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.14),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.24),
                                ),
                              ),
                              child: const Icon(
                                Icons.menu_book_rounded,
                                size: 18,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Last Read:',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.86,
                                      ),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    lastReadChapter.surahName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      height: 1.05,
                                    ),
                                  ),
                                  Text(
                                    '(Surah ${lastReadChapter.surahNo})',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: 0.84,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FilledButton(
                              onPressed: () =>
                                  _showSurahDetail(lastReadChapter),
                              style: FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF43E6B0),
                                foregroundColor: const Color(0xFF04353A),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                minimumSize: const Size(0, 40),
                                shape: const StadiumBorder(),
                              ),
                              child: const Text(
                                'Continue',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 5,
                            value: lastReadProgress.progress,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.24,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF43E6B0),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            progressLabel,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchAndFilters() {
    final glass = NoorifyGlassTheme(context);
    final searchFill = glass.isDark
        ? const Color(0xC4142331)
        : const Color(0xFFF9FCFF);
    final searchBorder = glass.isDark
        ? const Color(0x66A9C7DB)
        : const Color(0xFFBDD5E4);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: glass.isDark
                  ? null
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xEFFFFFFF), Color(0xD7F3FAFF)],
                    ),
              color: glass.isDark ? const Color(0x3816232F) : null,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: glass.isDark
                    ? const Color(0x6AA9C7DB)
                    : const Color(0x88D1E1EC),
              ),
              boxShadow: glass.isDark
                  ? null
                  : const [
                      BoxShadow(
                        color: Color(0x120E3853),
                        blurRadius: 12,
                        offset: Offset(0, 5),
                      ),
                    ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _FilterChipButton(
                    label: '\u09b8\u09ac',
                    selected: _filter == 'all',
                    isSegment: true,
                    onTap: () => setState(() => _filter = 'all'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _FilterChipButton(
                    label: '\u09ae\u0995\u09cd\u0995\u09c0',
                    selected: _filter == 'meccan',
                    isSegment: true,
                    onTap: () => setState(() => _filter = 'meccan'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _FilterChipButton(
                    label: '\u09ae\u09be\u09a6\u09be\u09a8\u09c0',
                    selected: _filter == 'medinan',
                    isSegment: true,
                    onTap: () => setState(() => _filter = 'medinan'),
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _FilterChipButton(
                    label:
                        '\u09a1\u09be\u0989\u09a8\u09b2\u09cb\u09a1\u09c7\u09a1',
                    selected: _showOnlyDownloaded,
                    isSegment: true,
                    onTap: () => setState(
                      () => _showOnlyDownloaded = !_showOnlyDownloaded,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: TextStyle(
              color: glass.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Search',
              hintStyle: TextStyle(color: glass.textSecondary),
              prefixIcon: Icon(
                Icons.search_rounded,
                color: glass.textSecondary,
              ),
              filled: true,
              fillColor: searchFill,
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: searchBorder, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: searchBorder, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: glass.accent, width: 1.7),
              ),
            ),
          ),
          if (_showBulkCacheProgress) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: BrandColors.tintBackground,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: BrandColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Preparing offline reading: $_bulkCacheCompleted/$_bulkCacheTotal',
                    style: const TextStyle(
                      fontSize: 12,
                      color: BrandColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      minHeight: 6,
                      value: _bulkCacheProgressValue,
                      backgroundColor: Colors.white,
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        BrandColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCollapsedTopBar() {
    final glass = NoorifyGlassTheme(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
      child: NoorifyGlassCard(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        radius: BorderRadius.circular(14),
        child: Row(
          children: [
            Text(
              'Quran',
              style: TextStyle(
                color: glass.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            IconButton(
              onPressed: () {
                setState(() => _isTopCollapsed = false);
                Future<void>.delayed(const Duration(milliseconds: 220), () {
                  if (!mounted) return;
                  _searchFocusNode.requestFocus();
                });
              },
              icon: Icon(Icons.search_rounded, color: glass.accent),
              tooltip: 'Search Surah',
            ),
            IconButton(
              onPressed: _openBookmarksScreen,
              icon: Icon(
                _bookmarks.isEmpty
                    ? Icons.bookmark_border_rounded
                    : Icons.bookmark_rounded,
                color: glass.accent,
              ),
              tooltip: 'Bookmarks',
            ),
            IconButton(
              onPressed: () {
                if (_surahListController.hasClients) {
                  _surahListController.animateTo(
                    0,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                  );
                }
                setState(() => _isTopCollapsed = false);
              },
              icon: Icon(Icons.expand_more_rounded, color: glass.accent),
              tooltip: 'Expand',
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              AnimatedCrossFade(
                firstChild: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [_buildHeader(), _buildSearchAndFilters()],
                ),
                secondChild: _buildCollapsedTopBar(),
                crossFadeState: _isTopCollapsed
                    ? CrossFadeState.showSecond
                    : CrossFadeState.showFirst,
                duration: const Duration(milliseconds: 240),
                sizeCurve: Curves.easeInOutCubic,
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: glass.accent),
                      )
                    : _error != null
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _error!,
                              style: TextStyle(color: glass.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            FilledButton(
                              onPressed: _loadChapters,
                              style: FilledButton.styleFrom(
                                backgroundColor: glass.accent,
                                foregroundColor: glass.isDark
                                    ? const Color(0xFF032F35)
                                    : Colors.white,
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: _surahListController,
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        itemCount: _filteredChapters.length,
                        itemBuilder: (context, index) {
                          final chapter = _filteredChapters[index];
                          final firstBookmark = _firstBookmarkForSurah(
                            chapter.surahNo,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _QuranSurahTile(
                              chapter: chapter,
                              hasBookmark: firstBookmark != null,
                              revelationLabel: _revelationLabel(
                                chapter.revelationPlace,
                              ),
                              onTap: () => _showSurahDetail(chapter),
                              onBookmarkTap: _openBookmarksScreen,
                            ),
                          );
                        },
                      ),
              ),
              bottomNav(context, 2),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChipButton extends StatelessWidget {
  const _FilterChipButton({
    required this.label,
    required this.selected,
    required this.onTap,
    this.isSegment = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isSegment;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final bgColor = selected
        ? glass.accent
        : (glass.isDark ? const Color(0x66162538) : const Color(0xFFFDFEFF));
    final borderColor = selected
        ? glass.accentSoft
        : (glass.isDark ? const Color(0x55B4D8EE) : const Color(0xFFC6DAE8));
    final textColor = selected
        ? (glass.isDark ? const Color(0xFF032F35) : Colors.white)
        : glass.textPrimary;

    return InkWell(
      borderRadius: BorderRadius.circular(isSegment ? 10 : 100),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: isSegment
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 9)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(isSegment ? 10 : 100),
          border: Border.all(color: borderColor),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: glass.accent.withValues(
                      alpha: glass.isDark ? 0.28 : 0.22,
                    ),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ]
              : (glass.isDark
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x0B0E3853),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ]),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: TextStyle(
            color: textColor,
            fontSize: isSegment ? 13 : null,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _QuranSurahTile extends StatelessWidget {
  const _QuranSurahTile({
    required this.chapter,
    required this.hasBookmark,
    required this.revelationLabel,
    required this.onTap,
    required this.onBookmarkTap,
  });

  final QuranChapter chapter;
  final bool hasBookmark;
  final String revelationLabel;
  final VoidCallback onTap;
  final VoidCallback onBookmarkTap;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final translation = chapter.surahNameTranslation.trim().isEmpty
        ? 'Translation unavailable'
        : chapter.surahNameTranslation.trim();
    final tileBackground = glass.isDark
        ? null
        : const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFDFEFF), Color(0xFFF4FAFF)],
          );

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: NoorifyGlassCard(
          radius: BorderRadius.circular(18),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          boxShadow: [
            BoxShadow(
              color: glass.isDark
                  ? const Color(0x32000000)
                  : const Color(0x140E3853),
              blurRadius: 14,
              offset: const Offset(0, 7),
            ),
          ],
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: tileBackground,
              border: glass.isDark
                  ? null
                  : Border.all(color: const Color(0xB8DCEAF3)),
            ),
            child: Stack(
              children: [
                if (!glass.isDark)
                  Positioned(
                    top: -22,
                    left: -18,
                    child: IgnorePointer(
                      child: Container(
                        width: 140,
                        height: 64,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: const LinearGradient(
                            colors: [Color(0x4DFFFFFF), Color(0x00FFFFFF)],
                          ),
                        ),
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: glass.isDark
                            ? const Color(0xFF122A35)
                            : const Color(0xFFE9F8FC),
                        shape: BoxShape.circle,
                        border: Border.all(color: glass.accentSoft, width: 1.4),
                        boxShadow: [
                          BoxShadow(
                            color: glass.accent.withValues(alpha: 0.26),
                            blurRadius: 14,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Text(
                        chapter.surahNo.toString(),
                        style: TextStyle(
                          color: glass.accentSoft,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            chapter.surahName,
                            style: TextStyle(
                              color: glass.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            chapter.surahName,
                            style: TextStyle(
                              color: glass.isDark
                                  ? const Color(0xFFE4F1FA)
                                  : const Color(0xFF21465F),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            '$revelationLabel \u2022 ${chapter.totalAyah} ayat \u2022 $translation',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: glass.isDark
                                  ? const Color(0xFFC6DBEB)
                                  : const Color(0xFF3F627B),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 110),
                      child: Text(
                        chapter.surahNameArabic,
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: glass.isDark
                              ? const Color(0xFFDDEBA8)
                              : const Color(0xFF2F5A60),
                          fontSize: 40,
                          fontWeight: FontWeight.w500,
                          height: 0.9,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton.filledTonal(
                      onPressed: onBookmarkTap,
                      style: IconButton.styleFrom(
                        backgroundColor: hasBookmark
                            ? (glass.isDark
                                  ? const Color(0x332EB8E6)
                                  : const Color(0x1F1EA8B8))
                            : (glass.isDark
                                  ? const Color(0x3316383E)
                                  : const Color(0x121EA8B8)),
                        foregroundColor: hasBookmark
                            ? glass.accent
                            : glass.textSecondary,
                      ),
                      icon: Icon(
                        hasBookmark
                            ? Icons.bookmark_rounded
                            : Icons.bookmark_border_rounded,
                      ),
                      tooltip: 'Open bookmarks',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
