import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Palette
// ─────────────────────────────────────────────────────────────────────────────
const Color _kScrim = Color(0xFF0A1024); // near-black navy used for the scrim
const Color _kHeading = Color(0xFFFFFFFF);
const Color _kHighlight = Color(0xFF9DBDF7); // periwinkle accent
const Color _kBody = Color(0xFFD4DBEC);
const Color _kChipText = Color(0xFFE7ECFA);
const String _kFont = 'AirbnbCereal';

// ─────────────────────────────────────────────────────────────────────────────
//  Slide model
// ─────────────────────────────────────────────────────────────────────────────
class OnboardSlide {
  final String? chip;
  final String heading;
  final List<String> highlights;
  final String body;
  final String image;

  const OnboardSlide({
    this.chip,
    required this.heading,
    this.highlights = const [],
    required this.body,
    required this.image,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  Screen
// ─────────────────────────────────────────────────────────────────────────────
class OnboardingScreenV2 extends StatefulWidget {
  const OnboardingScreenV2({super.key});

  @override
  State<OnboardingScreenV2> createState() => _OnboardingScreenV2State();
}

class _OnboardingScreenV2State extends State<OnboardingScreenV2> {
  final PageController _controller = PageController();
  int _index = 0;

  static const List<OnboardSlide> _slides = [
    OnboardSlide(
      chip: '01 · YOUR DAY',
      heading: 'Your whole day,\nin a single view',
      highlights: ['single view'],
      body:
          'Shifts, tasks, mileage and live duty status — everything you need the moment you log on.',
      image: AppIcons.onboard1,
    ),
    OnboardSlide(
      chip: '02 · LIVE',
      heading: 'Your team,\non the map in real time',
      highlights: ['real time'],
      body:
          'See teammates live, share alerts, start a chat, or trigger SOS — stay connected wherever the day takes you.',
      image: AppIcons.onboard2,
    ),
    OnboardSlide(
      chip: '03 · EVIDENCE',
      heading: 'Capture proof,\nmanage every task',
      highlights: ['manage every task'],
      body:
          'Upload photos, videos, scans and audio from the field, and track every assignment in real time.',
      image: AppIcons.onboard3,
    ),
    OnboardSlide(
      chip: '04 · DETAILS',
      heading: 'Evidence details,\ntrack live updates',
      highlights: ['track live updates'],
      body:
          'Tap Manage Tasks to upload photos, videos, scans, audio recordings, and evidence directly from the field. Chat with your office, track live updates, and stay connected to every assignment in real time.',
      image: AppIcons.onboard4,
    ),
  ];

  bool get _isLast => _index == _slides.length - 1;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_seen', true);
    if (!mounted) return;
    context.go(AppRoutes.login);
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _back() {
    _controller.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light, // Android
        statusBarBrightness: Brightness.dark, // iOS
      ),
      child: Scaffold(
        backgroundColor: _kScrim,
        body: Stack(
          children: [
            // Full-bleed screenshot carousel.
            PageView.builder(
              controller: _controller,
              itemCount: _slides.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => _SlideView(slide: _slides[i]),
            ),

            // Top controls (Skip + back), inside the safe area.
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedOpacity(
                      opacity: _index > 0 ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: _PillButton(
                        onTap: _index > 0 ? _back : null,
                        child: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.white,
                          size: 16.sp,
                        ),
                      ),
                    ),
                    _PillButton(
                      onTap: _finish,
                      child: Text(
                        'Skip',
                        style: TextStyle(
                          color: Colors.white,
                          fontFamily: _kFont,
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom controls (dots + Next / Get started).
            Align(
              alignment: Alignment.bottomCenter,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 0, 20.w, 16.h),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildDots(),
                      SizedBox(height: 16.h),
                      _buildButton(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_slides.length, (i) {
        final active = i == _index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: EdgeInsets.symmetric(horizontal: 3.w),
          width: active ? 22.w : 7.w,
          height: 7.h,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4.r),
          ),
        );
      }),
    );
  }

  Widget _buildButton() {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: ElevatedButton(
        onPressed: _next,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26.r),
          ),
        ),
        child: Text(
          _isLast ? 'Get started' : 'Next',
          style: TextStyle(
            color: Colors.white,
            fontFamily: _kFont,
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Single slide — full-bleed screenshot + bottom scrim + text
// ─────────────────────────────────────────────────────────────────────────────
class _SlideView extends StatelessWidget {
  final OnboardSlide slide;

  const _SlideView({required this.slide});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      fit: StackFit.expand,
      children: [
        /// Circular Background Vectors (concentric half-circles)
        Positioned(
          top: -size.width * 0.5,
          left: -size.width * 0.3,
          child: Container(
            width: size.width * 1.6,
            height: size.width * 1.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.03),
                width: 1.w,
              ),
            ),
          ),
        ),
        Positioned(
          top: -size.width * 0.3,
          left: -size.width * 0.1,
          child: Container(
            width: size.width * 1.2,
            height: size.width * 1.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.05),
                width: 1.5.w,
              ),
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.12),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        /// Circular Background Vectors (concentric half-circles - bottom)
        Positioned(
          bottom: -size.width * 0.7,
          left: -size.width * 0.3,
          child: Container(
            width: size.width * 1.6,
            height: size.width * 1.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.06),
                width: 1.5.w,
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -size.width * 0.5,
          left: -size.width * 0.1,
          child: Container(
            width: size.width * 1.2,
            height: size.width * 1.2,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.12),
                width: 2.5.w,
              ),
              gradient: RadialGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.18),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        /// Image
        Positioned(
          top: MediaQuery.of(context).padding.top + 9.h,
          left: 19.w,
          right: 19.w,
          child: ClipRRect(
            borderRadius: BorderRadius.vertical(top: Radius.circular(22.r)),
            child: SizedBox(
              height: size.height * 0.55, // <-- Adjust this value
              child: Image.asset(
                slide.image,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (context, error, stack) => const _Placeholder(),
              ),
            ),
          ),
        ),

        /// Gradient Overlay
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x000A1024),
                Color(0x4D0A1024),
                Color(0xE60A1024),
                _kScrim,
              ],
              stops: [0.30, 0.52, 0.78, 1.0],
            ),
          ),
        ),

        /// Bottom Content
        Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            top: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(24.w, 0, 24.w, 96.h),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (slide.chip != null) ...[
                    _SectionChip(text: slide.chip!),
                    SizedBox(height: 14.h),
                  ],

                  _HighlightHeading(
                    text: slide.heading,
                    highlights: slide.highlights,
                    fontSize: size.width * 0.072,
                  ),

                  SizedBox(height: 12.h),

                  Text(
                    slide.body,
                    style: TextStyle(
                      color: _kBody,
                      fontFamily: _kFont,
                      fontSize: size.width * 0.037,
                      height: 1.45,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Labelled placeholder shown until the screenshot asset exists.
class _Placeholder extends StatelessWidget {
  const _Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF15275C),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.phone_iphone_rounded,
            size: 46.sp,
            color: Colors.white.withValues(alpha: 0.6),
          ),
          SizedBox(height: 10.h),
          Text(
            'App screen here',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontFamily: _kFont,
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Add the screenshot asset',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.45),
              fontFamily: _kFont,
              fontSize: 11.sp,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final VoidCallback? onTap;
  final Widget child;
  const _PillButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.40),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: child,
      ),
    );
  }
}

class _SectionChip extends StatelessWidget {
  final String text;
  const _SectionChip({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: _kChipText,
          fontFamily: _kFont,
          fontSize: 11.sp,
          letterSpacing: 1.0,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HighlightHeading extends StatelessWidget {
  final String text;
  final List<String> highlights;
  final double fontSize;
  const _HighlightHeading({
    required this.text,
    required this.highlights,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = TextStyle(
      color: _kHeading,
      fontFamily: _kFont,
      fontSize: fontSize,
      height: 1.2,
      fontWeight: FontWeight.w700,
    );
    final hiStyle = baseStyle.copyWith(color: _kHighlight);

    return RichText(
      text: TextSpan(
        style: baseStyle,
        children: _buildSpans(baseStyle, hiStyle),
      ),
    );
  }

  List<TextSpan> _buildSpans(TextStyle base, TextStyle hi) {
    if (highlights.isEmpty) return [TextSpan(text: text)];

    final spans = <TextSpan>[];
    String remaining = text;

    while (remaining.isNotEmpty) {
      int matchIndex = -1;
      String matchPhrase = '';
      for (final phrase in highlights) {
        if (phrase.isEmpty) continue;
        final idx = remaining.indexOf(phrase);
        if (idx != -1 && (matchIndex == -1 || idx < matchIndex)) {
          matchIndex = idx;
          matchPhrase = phrase;
        }
      }

      if (matchIndex == -1) {
        spans.add(TextSpan(text: remaining));
        break;
      }

      if (matchIndex > 0) {
        spans.add(TextSpan(text: remaining.substring(0, matchIndex)));
      }
      spans.add(TextSpan(text: matchPhrase, style: hi));
      remaining = remaining.substring(matchIndex + matchPhrase.length);
    }

    return spans;
  }
}
