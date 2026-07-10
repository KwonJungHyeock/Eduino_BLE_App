// Author: eduino
// Neo Cockpit 디자인 토큰 (§6.1 컬러 · §6.2 타이포 · §6.3 원칙)
// 다크 계기판/조종석 은유. 네온 글로우는 절제, 색 대비로 표현.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// §6.1 컬러 팔레트 (다크)
abstract class AppColors {
  static const Color baseBg = Color(0xFF12151C);
  static const Color surface = Color(0xFF171B24);
  static const Color surfaceHigh = Color(0xFF1E2431); // elevation 한 단계 위
  static const Color border = Color(0xFF2A3140);
  static const Color accent = Color(0xFFE31E24); // EDUINO 레드 · 정지/강조
  static const Color signal = Color(0xFF7CE0C3); // 연결/텔레메트리 정상
  static const Color textPrimary = Color(0xFFE8ECF2);
  static const Color textMuted = Color(0xFF5B6472);
  static const Color warn = Color(0xFFF5A524);
}

/// 8pt 그리드 간격 토큰 (§6.4 여백과 정밀 그리드)
abstract class Gap {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const SizedBox h4 = SizedBox(height: xs);
  static const SizedBox h8 = SizedBox(height: sm);
  static const SizedBox h16 = SizedBox(height: md);
  static const SizedBox h24 = SizedBox(height: lg);
  static const SizedBox w8 = SizedBox(width: sm);
  static const SizedBox w16 = SizedBox(width: md);
  static const SizedBox w24 = SizedBox(width: lg);
}

/// 반경 토큰
abstract class Radii {
  static const Radius r = Radius.circular(14);
  static const BorderRadius card = BorderRadius.all(Radius.circular(14));
  static const BorderRadius pill = BorderRadius.all(Radius.circular(999));
  static const BorderRadius chip = BorderRadius.all(Radius.circular(10));
}

/// §6.2 타이포 — 수치·텔레메트리·터미널 = JetBrains Mono, 본문·라벨 = Pretendard(폴백 sans).
abstract class AppType {
  /// 계기판 수치용 모노. Pretendard 폰트 파일이 없으면 sans 는 기본 폴백을 쓴다.
  static TextStyle mono({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = AppColors.textPrimary,
    double? height,
    double? letterSpacing,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: height,
        letterSpacing: letterSpacing,
      );

  /// 대형 계기 수치 (속도/거리 등). 굵기 대비로 계기판 느낌.
  static TextStyle instrument({
    double size = 64,
    Color color = AppColors.textPrimary,
  }) =>
      GoogleFonts.jetBrainsMono(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
        height: 1.0,
        letterSpacing: -1,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}

ThemeData buildNeoCockpitTheme() {
  const scheme = ColorScheme.dark(
    primary: AppColors.accent,
    onPrimary: Colors.white,
    secondary: AppColors.signal,
    onSecondary: AppColors.baseBg,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    error: AppColors.accent,
    outline: AppColors.border,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.baseBg,
    splashFactory: InkSparkle.splashFactory,
  );

  // 본문 라벨은 Pretendard(폴백) — 폰트 파일이 있으면 pubspec 에서 fontFamily 로 지정.
  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
      fontFamily: 'Pretendard',
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.baseBg,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        fontFamily: 'Pretendard',
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    sliderTheme: const SliderThemeData(
      activeTrackColor: AppColors.signal,
      inactiveTrackColor: AppColors.border,
      thumbColor: AppColors.signal,
      overlayColor: Color(0x337CE0C3),
      trackHeight: 4,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.surfaceHigh,
        foregroundColor: AppColors.textPrimary,
        minimumSize: const Size(0, 52), // 48dp+ 터치 영역 (§6.3)
        shape: const RoundedRectangleBorder(borderRadius: Radii.chip),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.textPrimary,
        side: const BorderSide(color: AppColors.border),
        minimumSize: const Size(0, 52),
        shape: const RoundedRectangleBorder(borderRadius: Radii.chip),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.surfaceHigh,
      contentTextStyle: TextStyle(color: AppColors.textPrimary),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
