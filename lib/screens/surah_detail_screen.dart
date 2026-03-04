import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import '../app/brand_colors.dart';
import '../models/quran_models.dart';
import '../services/quran_api_service.dart';
import '../services/quran_offline_download_service.dart';
import '../services/quran_timing_service.dart';

class SurahDetailScreen extends StatefulWidget {
  const SurahDetailScreen({
    super.key,
    required this.chapter,
    this.autoStartAudio = false,
  });

  final QuranChapter chapter;
  final bool autoStartAudio;

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  final QuranApiService _api = QuranApiService();
  final QuranOfflineDownloadService _offline = QuranOfflineDownloadService();
  final QuranTimingService _timing = QuranTimingService();
  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<PlayerState>? _playerStateSub;
  StreamSubscription<Duration>? _positionSub;
  StreamSubscription<Duration?>? _durationSub;

  QuranSurahDetail? _detail;
  String? _error;
  bool _isLoading = true;
  bool _isPreparingAudio = false;
  bool _isDownloadingAudio = false;
  bool _didDownloadAudio = false;
  bool _usingCachedContent = false;
  bool _showBottomPlayer = false;

  int? _selectedReciterId;
  String? _preparedAudioUrl;
  final Set<String> _cachedAudioUrls = {};
  int? _timingRecitationId;
  String? _timingAudioUrl;
  List<QuranTimingSegment> _timingSegments = const [];

  bool _isPlaying = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  final Map<int, GlobalKey> _ayahItemKeys = {};
  int _lastAutoScrolledAyahIndex = -1;

  @override
  void initState() {
    super.initState();
    _bindAudioStreams();
    _loadSurahDetail();
  }

  @override
  void dispose() {
    _playerStateSub?.cancel();
    _positionSub?.cancel();
    _durationSub?.cancel();
    _player.dispose();
    super.dispose();
  }

  void _bindAudioStreams() {
    _playerStateSub = _player.playerStateStream.listen((state) {
      if (!mounted) return;
      setState(() {
        _isPlaying = state.playing;
      });
    });

    _positionSub = _player.positionStream.listen((position) {
      if (!mounted) return;
      setState(() => _position = position);
    });

    _durationSub = _player.durationStream.listen((duration) {
      if (!mounted) return;
      setState(() => _duration = duration ?? Duration.zero);
    });
  }

  Future<void> _loadSurahDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final detail = await _api.fetchSurahDetail(
        widget.chapter.surahNo,
        lang: 'bn',
      );
      final fromCache = _api.lastReadFromCache;
      final cachedUrls = <String>{};
      for (final reciter in detail.audioByReciter) {
        final isCached = await _offline.hasAudio(reciter.url);
        if (isCached) cachedUrls.add(reciter.url);
      }

      if (!mounted) return;
      setState(() {
        _detail = detail;
        _selectedReciterId = detail.audioByReciter.isNotEmpty
            ? detail.audioByReciter.first.id
            : null;
        _cachedAudioUrls
          ..clear()
          ..addAll(cachedUrls);
        _usingCachedContent = fromCache;
        _timingRecitationId = null;
        _timingAudioUrl = null;
        _timingSegments = const [];
        _preparedAudioUrl = null;
        _showBottomPlayer = widget.autoStartAudio;
        _isLoading = false;
      });

      await _resolveTimingForSelectedReciter();

      if (widget.autoStartAudio) {
        await _togglePlayPause();
      }

      if (!mounted) return;
      if (fromCache) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('অফলাইন সেভ করা সূরার কনটেন্ট দেখানো হচ্ছে।'),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error =
            'সূরার বিস্তারিত লোড করা যায়নি। একবার ইন্টারনেট অন করে এই সূরা খুলুন, পরে অফলাইনে পাবেন।';
        _isLoading = false;
      });
    }
  }

  Future<void> _resolveTimingForSelectedReciter() async {
    final reciter = _selectedReciter;
    if (reciter == null) return;

    final recitationId = _timing.recitationIdForReciterName(reciter.reciter);
    if (recitationId == null) {
      if (!mounted) return;
      setState(() {
        _timingRecitationId = null;
        _timingAudioUrl = null;
        _timingSegments = const [];
        _preparedAudioUrl = null;
      });
      return;
    }

    try {
      final timing = await _timing.fetchChapterTiming(
        surahNo: widget.chapter.surahNo,
        recitationId: recitationId,
      );
      final cached = await _offline.hasAudio(timing.audioUrl);
      if (!mounted) return;
      setState(() {
        _timingRecitationId = timing.recitationId;
        _timingAudioUrl = timing.audioUrl;
        _timingSegments = timing.segments;
        _preparedAudioUrl = null;
        if (cached) _cachedAudioUrls.add(timing.audioUrl);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _timingRecitationId = null;
        _timingAudioUrl = null;
        _timingSegments = const [];
        _preparedAudioUrl = null;
      });
    }
  }

  QuranReciterAudio? get _selectedReciter {
    final detail = _detail;
    if (detail == null || detail.audioByReciter.isEmpty) return null;
    if (_selectedReciterId == null) return detail.audioByReciter.first;

    for (final reciter in detail.audioByReciter) {
      if (reciter.id == _selectedReciterId) return reciter;
    }
    return detail.audioByReciter.first;
  }

  String _toBanglaDigits(String input) {
    const latin = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const bangla = ['০', '১', '২', '৩', '৪', '৫', '৬', '৭', '৮', '৯'];
    var output = input;
    for (var i = 0; i < latin.length; i++) {
      output = output.replaceAll(latin[i], bangla[i]);
    }
    return output;
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  int _activeAyahIndex(int totalAyah) {
    if (totalAyah <= 0) return -1;
    final hasPlaybackStarted = _isPlaying || _position > Duration.zero;
    if (!hasPlaybackStarted) return -1;

    if (_timingSegments.isNotEmpty) {
      final currentMs = _position.inMilliseconds;
      for (final seg in _timingSegments) {
        if (currentMs >= seg.fromMs && currentMs <= seg.toMs) {
          return seg.ayahIndex.clamp(0, totalAyah - 1);
        }
      }

      if (currentMs > _timingSegments.last.toMs) {
        return _timingSegments.last.ayahIndex.clamp(0, totalAyah - 1);
      }
      if (currentMs < _timingSegments.first.fromMs) {
        return _timingSegments.first.ayahIndex.clamp(0, totalAyah - 1);
      }
    }

    final totalMs = _duration.inMilliseconds;
    if (totalMs <= 0) return -1;
    final currentMs = _position.inMilliseconds.clamp(0, totalMs);
    final progress = currentMs / totalMs;
    final index = (progress * totalAyah).floor();
    return index.clamp(0, totalAyah - 1);
  }

  QuranTimingSegment? _timingSegmentForAyah(int ayahIndex) {
    for (final seg in _timingSegments) {
      if (seg.ayahIndex == ayahIndex) return seg;
    }
    return null;
  }

  int _activeWordIndexForAyah(int ayahIndex, String arabicText) {
    final hasPlaybackStarted = _isPlaying || _position > Duration.zero;
    if (!hasPlaybackStarted) return -1;
    if (_timingSegments.isEmpty || arabicText.trim().isEmpty) return -1;
    final timing = _timingSegmentForAyah(ayahIndex);
    if (timing == null || timing.wordSegments.isEmpty) return -1;

    final currentMs = _position.inMilliseconds;
    for (final word in timing.wordSegments) {
      if (currentMs >= word.fromMs && currentMs <= word.toMs) {
        return word.wordIndex;
      }
    }

    if (currentMs > timing.wordSegments.last.toMs) {
      return timing.wordSegments.last.wordIndex;
    }
    if (currentMs < timing.wordSegments.first.fromMs) {
      return timing.wordSegments.first.wordIndex;
    }
    return -1;
  }

  void _maybeAutoScrollToAyah(int ayahIndex) {
    if (!_isPlaying || ayahIndex < 0) return;
    if (_lastAutoScrolledAyahIndex == ayahIndex) return;
    _lastAutoScrolledAyahIndex = ayahIndex;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final key = _ayahItemKeys[ayahIndex];
      final context = key?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        duration: const Duration(milliseconds: 340),
        curve: Curves.easeOutCubic,
        alignment: 0.18,
      );
    });
  }

  Key _keyForAyahItem(int ayahIndex) {
    return _ayahItemKeys.putIfAbsent(ayahIndex, GlobalKey.new);
  }

  Widget _buildArabicAyahText({
    required String arabic,
    required int highlightedWordIndex,
  }) {
    const baseStyle = TextStyle(
      fontSize: 24,
      height: 1.7,
      fontWeight: FontWeight.w600,
      color: BrandColors.textPrimary,
    );

    final cleaned = arabic.trim();
    if (cleaned.isEmpty) {
      return const SizedBox.shrink();
    }

    if (highlightedWordIndex < 0) {
      return Text(
        cleaned,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: baseStyle,
      );
    }

    final words = cleaned.split(RegExp(r'\s+'));
    if (words.isEmpty) {
      return Text(
        cleaned,
        textDirection: TextDirection.rtl,
        textAlign: TextAlign.right,
        style: baseStyle,
      );
    }

    final maxWordIndex = words.length - 1;
    final safeWordIndex = highlightedWordIndex.clamp(0, maxWordIndex);

    final spans = <InlineSpan>[];
    for (var i = 0; i < words.length; i++) {
      final word = words[i];
      final isHighlighted = i == safeWordIndex;
      spans.add(
        TextSpan(
          text: i == words.length - 1 ? word : '$word ',
          style: baseStyle.copyWith(
            color: isHighlighted
                ? BrandColors.primaryDark
                : BrandColors.textPrimary,
            fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
            backgroundColor: isHighlighted
                ? const Color(0x553AD1FF)
                : Colors.transparent,
          ),
        ),
      );
    }

    return RichText(
      textDirection: TextDirection.rtl,
      textAlign: TextAlign.right,
      text: TextSpan(children: spans),
    );
  }

  Future<void> _onReciterChanged(int? reciterId) async {
    if (reciterId == null || reciterId == _selectedReciterId) return;
    await _player.stop();
    if (!mounted) return;
    setState(() {
      _selectedReciterId = reciterId;
      _preparedAudioUrl = null;
      _timingRecitationId = null;
      _timingAudioUrl = null;
      _timingSegments = const [];
      _position = Duration.zero;
      _duration = Duration.zero;
      _lastAutoScrolledAyahIndex = -1;
    });
    await _resolveTimingForSelectedReciter();
  }

  String _playbackUrlFor(QuranReciterAudio reciter) {
    if (_timingAudioUrl != null && _timingRecitationId != null) {
      return _timingAudioUrl!;
    }
    return reciter.url;
  }

  Future<void> _prepareAudio(QuranReciterAudio reciter) async {
    final playbackUrl = _playbackUrlFor(reciter);
    final cachedFile = await _offline.getCachedAudio(playbackUrl);
    if (cachedFile != null) {
      await _player.setFilePath(cachedFile.path);
      _cachedAudioUrls.add(playbackUrl);
      return;
    }
    await _player.setUrl(playbackUrl);
  }

  Future<void> _togglePlayPause() async {
    if (_isPlaying) {
      await _player.pause();
      return;
    }

    final reciter = _selectedReciter;
    if (reciter == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('এই সূরার অডিও পাওয়া যায়নি')),
      );
      return;
    }

    final playbackUrl = _playbackUrlFor(reciter);
    if (_preparedAudioUrl == playbackUrl && _player.audioSource != null) {
      await _player.play();
      return;
    }

    setState(() => _isPreparingAudio = true);
    try {
      await _prepareAudio(reciter);
      await _player.play();
      if (!mounted) return;
      setState(() {
        _preparedAudioUrl = playbackUrl;
        _isPreparingAudio = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isPreparingAudio = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('অডিও প্লে করা যায়নি। ইন্টারনেট চেক করুন।'),
        ),
      );
    }
  }

  Future<void> _stopAudio() async {
    await _player.stop();
    if (!mounted) return;
    setState(() {
      _position = Duration.zero;
      _duration = Duration.zero;
      _lastAutoScrolledAyahIndex = -1;
    });
  }

  Future<void> _downloadSelectedAudio() async {
    final reciter = _selectedReciter;
    if (reciter == null || _isDownloadingAudio) return;
    final playbackUrl = _playbackUrlFor(reciter);

    setState(() => _isDownloadingAudio = true);
    try {
      final path = await _offline.downloadAudio(playbackUrl);
      if (!mounted) return;
      setState(() {
        _cachedAudioUrls.add(playbackUrl);
        _isDownloadingAudio = false;
        _didDownloadAudio = true;
      });
      final fileName = path.split('\\').last.split('/').last;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('অডিও সেভ হয়েছে: $fileName')));
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDownloadingAudio = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অডিও ডাউনলোড ব্যর্থ হয়েছে')),
      );
    }
  }

  Widget _buildAudioCard(QuranSurahDetail detail) {
    final reciter = _selectedReciter;
    final hasReciters = detail.audioByReciter.isNotEmpty;
    final playbackUrl = reciter == null ? null : _playbackUrlFor(reciter);
    final isCached =
        playbackUrl != null && _cachedAudioUrls.contains(playbackUrl);
    final hasExactTiming =
        _timingSegments.isNotEmpty &&
        _timingAudioUrl != null &&
        _timingRecitationId != null;

    final durationMs = _duration.inMilliseconds;
    final maxMs = durationMs > 0 ? durationMs : 1;
    final currentMs = _position.inMilliseconds.clamp(0, maxMs);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: BrandColors.border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${detail.surahName} • ${_toBanglaDigits(detail.surahNo.toString())}',
                    style: const TextStyle(
                      color: BrandColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Hide player',
                  visualDensity: VisualDensity.compact,
                  onPressed: () => setState(() => _showBottomPlayer = false),
                  icon: const Icon(
                    Icons.close_rounded,
                    color: BrandColors.textMuted,
                  ),
                ),
              ],
            ),
            if (_usingCachedContent) ...[
              const SizedBox(height: 2),
              const Text(
                'Offline saved content',
                style: TextStyle(
                  fontSize: 11,
                  color: BrandColors.textMuted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 6),
            if (hasReciters)
              InputDecorator(
                decoration: InputDecoration(
                  labelText: 'রিসাইটার',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    value: _selectedReciter?.id,
                    items: detail.audioByReciter
                        .map(
                          (reciter) => DropdownMenuItem<int>(
                            value: reciter.id,
                            child: Text(
                              reciter.reciter,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(growable: false),
                    onChanged: _onReciterChanged,
                  ),
                ),
              )
            else
              const Text(
                'এই সূরার জন্য অডিও সোর্স পাওয়া যায়নি।',
                style: TextStyle(
                  color: Color(0xFF7A4444),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            const SizedBox(height: 8),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
              ),
              child: Slider(
                value: currentMs.toDouble(),
                min: 0,
                max: maxMs.toDouble(),
                onChanged: durationMs > 0
                    ? (value) =>
                          _player.seek(Duration(milliseconds: value.round()))
                    : null,
              ),
            ),
            Row(
              children: [
                Text(
                  _formatDuration(_position),
                  style: const TextStyle(
                    fontSize: 12,
                    color: BrandColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatDuration(_duration),
                  style: const TextStyle(
                    fontSize: 12,
                    color: BrandColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              hasExactTiming
                  ? 'Exact ayah timing sync enabled'
                  : 'Approximate sync (timing not available for this reciter)',
              style: const TextStyle(
                fontSize: 11,
                color: BrandColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: hasReciters && !_isPreparingAudio
                        ? _togglePlayPause
                        : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: BrandColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    icon: _isPreparingAudio
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                          ),
                    label: Text(_isPlaying ? 'Pause' : 'Play'),
                  ),
                ),
                const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: _isPlaying || _position > Duration.zero
                      ? _stopAudio
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: BrandColors.primaryDark,
                    side: const BorderSide(color: BrandColors.border),
                  ),
                  icon: const Icon(Icons.stop_rounded),
                  label: const Text('Stop'),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: hasReciters && !_isDownloadingAudio
                      ? _downloadSelectedAudio
                      : null,
                  style: FilledButton.styleFrom(
                    backgroundColor: BrandColors.tintBackgroundStrong,
                    foregroundColor: BrandColors.primaryDark,
                  ),
                  icon: _isDownloadingAudio
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          isCached
                              ? Icons.download_done_rounded
                              : Icons.download_rounded,
                        ),
                  label: Text(isCached ? 'Saved' : 'Offline'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAyahCard({
    Key? itemKey,
    required int index,
    required String arabic,
    required String bengali,
    required bool highlighted,
    required int highlightedWordIndex,
  }) {
    return AnimatedContainer(
      key: itemKey,
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFEAF7FB) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: highlighted ? BrandColors.primaryLight : BrandColors.border,
          width: highlighted ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: highlighted
                      ? BrandColors.tintBackgroundStrong
                      : BrandColors.tintBackground,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  _toBanglaDigits((index + 1).toString()),
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: BrandColors.primaryDark,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                highlighted ? 'আরবি + বাংলা • চলছে' : 'আরবি + বাংলা',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: highlighted
                      ? BrandColors.primaryDark
                      : BrandColors.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          if (arabic.isNotEmpty) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: _buildArabicAyahText(
                arabic: arabic,
                highlightedWordIndex: highlighted ? highlightedWordIndex : -1,
              ),
            ),
          ],
          if (bengali.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              bengali,
              style: const TextStyle(
                fontSize: 15,
                height: 1.6,
                color: BrandColors.textPrimary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_didDownloadAudio);
      },
      child: Scaffold(
        backgroundColor: BrandColors.screenBackground,
        appBar: AppBar(
          backgroundColor: BrandColors.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(_didDownloadAudio),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          title: Text(widget.chapter.surahName),
          actions: [
            IconButton(
              tooltip: 'Audio player',
              onPressed: _detail == null
                  ? null
                  : () => setState(() => _showBottomPlayer = true),
              icon: const Icon(Icons.headphones_rounded),
            ),
          ],
        ),
        bottomNavigationBar: _detail != null && _showBottomPlayer
            ? _buildAudioCard(_detail!)
            : null,
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!),
                    const SizedBox(height: 8),
                    FilledButton(
                      onPressed: _loadSurahDetail,
                      style: FilledButton.styleFrom(
                        backgroundColor: BrandColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('আবার চেষ্টা করুন'),
                    ),
                  ],
                ),
              )
            : Builder(
                builder: (context) {
                  final detail = _detail!;
                  final totalAyah = math.max(
                    detail.arabicAyahs.length,
                    detail.bengaliAyahs.length,
                  );
                  final activeAyahIndex = _activeAyahIndex(totalAyah);
                  _maybeAutoScrollToAyah(activeAyahIndex);

                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _showBottomPlayer
                                    ? 'Player is active at bottom'
                                    : 'Audio player hidden for reading',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: BrandColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            TextButton.icon(
                              onPressed: () =>
                                  setState(() => _showBottomPlayer = true),
                              icon: const Icon(
                                Icons.headphones_rounded,
                                size: 16,
                              ),
                              label: const Text('Play Audio'),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                          itemCount: totalAyah,
                          separatorBuilder: (_, index) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final arabic = index < detail.arabicAyahs.length
                                ? detail.arabicAyahs[index]
                                : '';
                            final bengali = index < detail.bengaliAyahs.length
                                ? detail.bengaliAyahs[index]
                                : '';
                            final wordHighlightIndex = _activeWordIndexForAyah(
                              index,
                              arabic,
                            );

                            return _buildAyahCard(
                              itemKey: _keyForAyahItem(index),
                              index: index,
                              arabic: arabic,
                              bengali: bengali,
                              highlighted: index == activeAyahIndex,
                              highlightedWordIndex: wordHighlightIndex,
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }
}
