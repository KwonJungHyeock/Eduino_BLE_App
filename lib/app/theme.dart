// Author: eduino
// Neo Cockpit 디자인 토큰 (§6.1 컬러 · §6.2 타이포 · §6.3 원칙)
// 다크 계기판/조종석 은유. 네온 글로우는 절제, 색 대비로 표현.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 컬러 팔레트 (라이트 + 블루투스 블루) — 흰 배경, 선택/연결은 신뢰감 있는 블루.
abstract class AppColors {
  static const Color baseBg = Color(0xFFEEF3FA); // 아주 옅은 블루-그레이 배경
  static const Color surface = Color(0xFFFFFFFF); // 카드/표면 = 화이트
  static const Color surfaceHigh = Color(0xFFF3F7FC); // 살짝 눌린 표면
  static const Color border = Color(0xFFDCE4EF);
  static const Color accent = Color(0xFFE53935); // 레드 · 정지/위험
  static const Color signal = Color(0xFF1C7DF3); // 블루투스 블루 · 선택/연결/주요
  static const Color signalDeep = Color(0xFF0A5FD0); // 블루 그라디언트 하단
  static const Color textPrimary = Color(0xFF15202E); // 진한 텍스트
  static const Color textMuted = Color(0xFF6B7684);
  static const Color warn = Color(0xFFF59E0B);

  /// 블루 선택효과에 쓰는 옅은 배경 틴트.
  static const Color signalTint = Color(0xFFE7F1FE);
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
  const scheme = ColorScheme.light(
    primary: AppColors.signal, // 블루투스 블루 = 주요 색
    onPrimary: Colors.white,
    secondary: AppColors.signalDeep,
    onSecondary: Colors.white,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    error: AppColors.accent,
    onError: Colors.white,
    outline: AppColors.border,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.baseBg,
    splashFactory: InkSparkle.splashFactory,
  );

  return base.copyWith(
    textTheme: base.textTheme.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
      fontFamily: 'Pretendard',
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.baseBg,
      foregroundColor: AppColors.textPrimary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: AppColors.textPrimary),
      titleTextStyle: TextStyle(
        color: AppColors.textPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w700,
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
      overlayColor: Color(0x261C7DF3),
      trackHeight: 5,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.signal,
        foregroundColor: Colors.white,
        minimumSize: const Size(0, 54),
        shape: const RoundedRectangleBorder(borderRadius: Radii.chip),
        textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.signal,
        side: const BorderSide(color: AppColors.border),
        minimumSize: const Size(0, 54),
        shape: const RoundedRectangleBorder(borderRadius: Radii.chip),
      ),
    ),
    snackBarTheme: const SnackBarThemeData(
      backgroundColor: AppColors.textPrimary,
      contentTextStyle: TextStyle(color: Colors.white),
      behavior: SnackBarBehavior.floating,
    ),
  );
}
