import 'package:flutter/material.dart';

import 'package:first_project/features/quran/services/quran_bookmarks_service.dart';
import 'package:first_project/shared/widgets/noorify_glass.dart';

class QuranBookmarksScreen extends StatelessWidget {
  const QuranBookmarksScreen({super.key, required this.bookmarks});

  final List<QuranAyahBookmark> bookmarks;

  @override
  Widget build(BuildContext context) {
    final glass = NoorifyGlassTheme(context);
    return Scaffold(
      backgroundColor: glass.bgBottom,
      body: NoorifyGlassBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Saved Bookmarks',
                        style: TextStyle(
                          color: glass.textPrimary,
                          fontSize: 21,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${bookmarks.length}',
                      style: TextStyle(
                        color: glass.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  itemCount: bookmarks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = bookmarks[index];
                    final note = item.note.trim();
                    final subtitle = note.isEmpty
                        ? 'Surah ${item.surahNo}, Ayah ${item.ayahNo}'
                        : note;
                    return Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => Navigator.of(context).pop(item),
                        child: NoorifyGlassCard(
                          radius: BorderRadius.circular(16),
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: glass.accent.withValues(alpha: 0.17),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: glass.accentSoft,
                                    width: 1.2,
                                  ),
                                ),
                                child: Icon(
                                  Icons.bookmark_rounded,
                                  size: 20,
                                  color: glass.accent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${item.surahName} \u2022 Ayah ${item.ayahNo}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: glass.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      subtitle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: glass.textSecondary,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              Icon(
                                Icons.arrow_forward_ios_rounded,
                                size: 16,
                                color: glass.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
