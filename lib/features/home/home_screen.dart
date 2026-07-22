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
    final rc = ref.watch(rcProfileProvider).valueOrNull;
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
      // 교구 학습 모드: 허브를 카테고리 목록에서 자동 렌더(B2 · 하드코딩 금지).
      // 카테고리가 3+ 로 늘면 여기서 "내 킷 + 둘러보기 탭" 뷰로 확장한다.
      final hubs = <_HubData>[
        _HubData(
          section: '교구 학습',
          title: '교구 학습하기',
          desc: kit == null
              ? '내 교구를 선택하고\n제어와 학습을 시작해요'
              : '현재 교구: ${kit.name}\n눌러서 교구 선택·제어를 이어가요',
          route: Routes.kit,
          thumb: kit != null
              ? KitIllustration(
                  art: kitArtFor(kit.type), size: 60, showTile: false)
              : const Icon(Icons.smart_toy_rounded,
                  color: AppColors.accent, size: 40),
        ),
        _HubData(
          section: 'RC 주행',
          title: 'RC 주행하기',
          desc: rc == null
              ? '내 RC카를 고르고\n주행을 시작해요'
              : '현재 RC: ${rc.name}\n눌러서 RC 선택·주행을 이어가요',
          route: Routes.rcSelect,
          thumb: rc != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(rc.assetImage,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => KitIllustration(
                          art: kitArtFor(rc.type), size: 60, showTile: false)),
                )
              : const Icon(Icons.sports_esports_rounded,
                  color: AppColors.accent, size: 40),
        ),
      ];
      for (var i = 0; i < hubs.length; i++) {
        content.add(NodeRailHeader(hubs[i].section));
        content.add(_HubHeroCard(data: hubs[i]));
        if (i < hubs.length - 1) content.add(const SizedBox(height: 22));
      }
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

/// 홈 허브 카드 데이터(B2) — 카테고리별 진입 CTA. 하드코딩 대신 목록으로 렌더.
class _HubData {
  const _HubData({
    required this.section,
    required this.title,
    required this.desc,
    required this.route,
    required this.thumb,
  });
  final String section; // 섹션 헤더 라벨
  final String title; // 카드 제목
  final String desc; // 카드 설명(현재 선택 반영)
  final String route; // 진입 경로
  final Widget thumb; // 좌측 썸네일(일러스트/사진/아이콘)
}

/// 공통 허브 히어로 카드 — 교구/ RC 두 카테고리가 같은 컴포넌트를 쓴다(B3).
/// 코랄 그라디언트 · 72 흰 타일 썸네일 · 제목/설명 · 화살표.
class _HubHeroCard extends StatelessWidget {
  const _HubHeroCard({required this.data});
  final _HubData data;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: () => context.push(data.route),
      child: Container(
        padding: const EdgeInsets.all(Gap.lg),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.accentSoft, AppColors.accent],
          ),
          borderRadius: Radii.cardLg,
          boxShadow: Shadows.glow(AppColors.accent),
        ),
        child: Row(
          children: [
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: Radii.card,
              ),
              child: data.thumb,
            ),
            Gap.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data.title,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Gap.h4,
                  Text(
                    data.desc,
                    style: TextStyle(
                        fontSize: 13,
                        height: 1.45,
                        color: Colors.white.withValues(alpha: 0.92)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
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
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.cardBorder),
            boxShadow: enabled ? Shadows.tap : null, // C1: 탭 가능 → 미세 그림자
          ),
          child: Row(
            children: [
              // 아이콘 칩 40×40 · r12 · 통일.
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: chipBg,
                  borderRadius: BorderRadius.circular(12),
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
