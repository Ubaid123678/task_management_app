import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class AppIntroScreen extends StatefulWidget {
  const AppIntroScreen({super.key, required this.onDone});

  final Future<void> Function() onDone;

  @override
  State<AppIntroScreen> createState() => _AppIntroScreenState();
}

class _AppIntroScreenState extends State<AppIntroScreen> {
  final PageController _pageController = PageController();
  int _index = 0;

  static const List<_IntroData> _slides = <_IntroData>[
    _IntroData(
      title: 'Welcome to Task Orbit',
      subtitle:
          'Plan with clarity, execute with focus, and track what matters every day.',
      icon: Icons.checklist_rounded,
    ),
    _IntroData(
      title: 'Stay in Control',
      subtitle:
          'Use smart filters, recurring workflows, and progress tracking in one place.',
      icon: Icons.tune,
    ),
    _IntroData(
      title: 'Move Faster',
      subtitle:
          'Create tasks quickly, stay on schedule, and keep your momentum.',
      icon: Icons.rocket_launch,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _finishIntro() async {
    await widget.onDone();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final compact = MediaQuery.sizeOf(context).width < 390;
    final isLast = _index == _slides.length - 1;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              isDark ? const Color(0xFF0F172A) : const Color(0xFFE6FFFB),
              isDark ? const Color(0xFF111827) : const Color(0xFFFDFBF7),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: Row(
                  children: [
                    const _IntroLogo(),
                    const Spacer(),
                    TextButton(
                      onPressed: _finishIntro,
                      child: const Text('Skip'),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _slides.length,
                  onPageChanged: (value) {
                    setState(() {
                      _index = value;
                    });
                  },
                  itemBuilder: (context, index) {
                    final slide = _slides[index];
                    return Padding(
                      padding: EdgeInsets.fromLTRB(
                        compact ? 20 : 24,
                        20,
                        compact ? 20 : 24,
                        14,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: compact ? 96 : 112,
                            height: compact ? 96 : 112,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.brandTeal.withValues(
                                    alpha: 0.25,
                                  ),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Icon(
                              slide.icon,
                              color: Colors.white,
                              size: compact ? 42 : 48,
                            ),
                          ),
                          const SizedBox(height: 24),
                          Text(
                            slide.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            slide.subtitle,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                child: Row(
                  children: [
                    Row(
                      children: List<Widget>.generate(_slides.length, (index) {
                        final active = index == _index;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: active ? 22 : 8,
                          height: 8,
                          margin: const EdgeInsets.only(right: 6),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            color: active
                                ? AppTheme.brandTeal
                                : Theme.of(context).colorScheme.outlineVariant,
                          ),
                        );
                      }),
                    ),
                    const Spacer(),
                    FilledButton.icon(
                      onPressed: () async {
                        if (isLast) {
                          await _finishIntro();
                          return;
                        }
                        await _pageController.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        );
                      },
                      icon: Icon(isLast ? Icons.check : Icons.arrow_forward),
                      label: Text(isLast ? 'Get Started' : 'Next'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroLogo extends StatelessWidget {
  const _IntroLogo();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
              colors: [Color(0xFF0D9488), Color(0xFF14B8A6)],
            ),
          ),
          child: const Icon(
            Icons.checklist_rounded,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Text('Task Orbit', style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _IntroData {
  const _IntroData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}
