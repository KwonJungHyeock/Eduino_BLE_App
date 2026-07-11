// Author: eduino
// Neo Cockpit 디자인 토큰 (§6.1 컬러 · §6.2 타이포 · §6.3 원칙)
// 다크 계기판/조종석 은유. 네온 글로우는 절제, 색 대비로 표현.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// 컬러 팔레트 (라이트 + 블루투스 블루) — 흰 배경, 선택/연결은 신뢰감 있는 블루.
/// 톤: 밝고 친근한 교육형. 코랄 브랜드 + 하늘 블루, 부드러운 그림자와 틴트로 온기.
abstract class AppColors {
  static const Color baseBg = Color(0xFFF3F7FC); // 아주 옅은 블루-그레이 배경(더 밝게)
  static const Color surface = Color(0xFFFFFFFF); // 카드/표면 = 화이트
  static const Color surfaceHigh = Color(0xFFF3F7FC); // 살짝 눌린 표면
  static const Color border = Color(0xFFE2E9F2); // 더 부드러운 보더
  static const Color accent = Color(0xFFEE4C57); // EDUINO 브랜드 코랄레드(로고) · 강조/정지
  static const Color accentSoft = Color(0xFFFF7A82); // 코랄 밝은 톤(그라디언트/일러스트)
  static const Color signal = Color(0xFF1C7DF3); // 블루투스 블루 · 선택/연결/주요
  static const Color signalDeep = Color(0xFF0A5FD0); // 블루 그라디언트 하단
  static const Color signalSoft = Color(0xFF63A4F7); // 블루 밝은 톤
  static const Color mint = Color(0xFF19C3A6); // 보조 포인트(센서 OK/성공)
  static const Color sun = Color(0xFFFFC24B); // 따뜻한 노랑(교육형 포인트)
  static const Color textPrimary = Color(0xFF15202E); // 진한 텍스트
  static const Color textMuted = Color(0xFF6B7684);
  static const Color warn = Color(0xFFF59E0B);

  /// 블루 선택효과에 쓰는 옅은 배경 틴트.
  static const Color signalTint = Color(0xFFE7F1FE);

  /// 코랄 선택효과에 쓰는 옅은 배경 틴트.
  static const Color accentTint = Color(0xFFFDECEE);
}

/// 부드러운 그림자 토큰 — 밝고 친근한 톤의 깊이감(짙은 검정 대신 블루-그레이 확산).
abstract class Shadows {
  /// 카드 기본 그림자(살짝 떠 있는 느낌).
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0F1B3A6B), blurRadius: 16, offset: Offset(0, 6)),
  ];

  /// 눌림/강조된 카드(더 크게 떠오름).
  static const List<BoxShadow> lift = [
    BoxShadow(color: Color(0x1A1B3A6B), blurRadius: 24, offset: Offset(0, 10)),
  ];

  /// 컬러 액센트 아래 은은한 컬러 글로우(코랄/블루 카드용).
  static List<BoxShadow> glow(Color c) => [
        BoxShadow(
            color: c.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10)),
      ];
}

/// 모션 토큰 — 절제된, 부드러운 이징(§6.4 절제된 모션).
abstract class Motion {
  static const Duration fast = Duration(milliseconds: 160);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 480);
  static const Duration intro = Duration(milliseconds: 1100);
  static const Curve emphasized = Curves.easeOutCubic;
  static const Curve gentle = Curves.easeInOut;
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
  static const SizedBox h12 = SizedBox(height: 12);
  static const SizedBox h16 = SizedBox(height: md);
  static const SizedBox h24 = SizedBox(height: lg);
  static const SizedBox w8 = SizedBox(width: sm);
  static const SizedBox w12 = SizedBox(width: 12);
  static const SizedBox w16 = SizedBox(width: md);
  static const SizedBox w24 = SizedBox(width: lg);
}

/// 반경 토큰
abstract class Radii {
  static const Radius r = Radius.circular(14);
  static const BorderRadius card = BorderRadius.all(Radius.circular(14));
  static const BorderRadius cardLg =
      BorderRadius.all(Radius.circular(22)); // 히어로 카드(친근한 라운드)
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
