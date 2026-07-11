// Author: eduino
// 홈 — 사용 모드(블루투스 실습 / 교구 학습)에 맞춰 우선순위를 바꿔 보여준다.
// 뒤로가기 시 종료 확인. 블루투스 실습·교구 제어·설정 구성.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/bt/bt_transport.dart';
import '../../providers/app_mode_providers.dart';
import '../../providers/bt_providers.dart';
import '../../providers/kit_providers.dart';
import '../../providers/module_providers.dart';
import '../../widgets/brand_mark.dart';
import '../../widgets/circuit.dart';
import '../../widgets/kit_illustration.dart';
import '../../widgets/pressable.dart';
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
          accent: connected ? AppColors.signal : AppColors.textPrimary,
          onTap: () => context.push(Routes.connect),
        ),
        Gap.h8,
        _MenuTile(
          icon: Icons.forum_outlined,
          title: '시리얼 통신 채팅',
          subtitle: '앱 ↔ PC 시리얼 모니터로 문자 주고받기',
          onTap: () => context.push(Routes.basics),
        ),
        Gap.h8,
        _MenuTile(
          icon: Icons.terminal,
          title: 'AT 커맨드',
          subtitle: '모듈 설정 명령 실습',
          onTap: () => context.push(Routes.terminal),
        ),
        Gap.h8,
        _MenuTile(
          icon: Icons.lightbulb_outline,
          title: 'LED 제어',
          subtitle: '보드 13번 핀 켜고 끄기',
          accent: AppColors.signal,
          onTap: () => context.push(Routes.led),
        ),
      ]);
    } else {
      // 교구 학습 모드: '교구 학습하기' 단일 진입 → 교구 선택 → 제어/학습.
      content.addAll([
        const NodeRailHeader('교구 학습', color: AppColors.accent),
        _KitHeroButton(kit: kit),
      ]);
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final exit = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('앱 종료'),
            content: const Text('앱을 종료하시겠습니까?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('취소')),
              FilledButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('종료')),
            ],
          ),
        );
        if (exit == true) SystemNavigator.pop();
      },
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
            padding: const EdgeInsets.all(Gap.md),
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
                onTap: () => context.push(Routes.module),
              ),
              // 모터 포트 설정은 교구 학습 모드(RC카)에서만 노출.
              if (mode == AppMode.kit && (kit == null || kit.isRc)) ...[
                Gap.h8,
                _MenuTile(
                  icon: Icons.settings_input_component,
                  title: '모터 포트 설정',
                  subtitle: '바퀴 ↔ 쉴드 포트(M1~M4)',
                  onTap: () => context.push(Routes.motor),
                ),
              ],
              Gap.h8,
              _MenuTile(
                icon: Icons.swap_horiz,
                title: '사용 모드 변경',
                subtitle: '현재: ${mode.title}',
                onTap: () => context.push(Routes.mode),
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
    final accent = mode == AppMode.kit ? AppColors.accent : AppColors.signal;
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
    final connected = conn.isConnected;
    final (color, label) = switch (conn) {
      BtConnectionState.connected => (AppColors.signal, '연결됨'),
      BtConnectionState.connecting => (AppColors.warn, '연결 중'),
      BtConnectionState.scanning => (AppColors.warn, '스캔 중'),
      BtConnectionState.disconnecting => (AppColors.warn, '해제 중'),
      BtConnectionState.disconnected => (AppColors.textMuted, '미연결'),
    };

    return InkWell(
      onTap: () => context.push(Routes.connect),
      borderRadius: Radii.card,
      child: Container(
        padding: const EdgeInsets.all(Gap.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: Radii.card,
          border: Border.all(
              color: connected ? AppColors.signal : AppColors.border),
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
                color: AppColors.baseBg,
                borderRadius: Radii.chip,
                border: Border.all(color: AppColors.border),
              ),
              child: Icon(
                connected
                    ? Icons.bluetooth_connected
                    : Icons.bluetooth_disabled,
                color: color,
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
                  HapticFeedback.selectionClick();
                  await ref.read(transportProvider).disconnect();
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
    this.accent = AppColors.textPrimary,
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
        borderRadius: Radii.card,
        child: Container(
          padding: const EdgeInsets.symmetric(
              horizontal: Gap.md, vertical: Gap.md - 2),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: Radii.card,
            border: Border.all(color: AppColors.border),
            boxShadow: Shadows.soft,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.baseBg,
                  borderRadius: Radii.chip,
                  border: Border.all(color: AppColors.border),
                ),
                child: Icon(icon, color: accent, size: 20),
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
                            size: 12, color: AppColors.textMuted)),
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
                const Icon(Icons.chevron_right, color: AppColors.textMuted),
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
    this.accent = AppColors.textPrimary,
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
