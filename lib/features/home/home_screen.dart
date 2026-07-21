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
      // 블루투스 실습 모드: 연결·통신·AT·코드 + LED 제어까지만.
      content.addAll([
        const NodeRailHeader('블루투스 실습', color: AppColors.signal),
        _MenuTile(
          icon: Icons.bluetooth_searching,
          title: '블루투스 연결',
          subtitle: connected ? '연결됨 · 눌러서 관리' : '모듈 스캔·연결',
          accent: AppColors.signal,
          onTap: () => context.push(Routes.connect),
        ),
        Gap.h8,
        _MenuTile(
          icon: Icons.forum_outlined,
          title: '시리얼 통신 채팅',
          subtitle: '앱 ↔ PC 시리얼 모니터로 문자 주고받기',
          accent: AppColors.mint,
          onTap: () => context.push(Routes.basics),
        ),
        Gap.h8,
        _MenuTile(
          icon: Icons.terminal,
          title: 'AT 커맨드',
          subtitle: '모듈 설정 명령 실습',
          accent: AppColors.signalDeep,
          onTap: () => context.push(Routes.terminal),
        ),
        Gap.h8,
        _MenuTile(
          icon: Icons.lightbulb_outline,
          title: 'LED 제어',
          subtitle: '핀 선택 후 ON/OFF (기본 D13)',
          accent: AppColors.sun,
          onTap: () => context.push(Routes.led),
        ),
        Gap.h24,
        const NodeRailHeader('RC카 컨트롤', color: AppColors.signal),
        _MenuTile(
          icon: Icons.sports_esports,
          title: 'RC 주행 컨트롤러',
          subtitle: '조이스틱·방향·기울기·음성 · 2·4휠 (설정에서 휠·핀)',
          accent: AppColors.signal,
          onTap: () => context.push(Routes.controller),
        ),
        Gap.h8,
        _MenuTile(
          icon: Icons.sensors,
          title: '자율주행 (초음파)',
          subtitle: '초음파 1개로 장애물 회피 · 실시간 튜닝',
          accent: AppColors.signalDeep,
          onTap: () => context.push(Routes.auto),
        ),
        Gap.h8,
        _MenuTile(
          icon: Icons.route,
          title: '라인트레이싱',
          subtitle: '라인센서로 선 따라 주행 (2휠 2개·4휠 3개)',
          accent: AppColors.mint,
          onTap: () => context.push(Routes.line),
        ),
      ]);
    } else {
      // 교구 학습 모드: '교구 학습하기' 단일 진입 → 교구 선택 → 제어/학습.
      content.addAll([
        const NodeRailHeader('교구 학습', color: AppColors.accent),
        _KitHeroButton(kit: kit),
      ]);
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
        body: BreadboardBackground(
          child: SafeArea(
          child: ListView(
            padding: pagePadding(context),
            children: _stagger([
              _StatusCard(conn: conn, kit: kit),
              Gap.h16,
              _ModeBanner(mode: mode),
              Gap.h24,
              ...content,
              Gap.h24,
              const NodeRailHeader('설정'),
              _MenuTile(
                icon: Icons.settings_bluetooth,
                title: '블루투스 모듈',
                subtitle: module == null
                    ? 'HM-10 / HC-06 선택'
                    : '선택됨: ${module.title} · 변경',
                accent: AppColors.signalDeep,
                onTap: () => context.push(Routes.module),
              ),
              Gap.h8,
              _MenuTile(
                icon: Icons.swap_horiz,
                title: '사용 모드 변경',
                subtitle: '현재: ${mode.title}',
                accent: AppColors.accent,
                onTap: () => context.push(Routes.mode),
              ),
              Gap.h8,
              _MenuTile(
                icon: Icons.help_outline,
                title: '도움말 & FAQ',
                subtitle: '연결·조작 문제 해결 · 배선 안내',
                accent: AppColors.mint,
                onTap: () => context.push(Routes.help),
              ),
              Gap.h8,
              _MenuTile(
                icon: Icons.privacy_tip_outlined,
                title: '개인정보처리방침',
                subtitle: '데이터 미수집 · 오프라인 동작',
                accent: AppColors.mint,
                onTap: () => context.push(Routes.privacy),
              ),
            ]),
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

/// 교구 학습 모드의 단일 진입 CTA — 누르면 교구 선택 → 제어/학습.
class _KitHeroButton extends StatelessWidget {
  const _KitHeroButton({required this.kit});
  final KitProfile? kit;

  @override
  Widget build(BuildContext context) {
    final hasKit = kit != null;
    return Pressable(
      onTap: () => context.push(Routes.kit),
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
              child: hasKit
                  ? KitIllustration(
                      art: kitArtFor(kit!.type), size: 60, showTile: false)
                  : const Icon(Icons.smart_toy_rounded,
                      color: AppColors.accent, size: 40),
            ),
            Gap.w16,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('교구 학습하기',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Gap.h4,
                  Text(
                    hasKit
                        ? '현재 교구: ${kit!.name}\n눌러서 교구 선택·제어를 이어가요'
                        : '내 교구를 선택하고\n제어와 학습을 시작해요',
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
    return InkWell(
      onTap: () => context.push(Routes.mode),
      borderRadius: Radii.card,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: Gap.md, vertical: 12),
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.10),
          borderRadius: Radii.card,
          border: Border.all(color: accent.withValues(alpha: 0.4)),
        ),
        child: Row(
          children: [
            Icon(mode.icon, color: accent, size: 20),
            Gap.w8,
            Text('${mode.title} 모드',
                style: AppType.mono(
                    size: 13, weight: FontWeight.w700, color: accent)),
            const Spacer(),
            Text('변경',
                style: AppType.mono(size: 12, color: AppColors.textMuted)),
            const Icon(Icons.chevron_right,
                size: 18, color: AppColors.textMuted),
          ],
        ),
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
      BtConnectionState.connected => (AppColors.signal, '연결됨'),
      BtConnectionState.connecting => (AppColors.warn, '연결 중'),
      BtConnectionState.scanning => (AppColors.warn, '스캔 중'),
      BtConnectionState.disconnecting => (AppColors.warn, '해제 중'),
      BtConnectionState.disconnected => (AppColors.textMuted, '미연결'),
    };
    if (reconnecting && !connected) {
      color = AppColors.warn;
      label = '재연결 중…';
    }

    // 상태색을 카드 배경에도 은은히 반영(연결=파랑, 대기/재연결=노랑 톤).
    final tintBase = connected
        ? AppColors.signal
        : (color == AppColors.warn ? AppColors.warn : AppColors.signal);
    final cardTint = Color.alphaBlend(
      tintBase.withValues(alpha: connected ? 0.08 : 0.05),
      AppColors.surface,
    );
    return InkWell(
      onTap: () => context.push(Routes.connect),
      borderRadius: Radii.card,
      child: Container(
        padding: const EdgeInsets.all(Gap.md),
        decoration: BoxDecoration(
          color: cardTint,
          borderRadius: Radii.card,
          border: Border.all(
              color: connected
                  ? AppColors.signal
                  : tintBase.withValues(alpha: 0.16)),
          boxShadow: connected ? Shadows.glow(AppColors.signal) : Shadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: connected
                    ? AppColors.signal
                    : tintBase.withValues(alpha: 0.14),
                borderRadius: Radii.chip,
                boxShadow: connected
                    ? [
                        BoxShadow(
                          color: AppColors.signal.withValues(alpha: 0.30),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: Icon(
                connected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color: connected ? Colors.white : color,
                size: 22,
              ),
            ),
            Gap.w16,
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
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: SignalTrace(
                connected: connected,
                rightLabel: module == null ? '모듈' : module.shortName,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.accent = AppColors.signal,
    this.enabled = true,
    this.trailingBadge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accent;
  final bool enabled;
  final String? trailingBadge;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: Radii.cardLg,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            // 카드에 아주 옅은 컬러 틴트(화이트 일변도 완화).
            color: Color.alphaBlend(
                accent.withValues(alpha: 0.07), AppColors.surface),
            borderRadius: Radii.cardLg,
            boxShadow: Shadows.soft,
          ),
          child: Row(
            children: [
              // 솔리드 컬러 아이콘 칩 — 생기 있게, 기능마다 다른 색.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                        color: accent.withValues(alpha: 0.30),
                        blurRadius: 10,
                        offset: const Offset(0, 4)),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              Gap.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700)),
                    Gap.h4,
                    Text(subtitle,
                        style: AppType.mono(
                            size: 12,
                            color: AppColors.textMuted,
                            height: 1.3)),
                  ],
                ),
              ),
              if (trailingBadge != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.baseBg,
                    borderRadius: Radii.chip,
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(trailingBadge!,
                      style: AppType.mono(
                          size: 10, color: AppColors.textMuted)),
                )
              else
                Icon(Icons.chevron_right,
                    color: AppColors.textMuted.withValues(alpha: 0.5)),
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
    this.enabled = true,
    this.trailingBadge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color accent;
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
      enabled: enabled,
      trailingBadge: trailingBadge,
    );
  }
}
