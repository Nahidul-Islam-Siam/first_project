import 'package:flutter/material.dart';

import 'package:first_project/features/asmaul_husna/models/asma_name.dart';
import 'package:first_project/features/asmaul_husna/services/asma_service.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';
import 'package:first_project/shared/widgets/bottom_nav.dart';

class AsmaScreen extends StatefulWidget {
  const AsmaScreen({super.key});

  @override
  State<AsmaScreen> createState() => _AsmaScreenState();
}

class _AsmaScreenState extends State<AsmaScreen> {
  final AsmaService _asmaService = AsmaService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  String? _error;
  String _query = '';
  List<AsmaName> _names = const [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _loadAsmaNames();
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (!mounted) return;
    setState(() => _query = _searchController.text.trim().toLowerCase());
  }

  Future<void> _loadAsmaNames() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final names = await _asmaService.loadAsmaNames();
      if (!mounted) return;
      setState(() {
        _names = names;
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

  List<AsmaName> get _filteredNames {
    if (_query.isEmpty) return _names;
    return _names
        .where((item) {
          return item.id.toString().contains(_query) ||
              item.arabic.contains(_query) ||
              item.transliteration.toLowerCase().contains(_query) ||
              item.englishMeaning.toLowerCase().contains(_query) ||
              item.banglaName.toLowerCase().contains(_query) ||
              item.banglaMeaning.toLowerCase().contains(_query);
        })
        .toList(growable: false);
  }

  void _onTapPlay(AsmaName item) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Audio playback integration is next step.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredNames = _filteredNames;
    final glass = NoorifyGlassTheme(context);

    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              _AsmaHeader(
                searchController: _searchController,
                total: _names.length,
                shown: filteredNames.length,
              ),
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: glass.accent),
                      )
                    : _error != null
                    ? _AsmaErrorView(error: _error!, onRetry: _loadAsmaNames)
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
                        itemCount: filteredNames.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = filteredNames[index];
                          final hasAudio = (item.audio ?? '').trim().isNotEmpty;
                          return _AsmaNameCard(
                            item: item,
                            hasAudio: hasAudio,
                            onPlay: () => _onTapPlay(item),
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

class _AsmaHeader extends StatelessWidget {
  const _AsmaHeader({
    required this.searchController,
    required this.total,
    required this.shown,
  });

  final TextEditingController searchController;
  final int total;
  final int shown;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Padding(
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
                    'Asma Ul Husna',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                        ? const Color(0x331FD5C0)
                        : const Color(0x1F1EA8B8),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: glass.glassBorder),
                  ),
                  child: Text(
                    '$shown/$total',
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
              '99 Beautiful Names of Allah',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: glass.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: searchController,
              style: TextStyle(color: glass.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search name, meaning, or number',
                hintStyle: TextStyle(color: glass.textMuted),
                prefixIcon: Icon(Icons.search_rounded, color: glass.textMuted),
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
    );
  }
}

class _AsmaErrorView extends StatelessWidget {
  const _AsmaErrorView({required this.error, required this.onRetry});

  final String error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              error,
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
              onPressed: onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AsmaNameCard extends StatelessWidget {
  const _AsmaNameCard({
    required this.item,
    required this.hasAudio,
    required this.onPlay,
  });

  final AsmaName item;
  final bool hasAudio;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return NoorifyGlassCard(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      radius: BorderRadius.circular(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: glass.isDark
                      ? const Color(0x331FD5C0)
                      : const Color(0x221EA8B8),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.id.toString(),
                  style: TextStyle(
                    color: glass.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Spacer(),
              IconButton.filledTonal(
                tooltip: hasAudio ? 'Play audio' : 'No audio yet',
                onPressed: hasAudio ? onPlay : null,
                style: IconButton.styleFrom(
                  backgroundColor: glass.isDark
                      ? const Color(0x3316383E)
                      : const Color(0x221EA8B8),
                  foregroundColor: glass.accent,
                ),
                icon: const Icon(Icons.play_arrow_rounded),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              item.arabic,
              textDirection: TextDirection.rtl,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            item.transliteration,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: glass.accentSoft,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            item.englishMeaning,
            style: TextStyle(fontSize: 13, color: glass.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            '${item.banglaName} - ${item.banglaMeaning}',
            style: TextStyle(fontSize: 13, color: glass.textMuted),
          ),
        ],
      ),
    );
  }
}
