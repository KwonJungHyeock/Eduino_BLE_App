// Author: eduino
// 홈 — 사용 모드(블루투스 실습 / 교구 학습)에 맞춰 우선순위를 바꿔 보여준다.
// 뒤로가기 2번으로 종료(스낵바 안내). 블루투스 실습·교구 제어·설정 구성.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/bt/bt_transport.dart';
import '../../providers/app_mode_providers.dart';
import '../../providers/bt_providers.dart';
import '../../providers/connection_manager.dart';
import '../../providers/kit_providers.dart';
import '../../providers/module_providers.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/circuit.dart';
import '../../widgets/dialogs.dart';
import '../../widgets/double_back_exit.dart';
import '../../widgets/kit_illustration.dart';
import '../../widgets/pressable.dart';
import '../../widgets/responsive.dart';
import '../kit/kit_profile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(connectionProvider);
    final kit = ref.watch(kitProfileProvider).valueOrNull;
    final module = ref.watch(moduleProvider).valueOrNull;
    final mode = ref.watch(appModeProvider).valueOrNull ?? AppMode.kit;
    final connected = conn.isConnected;

    // 모드별로 완전히 분리 — 현재 모드의 기능만 노출한다.
    final content = <Widget>[];

    if (mode == AppMode.lab) {
      // 통신 실습만(연결·시리얼·AT·LED). RC 주행은 교구 학습 모드로 이동.
      final accent = AppMode.lab.color;
      content.addAll([
        const NodeRailHeader('통신 실습', count: 4),
        _MenuTile(
          icon: Icons.bluetooth_searching,
          title: '블루투스 연결',
          subtitle: connected ? '연결됨 · 눌러서 관리' : '모듈 스캔·연결',
          accent: accent,
          onTap: () => context.push(Routes.connect),
        ),
        Gap.h8,
        _MenuTile(
          icon: Icons.forum_outlined,
          title: '시리얼 통신 채팅',
          subtitle: 'PC 시리얼 모니터와 문자 주고받기',
          accent: accent,
          onTap: () => context.push(Routes.basics),
        ),
        Gap.h8,
        _MenuTile(
          icon: Icons.terminal,
          title: 'AT 커맨드',
          subtitle: '모듈 설정 명령 실습',
          accent: accent,
          onTap: () => context.push(Routes.terminal),
        ),
        Gap.h8,
        _MenuTile(
          icon: Icons.lightbulb_outline,
          title: 'LED 제어',
          subtitle: '핀 선택 후 ON/OFF',
          accent: accent,
          onTap: () => context.push(Routes.led),
        ),
      ]);
    } else {
      // 교구 학습 모드: 진입 즉시 전 키트 이미지 그리드 + 필터 탭(QA 6).
      // 진입 버튼 없음 — 카드(상품 이미지) 자체가 버튼(탭 → 해당 키트 컨트롤러).
      content.add(const NodeRailHeader('내 키트 선택'));
      content.add(Gap.h12);
      content.add(const _KitGrid());
    }

    return DoubleBackToExit(
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const BrandMark(size: 26),
              Gap.w8,
              Text('Eduino',
                  style: AppType.mono(size: 18, weight: FontWeight.w800)),
              Text(' AI',
                  style: AppType.mono(
                      size: 18,
                      weight: FontWeight.w800,
                      color: AppColors.accent)),
              const Spacer(),
              CircuitAccent(
                  color: mode == AppMode.kit
                      ? AppColors.accent
                      : AppColors.signal),
            ],
          ),
        ),
        backgroundColor: AppColors.pageBg,
        body: SafeArea(
          // 태블릿 과폭 방지(QA 6) — 콘텐츠 폭을 캡해 카드/설정 버튼이 과하게 넓어지지 않게.
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: ListView(
            padding: pagePadding(context),
            children: _stagger([
              _StatusCard(conn: conn, kit: kit),
              Gap.h16,
              _ModeBanner(mode: mode),
              const SizedBox(height: 22),
              ...content,
              const SizedBox(height: 22),
              const NodeRailHeader('설정'),
              _MenuTile(
                icon: Icons.settings_bluetooth,
                title: '블루투스 모듈',
                subtitle: module == null
                    ? 'HM-10 / HC-06 선택'
                    : '선택됨: ${module.title}',
                utility: true,
                onTap: () => context.push(Routes.module),
              ),
              Gap.h8,
              _MenuTile(
                icon: Icons.swap_horiz,
                title: '사용 모드 변경',
                subtitle: '현재: ${mode.title}',
                utility: true,
                onTap: () => context.push(Routes.mode),
              ),
              Gap.h8,
              _MenuTile(
                icon: Icons.help_outline,
                title: '도움말 & FAQ',
                subtitle: '연결·조작 문제 해결 · 배선 안내',
                utility: true,
                onTap: () => context.push(Routes.help),
              ),
              Gap.h8,
              _MenuTile(
                icon: Icons.privacy_tip_outlined,
                title: '개인정보처리방침',
                subtitle: '데이터 미수집 · 오프라인 동작',
                utility: true,
                onTap: () => context.push(Routes.privacy),
              ),
            ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 진입 시 위에서부터 순차로 떠오르는 카드 연출(스태거).
  List<Widget> _stagger(List<Widget> items) {
    final out = <Widget>[];
    var step = 0;
    for (final w in items) {
      // 간격(SizedBox)은 지연 대상에서 제외해 리듬을 유지.
      if (w is SizedBox) {
        out.add(w);
        continue;
      }
      out.add(RiseIn(
        delay: Duration(milliseconds: (step * 45).clamp(0, 340)),
        child: w,
      ));
      step++;
    }
    return out;
  }
}

/// 교구 학습 메인(QA 6) — 필터 탭 + 전 키트 이미지 카드 그리드.
///   진입 즉시 카드 노출(진입 버튼 없음), 카드(상품 이미지) 탭 → 해당 키트 컨트롤러.
class _KitGrid extends ConsumerStatefulWidget {
  const _KitGrid();
  @override
  ConsumerState<_KitGrid> createState() => _KitGridState();
}

enum _KitFilter { all, rc, farm, factory, home }

class _KitGridState extends ConsumerState<_KitGrid> {
  _KitFilter _f = _KitFilter.all;

  static const _tabs = <(_KitFilter, String)>[
    (_KitFilter.all, '전체'),
    (_KitFilter.rc, 'RC'),
    (_KitFilter.farm, '스마트팜'),
    (_KitFilter.factory, '스마트팩토리'),
    (_KitFilter.home, '스마트홈'),
  ];

  List<KitType> get _kits => switch (_f) {
        _KitFilter.all => KitProfile.all,
        _KitFilter.rc => KitProfile.rcKits,
        _KitFilter.farm => const [KitType.smartFarm],
        _KitFilter.factory => const [KitType.smartFactory],
        _KitFilter.home => const [KitType.smartHome],
      };

  Future<void> _open(KitType type) async {
    HapticFeedback.selectionClick();
    if (KitProfile.forType(type).isRc) {
      await ref.read(rcProfileProvider.notifier).select(type);
      if (mounted) context.push(Routes.controller);
    } else {
      await ref.read(kitProfileProvider.notifier).select(type);
      if (mounted) context.push(Routes.control);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cols =
        MediaQuery.sizeOf(context).width >= Breakpoints.tablet ? 3 : 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 필터 탭(기본=전체).
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final t in _tabs) ...[
                _filterPill(t.$1, t.$2),
                Gap.w8,
              ],
            ],
          ),
        ),
        Gap.h16,
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: cols,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.82,
          children: [
            for (final k in _kits)
              _KitGridCard(
                  profile: KitProfile.forType(k), onTap: () => _open(k)),
          ],
        ),
      ],
    );
  }

  Widget _filterPill(_KitFilter f, String label) {
    final sel = _f == f;
    return Pressable(
      onTap: () => setState(() => _f = f),
      semanticLabel: '$label 필터',
      child: AnimatedContainer(
        duration: Motion.fast,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: sel ? AppColors.accent : AppColors.chipGray,
          borderRadius: Radii.pill,
        ),
        child: Text(label,
            style: AppType.mono(
                size: 12,
                weight: FontWeight.w700,
                color: sel ? Colors.white : AppColors.listDesc)),
      ),
    );
  }
}

/// 그리드 카드 — 상품 이미지 자체가 버튼. 이미지 없으면 커스텀 일러스트로 폴백.
class _KitGridCard extends StatelessWidget {
  const _KitGridCard({required this.profile, required this.onTap});
  final KitProfile profile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = profile.isRc ? AppColors.accent : AppColors.signal;
    return Pressable(
      onTap: onTap,
      pressedScale: 0.97,
      semanticLabel: '${profile.name} 열기',
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: Radii.cardLg,
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: Shadows.tap,
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                color: AppColors.tintOf(accent),
                alignment: Alignment.center,
                child: Image.asset(
                  profile.assetImage,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (c, e, s) => KitIllustration(
                      art: kitArtFor(profile.type), size: 72, showTile: false),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: AppColors.listTitle)),
                  const SizedBox(height: 3),
                  Text(profile.isRc ? 'RC카' : '스마트 교구',
                      style: AppType.mono(size: 10, color: accent)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 현재 사용 모드 배너(브랜드 톤) — 눌러서 변경.
class _ModeBanner extends StatelessWidget {
  const _ModeBanner({required this.mode});
  final AppMode mode;

  @override
  Widget build(BuildContext context) {
    final accent = mode.color; // 모드 색 토큰 공유(교구=코랄/실습=블루)
    // 상태 표시만 — 모드 변경은 설정에서(중복 제거, 지시서 E).
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: AppColors.tintOf(accent),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(mode.icon, color: accent, size: 18),
          Gap.w8,
          Text('${mode.title} 모드',
              style: AppType.mono(
                  size: 13, weight: FontWeight.w700, color: accent)),
        ],
      ),
    );
  }
}

class _StatusCard extends ConsumerWidget {
  const _StatusCard({required this.conn, required this.kit});
  final BtConnectionState conn;
  final dynamic kit; // KitProfile?

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final device = ref.watch(transportProvider).connectedDevice;
    final module = ref.watch(moduleProvider).valueOrNull;
    final reconnecting = ref.watch(reconnectingProvider);
    final connected = conn.isConnected;
    var (color, label) = switch (conn) {
      BtConnectionState.connected => (AppColors.mint, '연결됨'),
      BtConnectionState.connecting => (AppColors.warn, '연결 중'),
      BtConnectionState.scanning => (AppColors.warn, '스캔 중'),
      BtConnectionState.disconnecting => (AppColors.warn, '해제 중'),
      BtConnectionState.disconnected => (AppColors.chipGrayIcon, '미연결'),
    };
    if (reconnecting && !connected) {
      color = AppColors.warn;
      label = '재연결 중…';
    }

    // 연결=민트 톤, 미연결=회색. 카드는 리스트 행과 동일 토큰(radius 16·보더).
    return InkWell(
      onTap: () => context.push(Routes.connect),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: connected ? AppColors.tintOf(AppColors.mint) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: connected
                  ? AppColors.mint.withValues(alpha: 0.40)
                  : AppColors.cardBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: connected ? AppColors.mint : AppColors.chipGray,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                connected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color: connected ? Colors.white : AppColors.chipGrayIcon,
                size: 22,
              ),
            ),
            Gap.w12,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(label,
                          style: AppType.mono(
                              size: 13,
                              weight: FontWeight.w700,
                              color: color)),
                      Gap.w8,
                      if (device != null)
                        Flexible(
                          child: Text(device.displayName,
                              overflow: TextOverflow.ellipsis,
                              style: AppType.mono(
                                  size: 12, color: AppColors.textMuted)),
                        ),
                    ],
                  ),
                  Gap.h4,
                  Text(
                    '${module == null ? "모듈 미선택" : "모듈: ${module.shortName}"}'
                    ' · ${kit == null ? "교구 미선택" : kit.name}',
                    style: AppType.mono(size: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            if (connected)
              IconButton(
                tooltip: '연결 해제',
                icon: const Icon(Icons.link_off, color: AppColors.textMuted),
                onPressed: () async {
                  final ok = await confirmAction(
                    context,
                    title: '연결 해제',
                    message: '블루투스 연결을 해제할까요?\nRC카/교구가 정지합니다.',
                    confirmLabel: '해제',
                    danger: true,
                  );
                  if (!ok || !context.mounted) return;
                  HapticFeedback.selectionClick();
                  await ref.read(connectionManagerProvider).userDisconnect();
                },
              )
            else
              const Icon(Icons.chevron_right, color: AppColors.chevron),
          ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SignalTrace(
                connected: connected,
                rightLabel: module == null ? '모듈' : module.shortName,
                color: AppColors.mint,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 통일된 리스트 행(지시서 B/C). 기능 행=모드 tint+accent 칩 / 설정 행=회색 칩.
class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = AppColors.signal,
    this.utility = false,
    this.enabled = true,
    this.trailingBadge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accent;
  final bool utility; // 설정/유틸 행 = 회색 칩
  final bool enabled;
  final String? trailingBadge;

  @override
  Widget build(BuildContext context) {
    final chipBg = utility ? AppColors.chipGray : AppColors.tintOf(accent);
    final chipIcon = utility ? AppColors.chipGrayIcon : accent;
    return Pressable(
      onTap: onTap,
      enabled: enabled,
      pressedScale: 0.98, // 리스트 행(B5)
      semanticLabel: '$title. $subtitle',
      highlightColor: accent.withValues(alpha: 0.06), // press 하이라이트(B5)
      borderRadius: Radii.card,
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: Radii.card,
          border: Border.all(color: AppColors.cardBorder),
          boxShadow: enabled ? Shadows.tap : null, // C1: 탭 가능 → 소프트 뎁스
        ),
        child: Row(
          children: [
            // 아이콘 칩 40×40 · r13 · 통일.
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: chipBg,
                borderRadius: Radii.chip,
              ),
              child: Icon(icon, color: chipIcon, size: 22),
            ),
              Gap.w12,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.listTitle)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 12,
                            height: 1.3,
                            color: AppColors.listDesc)),
                  ],
                ),
              ),
              if (trailingBadge != null) ...[
                Gap.w8,
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.chipGray,
                    borderRadius: Radii.chip,
                  ),
                  child: Text(trailingBadge!,
                      style: AppType.mono(size: 10, color: AppColors.listDesc)),
                ),
              ] else
                const Icon(Icons.chevron_right, color: AppColors.chevron),
            ],
          ),
        ),
      );
  }
}

// 다른 화면(컨트롤러 메뉴)에서 재사용할 수 있도록 공개 별칭.
class HomeMenuTile extends StatelessWidget {
  const HomeMenuTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = AppColors.signal,
    this.utility = false,
    this.enabled = true,
    this.trailingBadge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accent;
  final bool utility;
  final bool enabled;
  final String? trailingBadge;

  @override
  Widget build(BuildContext context) {
    return _MenuTile(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: onTap,
      accent: accent,
      utility: utility,
      enabled: enabled,
      trailingBadge: trailingBadge,
    );
  }
}
