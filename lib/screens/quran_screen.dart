import 'package:flutter/material.dart';

import '../widgets/bottom_nav.dart';

class QuranScreen extends StatelessWidget {
  const QuranScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const pageBg = Color(0xFFF2F5F4);
    const surface = Colors.white;
    const accent = Color(0xFF0B9D78);
    const sectionBg = Color(0xFFEAF0EE);

    final quickLinks = <String>[
      'সূরা আল কাহফ',
      'সূরা ইয়াসীন',
      'সূরা আল-মুলক',
      'সূরা আর-রহমান',
    ];

    final surahItems = <_SurahItem>[
      _SurahItem(number: 1, nameBn: 'সূরা আল ফাতিহা', subtitleBn: 'সূচনা'),
      _SurahItem(number: 2, nameBn: 'সূরা আল বাকারা', subtitleBn: 'বকনা-বাছুর'),
      _SurahItem(
        number: 3,
        nameBn: 'সূরা আল ইমরান',
        subtitleBn: 'ইমরানের পরিবার',
      ),
      _SurahItem(number: 4, nameBn: 'সূরা আন নিসা', subtitleBn: 'মহিলা'),
      _SurahItem(
        number: 5,
        nameBn: 'সূরা আল মায়িদাহ',
        subtitleBn: 'খাদ্য পরিবেশিত টেবিল',
      ),
    ];

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: 96,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: surface,
                border: Border(bottom: BorderSide(color: Color(0xFFDCE5E2))),
              ),
              child: const Text(
                'কুরআন',
                style: TextStyle(
                  color: Color(0xFF2E4B44),
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  Container(
                    color: sectionBg,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _QuranActionButton(
                              icon: Icons.menu_book_outlined,
                              label: 'তিলাওয়াত',
                            ),
                            _QuranActionButton(
                              icon: Icons.search,
                              label: 'অনুসন্ধান',
                            ),
                            _QuranActionButton(
                              icon: Icons.bookmark,
                              label: 'বুকমার্ক',
                            ),
                            _QuranActionButton(
                              icon: Icons.settings,
                              label: 'সেটিংস',
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'কুইক লিংক',
                          style: TextStyle(
                            color: Color(0xFF294740),
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 44,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemBuilder: (context, index) =>
                                _QuickLinkChip(label: quickLinks[index]),
                            separatorBuilder: (_, index) =>
                                const SizedBox(width: 10),
                            itemCount: quickLinks.length,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD9E9E4),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.headphones, color: accent, size: 42),
                              SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'অনুবাদসহ কুরআন শুনুন',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Color(0xFF1D6F60),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'mahfil.net',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Color(0xFF4D6661),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right,
                                color: accent,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    color: surface,
                    child: Column(
                      children: surahItems
                          .map(
                            (item) => _SurahListTile(
                              number: item.number,
                              nameBn: item.nameBn,
                              subtitleBn: item.subtitleBn,
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ),
            ),
            bottomNav(context, 2),
          ],
        ),
      ),
    );
  }
}

class _QuranActionButton extends StatelessWidget {
  const _QuranActionButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 74,
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: const Color(0xFFDCEAE6),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFF0A9C79), size: 36),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF334E48), fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _QuickLinkChip extends StatelessWidget {
  const _QuickLinkChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFD7E9E2),
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF1A8A70),
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _SurahListTile extends StatelessWidget {
  const _SurahListTile({
    required this.number,
    required this.nameBn,
    required this.subtitleBn,
  });

  final int number;
  final String nameBn;
  final String subtitleBn;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFDCE5E2))),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF2D9A81), width: 2),
            ),
            child: Text(
              number.toString(),
              style: const TextStyle(
                color: Color(0xFF244A43),
                fontSize: 22,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nameBn,
                  style: const TextStyle(
                    color: Color(0xFF2C3F3B),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitleBn,
                  style: const TextStyle(
                    color: Color(0xFF5D6E69),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(
              Icons.download_for_offline_outlined,
              color: Color(0xFF90A49E),
              size: 30,
            ),
          ),
        ],
      ),
    );
  }
}

class _SurahItem {
  const _SurahItem({
    required this.number,
    required this.nameBn,
    required this.subtitleBn,
  });

  final int number;
  final String nameBn;
  final String subtitleBn;
}
