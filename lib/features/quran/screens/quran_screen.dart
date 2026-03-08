import 'dart:async';

import 'package:flutter/material.dart';

import 'package:first_project/core/theme/brand_colors.dart';
import 'package:first_project/features/quran/models/quran_models.dart';
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

  final Set<int> _downloadedSurahNos = {};
  final Set<int> _downloadingSurahNos = {};

  bool _isLoading = true;
  String? _error;
  String _searchQuery = '';
  String _filter = 'all';
  bool _showOnlyDownloaded = false;
  bool _usingCachedContent = false;
  int? _lastReadSurahNo;
  List<QuranAyahBookmark> _bookmarks = const [];
  bool _isBulkCachingText = false;
  int _bulkCacheCompleted = 0;
  int _bulkCacheTotal = 0;
  int _bulkCacheFailed = 0;

  List<QuranChapter> _chapters = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadBookmarks();
    _restoreLastRead();
    _loadChapters();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
  }

  Future<void> _restoreLastRead() async {
    final saved = await _lastReadService.readLastReadSurahNo();
    if (!mounted || saved == null) return;
    setState(() => _lastReadSurahNo = saved);
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
        _usingCachedContent = fromCache;
        _isLoading = false;
      });
      final downloaded = await _refreshDownloadedFlags();
      if (!mounted) return;
      if (!fromCache) {
        unawaited(_autoCacheAllTextIfNeeded(chapters, downloaded));
      }
      if (fromCache) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ইন্টারনেট নেই। সেভ করা কনটেন্ট দেখানো হচ্ছে।'),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'কুরআনের তালিকা লোড করা যায়নি।';
        _usingCachedContent = false;
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
      _bulkCacheFailed = 0;
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
        _bulkCacheFailed = failed;
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
      setState(() => _lastReadSurahNo = chapter.surahNo);
      unawaited(_lastReadService.saveLastReadSurahNo(chapter.surahNo));
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
    await _loadBookmarks();
    if (!mounted || downloaded != true) return;
    setState(() => _downloadedSurahNos.add(chapter.surahNo));
  }

  Future<void> _downloadSurahForOffline(QuranChapter chapter) async {
    if (_downloadingSurahNos.contains(chapter.surahNo)) return;
    setState(() => _downloadingSurahNos.add(chapter.surahNo));

    try {
      await _api.fetchSurahDetail(chapter.surahNo, lang: 'bn');

      if (!mounted) return;
      setState(() {
        _downloadingSurahNos.remove(chapter.surahNo);
        _downloadedSurahNos.add(chapter.surahNo);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Surah text saved for offline reading')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _downloadingSurahNos.remove(chapter.surahNo));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to save Surah for offline reading'),
        ),
      );
    }
  }

  void _showVideoInfo() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('ভিডিও তথ্য'),
          content: const Text(
            'QuranAPI docs এ সরাসরি ভিডিও endpoint নেই।\n'
            'অডিও endpoint আছে এবং সেটি অফলাইনে ডাউনলোড করা যাবে।',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('ঠিক আছে'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openBookmarksSheet() async {
    await _loadBookmarks();
    if (!mounted) return;
    if (_bookmarks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No saved ayah bookmarks yet')),
      );
      return;
    }

    final selected = await showModalBottomSheet<QuranAyahBookmark>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) {
        return ListView.separated(
          itemCount: _bookmarks.length + 1,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            if (index == 0) {
              return ListTile(
                title: Text(
                  'Saved Bookmarks (${_bookmarks.length})',
                  style: const TextStyle(
                    color: BrandColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }

            final item = _bookmarks[index - 1];
            final note = item.note.trim();
            final subtitle = note.isEmpty
                ? 'Surah ${item.surahNo}, Ayah ${item.ayahNo}'
                : note;

            return ListTile(
              leading: const Icon(Icons.bookmark_rounded),
              title: Text('${item.surahName} • ${item.ayahNo}'),
              subtitle: Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              onTap: () => Navigator.of(sheetContext).pop(item),
            );
          },
        );
      },
    );

    if (selected == null || !mounted) return;
    final chapter = _resolveChapterForBookmark(selected);
    await _showSurahDetail(chapter, initialAyahNo: selected.ayahNo);
  }

  Widget _buildHeader() {
    final quickLinks = _quickLinkIds
        .map(
          (id) => _chapters.firstWhere(
            (chapter) => chapter.surahNo == id,
            orElse: () => QuranChapter(
              surahNo: id,
              surahName: 'Surah $id',
              surahNameArabic: '...',
              surahNameArabicLong: '...',
              surahNameTranslation: '',
              revelationPlace: '',
              totalAyah: 0,
            ),
          ),
        )
        .toList(growable: false);

    final lastReadChapter = _chapters.firstWhere(
      (chapter) => chapter.surahNo == (_lastReadSurahNo ?? 2),
      orElse: () => quickLinks.first,
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BrandColors.primaryDark,
            BrandColors.primary,
            BrandColors.primaryLight,
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(54),
        ),
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(54),
        ),
        child: Stack(
          children: [
            Positioned(
              right: -28,
              top: -34,
              child: Container(
                width: 132,
                height: 132,
                decoration: const BoxDecoration(
                  color: Color(0x26FFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -42,
              bottom: -64,
              child: Container(
                width: 178,
                height: 178,
                decoration: const BoxDecoration(
                  color: Color(0x17FFFFFF),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'কুরআন',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 30,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Read • Listen • Offline',
                              style: TextStyle(
                                color: Color(0xDDFFFFFF),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _usingCachedContent
                                  ? Icons.cloud_off_rounded
                                  : Icons.cloud_done_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              _usingCachedContent ? 'Offline' : 'Live',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: _showVideoInfo,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.info_outline_rounded,
                            color: Colors.white,
                            size: 19,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.bookmark_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Last Read',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${lastReadChapter.surahName} • Surah ${lastReadChapter.surahNo}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton(
                          onPressed: () => _showSurahDetail(lastReadChapter),
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: BrandColors.primaryDark,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            minimumSize: const Size(0, 34),
                          ),
                          child: const Text('Continue'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _HeaderQuickActionChip(
                        icon: Icons.search_rounded,
                        label: 'Search',
                        onTap: () => _searchFocusNode.requestFocus(),
                      ),
                      _HeaderQuickActionChip(
                        icon: Icons.menu_book_outlined,
                        label: 'Tilawat',
                        onTap: () => _showSurahDetail(lastReadChapter),
                      ),
                      _HeaderQuickActionChip(
                        icon: Icons.headphones_rounded,
                        label: 'Audio',
                        onTap: () => _showSurahDetail(
                          lastReadChapter,
                          autoStartAudio: true,
                        ),
                      ),
                      _HeaderQuickActionChip(
                        icon: _bookmarks.isEmpty
                            ? Icons.bookmark_border_rounded
                            : Icons.bookmarks_rounded,
                        label: 'Bookmarks',
                        onTap: _openBookmarksSheet,
                      ),
                      _HeaderQuickActionChip(
                        icon: Icons.ondemand_video_rounded,
                        label: 'Video',
                        onTap: _showVideoInfo,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Quick Surah',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final chapter in quickLinks) ...[
                          _HeaderSurahChip(
                            label: chapter.surahNameArabic,
                            onTap: () => _showSurahDetail(chapter),
                          ),
                          const SizedBox(width: 8),
                        ],
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
        : Colors.white.withValues(alpha: 0.95);
    final searchBorder = glass.isDark
        ? const Color(0x66A9C7DB)
        : const Color(0xFF99BED6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            focusNode: _searchFocusNode,
            style: TextStyle(
              color: glass.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Search by surah name or number',
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
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_usingCachedContent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: glass.isDark
                        ? const Color(0x7D152638)
                        : BrandColors.tintBackground,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: glass.isDark
                          ? const Color(0x55B4D8EE)
                          : BrandColors.border,
                    ),
                  ),
                  child: Text(
                    'Offline cache',
                    style: TextStyle(
                      fontSize: 12,
                      color: glass.isDark
                          ? const Color(0xFFC5E2F0)
                          : BrandColors.primaryDark,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              _FilterChipButton(
                label: '\u09b8\u09ac',
                selected: _filter == 'all',
                onTap: () => setState(() => _filter = 'all'),
              ),
              _FilterChipButton(
                label: '\u09ae\u0995\u09cd\u0995\u09c0',
                selected: _filter == 'meccan',
                onTap: () => setState(() => _filter = 'meccan'),
              ),
              _FilterChipButton(
                label: '\u09ae\u09be\u09a6\u09be\u09a8\u09c0',
                selected: _filter == 'medinan',
                onTap: () => setState(() => _filter = 'medinan'),
              ),
              FilterChip(
                selected: _showOnlyDownloaded,
                label: const Text(
                  '\u09a1\u09be\u0989\u09a8\u09b2\u09cb\u09a1\u09c7\u09a1',
                ),
                labelStyle: TextStyle(
                  color: _showOnlyDownloaded
                      ? (glass.isDark ? const Color(0xFF032F35) : Colors.white)
                      : glass.textPrimary,
                  fontWeight: _showOnlyDownloaded
                      ? FontWeight.w700
                      : FontWeight.w600,
                ),
                selectedColor: glass.accent.withValues(
                  alpha: glass.isDark ? 0.38 : 0.22,
                ),
                backgroundColor: glass.isDark
                    ? const Color(0x66162538)
                    : Colors.white.withValues(alpha: 0.94),
                checkmarkColor: _showOnlyDownloaded
                    ? (glass.isDark ? const Color(0xFF032F35) : Colors.white)
                    : glass.accent,
                side: BorderSide(
                  color: _showOnlyDownloaded
                      ? glass.accentSoft
                      : (glass.isDark
                            ? const Color(0x55B4D8EE)
                            : BrandColors.border),
                ),
                onSelected: (v) => setState(() => _showOnlyDownloaded = v),
              ),
            ],
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
                  const SizedBox(height: 6),
                  Text(
                    _bulkCacheFailed > 0
                        ? 'Audio is separate. Retry later to finish remaining text.'
                        : 'Audio is separate and can be downloaded per Surah.',
                    style: const TextStyle(
                      fontSize: 11,
                      color: BrandColors.textMuted,
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

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(),
              _buildSearchAndFilters(),
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
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                        itemCount: _filteredChapters.length,
                        itemBuilder: (context, index) {
                          final chapter = _filteredChapters[index];
                          final downloaded = _downloadedSurahNos.contains(
                            chapter.surahNo,
                          );
                          final downloading = _downloadingSurahNos.contains(
                            chapter.surahNo,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _QuranSurahTile(
                              chapter: chapter,
                              downloaded: downloaded,
                              downloading: downloading,
                              revelationLabel: _revelationLabel(
                                chapter.revelationPlace,
                              ),
                              onTap: () => _showSurahDetail(chapter),
                              onDownload: () =>
                                  _downloadSurahForOffline(chapter),
                              onOpenAudio: () => _showSurahDetail(chapter),
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

class _HeaderQuickActionChip extends StatelessWidget {
  const _HeaderQuickActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withValues(alpha: 0.32)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: Colors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderSurahChip extends StatelessWidget {
  const _HeaderSurahChip({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
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
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final bgColor = selected
        ? glass.accent
        : (glass.isDark
              ? const Color(0x66162538)
              : Colors.white.withValues(alpha: 0.94));
    final borderColor = selected
        ? glass.accentSoft
        : (glass.isDark ? const Color(0x55B4D8EE) : BrandColors.border);
    final textColor = selected
        ? (glass.isDark ? const Color(0xFF032F35) : Colors.white)
        : glass.textPrimary;

    return InkWell(
      borderRadius: BorderRadius.circular(100),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(100),
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
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
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
    required this.downloaded,
    required this.downloading,
    required this.revelationLabel,
    required this.onTap,
    required this.onDownload,
    required this.onOpenAudio,
  });

  final QuranChapter chapter;
  final bool downloaded;
  final bool downloading;
  final String revelationLabel;
  final VoidCallback onTap;
  final VoidCallback onDownload;
  final VoidCallback onOpenAudio;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    final translation = chapter.surahNameTranslation.trim().isEmpty
        ? 'Translation unavailable'
        : chapter.surahNameTranslation.trim();

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: NoorifyGlassCard(
          radius: BorderRadius.circular(16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          boxShadow: [
            BoxShadow(
              color: glass.isDark
                  ? const Color(0x32000000)
                  : const Color(0x170E3853),
              blurRadius: 13,
              offset: const Offset(0, 6),
            ),
          ],
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [glass.accentSoft, glass.accent],
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  chapter.surahNo.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
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
                      chapter.surahNameArabic,
                      style: TextStyle(
                        color: glass.textPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      chapter.surahName,
                      style: TextStyle(
                        color: glass.isDark
                            ? const Color(0xFFE4F1FA)
                            : const Color(0xFF21465F),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$revelationLabel - ${chapter.totalAyah} ayah - $translation',
                      style: TextStyle(
                        color: glass.isDark
                            ? const Color(0xFFC6DBEB)
                            : const Color(0xFF3F627B),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton.filledTonal(
                onPressed: downloading
                    ? null
                    : downloaded
                    ? onOpenAudio
                    : onDownload,
                style: IconButton.styleFrom(
                  backgroundColor: downloaded
                      ? (glass.isDark
                            ? const Color(0x331FD5C0)
                            : const Color(0x221EA8B8))
                      : (glass.isDark
                            ? const Color(0x3316383E)
                            : const Color(0x221EA8B8)),
                  foregroundColor: downloaded ? glass.accentSoft : glass.accent,
                ),
                icon: downloading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        downloaded
                            ? Icons.download_done_rounded
                            : Icons.download_rounded,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
