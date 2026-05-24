import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../models/app_enums.dart';
import '../../services/app_providers.dart';
import '../../services/app_router.dart';
import '../../widgets/meekz_theme.dart';
import '../../widgets/shared_widgets.dart';

// ─── Onboarding data ─────────────────────────────────────────────────────────
class _SlideData {
  const _SlideData({
    required this.emoji,
    required this.title,
    required this.body,
    required this.cardColor,
    required this.accentColor,
  });
  final String emoji;
  final String title;
  final String body;
  final Color cardColor;
  final Color accentColor;
}

List<_SlideData> _slidesFor(LanguageCode lang) {
  return switch (lang) {
    LanguageCode.ms => const [
        _SlideData(
          emoji: '🌟',
          title: 'Selamat Datang\nke Meekz',
          body:
              'Alat saringan berasaskan permainan yang membantu mengenal pasti petunjuk pembelajaran awal kanak-kanak berumur 6 hingga 8 tahun.',
          cardColor: MeekzColors.pastelBlue,
          accentColor: MeekzColors.literacy,
        ),
        _SlideData(
          emoji: '🎮',
          title: 'Seronok untuk kanak-kanak,\nBerguna untuk anda',
          body:
              'Permainan pendek merangkumi literasi, numerasi, dan tumpuan — selesai dalam beberapa minit sahaja.',
          cardColor: MeekzColors.pastelGreen,
          accentColor: MeekzColors.numeracy,
        ),
        _SlideData(
          emoji: '📋',
          title: 'Petunjuk pembelajaran awal',
          body:
              'Meekz menyediakan petunjuk awal untuk membimbing perbincangan dengan guru dan profesional yang berkelayakan.',
          cardColor: MeekzColors.pastelYellow,
          accentColor: MeekzColors.warning,
        ),
      ],
    LanguageCode.zh => const [
        _SlideData(
          emoji: '🌟',
          title: '欢迎使用 Meekz',
          body: '一款趣味化筛查工具，帮助发现6至8岁儿童的早期学习相关指标。',
          cardColor: MeekzColors.pastelBlue,
          accentColor: MeekzColors.literacy,
        ),
        _SlideData(
          emoji: '🎮',
          title: '孩子觉得好玩，\n您获得洞察',
          body: '涵盖读写、数学和注意力的简短互动游戏 — 几分钟即可完成。',
          cardColor: MeekzColors.pastelGreen,
          accentColor: MeekzColors.numeracy,
        ),
        _SlideData(
          emoji: '📋',
          title: '初步学习指标',
          body: 'Meekz 提供初步指标，引导您与教师及合格专业人员展开讨论。',
          cardColor: MeekzColors.pastelYellow,
          accentColor: MeekzColors.warning,
        ),
      ],
    LanguageCode.en => const [
        _SlideData(
          emoji: '🌟',
          title: 'Welcome to Meekz',
          body:
              'A gentle, gamified screening tool that helps spot early learning-related indicators in children aged 6 to 8.',
          cardColor: MeekzColors.pastelBlue,
          accentColor: MeekzColors.literacy,
        ),
        _SlideData(
          emoji: '🎮',
          title: 'Fun for children,\nInsightful for you',
          body:
              'Short, engaging games across literacy, numeracy, and attention — completed in minutes, not hours.',
          cardColor: MeekzColors.pastelGreen,
          accentColor: MeekzColors.numeracy,
        ),
        _SlideData(
          emoji: '📋',
          title: 'Preliminary learning indicators',
          body:
              'Meekz provides preliminary indicators to guide conversations with teachers and qualified professionals.',
          cardColor: MeekzColors.pastelYellow,
          accentColor: MeekzColors.warning,
        ),
      ],
  };
}

// ── Localized button labels ─────────────────────────────────────────────────
String _nextLabel(LanguageCode lang) => switch (lang) {
      LanguageCode.ms => 'Seterusnya',
      LanguageCode.zh => '下一步',
      LanguageCode.en => 'Next',
    };

String _getStartedLabel(LanguageCode lang) => switch (lang) {
      LanguageCode.ms => 'Mula',
      LanguageCode.zh => '开始使用',
      LanguageCode.en => 'Get Started',
    };

String _skipLabel(LanguageCode lang) => switch (lang) {
      LanguageCode.ms => 'Langkau',
      LanguageCode.zh => '跳过',
      LanguageCode.en => 'Skip',
    };

// ─── Screen ──────────────────────────────────────────────────────────────────
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  void _next(List<_SlideData> slides) {
    if (_page < slides.length - 1) {
      _pageController.nextPage(
          duration: const Duration(milliseconds: 380), curve: Curves.easeOut);
    } else {
      context.go(MeekzRoutes.auth);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(selectedLanguageProvider);
    final slides = _slidesFor(lang);

    return Scaffold(
      backgroundColor: MeekzColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Language picker ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  _LanguageButton(
                    label: 'EN',
                    selected: lang == LanguageCode.en,
                    onTap: () => ref
                        .read(selectedLanguageProvider.notifier)
                        .state = LanguageCode.en,
                  ),
                  const SizedBox(width: 8),
                  _LanguageButton(
                    label: 'BM',
                    selected: lang == LanguageCode.ms,
                    onTap: () => ref
                        .read(selectedLanguageProvider.notifier)
                        .state = LanguageCode.ms,
                  ),
                  const SizedBox(width: 8),
                  _LanguageButton(
                    label: '中文',
                    selected: lang == LanguageCode.zh,
                    onTap: () => ref
                        .read(selectedLanguageProvider.notifier)
                        .state = LanguageCode.zh,
                  ),
                ],
              ),
            ),

            // ── Slides ────────────────────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: slides.length,
                itemBuilder: (_, i) => _OnboardingSlide(data: slides[i]),
              ),
            ),

            // ── Dots + CTA ────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: Column(
                children: [
                  // Animated page-indicator dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      slides.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 280),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: i == _page ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == _page
                              ? slides[_page].accentColor
                              : MeekzColors.border,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  MeekzButton(
                    label: _page == slides.length - 1
                        ? _getStartedLabel(lang)
                        : _nextLabel(lang),
                    onPressed: () => _next(slides),
                    icon: _page == slides.length - 1
                        ? Icons.arrow_forward_rounded
                        : null,
                  ),
                  if (_page < slides.length - 1) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go(MeekzRoutes.auth),
                      child: Text(
                        _skipLabel(lang),
                        style: GoogleFonts.quicksand(
                          color: MeekzColors.muted,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Single slide ─────────────────────────────────────────────────────────────
class _OnboardingSlide extends StatelessWidget {
  const _OnboardingSlide({required this.data});
  final _SlideData data;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Coloured hero card with large emoji
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
            decoration: BoxDecoration(
              color: data.cardColor,
              borderRadius: BorderRadius.circular(MeekzRadius.xl),
              border:
                  Border.all(color: data.accentColor.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: [
                Text(data.emoji, style: const TextStyle(fontSize: 80)),
                const SizedBox(height: 16),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: MeekzColors.ink,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Body copy outside the card — reads easily against warm bg.
          Text(
            data.body,
            textAlign: TextAlign.center,
            style: GoogleFonts.quicksand(
              fontSize: 15,
              color: MeekzColors.muted,
              height: 1.65,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Language selector button ─────────────────────────────────────────────────
class _LanguageButton extends StatelessWidget {
  const _LanguageButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? MeekzColors.primary : MeekzColors.surface,
          borderRadius: BorderRadius.circular(MeekzRadius.pill),
          border: Border.all(
            color: selected ? MeekzColors.primary : MeekzColors.border,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : MeekzColors.muted,
          ),
        ),
      ),
    );
  }
}
