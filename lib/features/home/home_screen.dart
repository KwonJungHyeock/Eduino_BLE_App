// Author: eduino
// 홈 메뉴 (§5.1 재구성). 인트로 다음 진입점. 연결 상태·선택 키트 카드 + 5개 기능 엔트리.
//   블루투스 연결 / AT 커맨드 / 통신 기초 예제 / 블루투스 컨트롤러 / 에듀이노 교구

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/bt/bt_transport.dart';
import '../../providers/bt_providers.dart';
import '../../providers/kit_providers.dart';
import '../../providers/module_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(connectionProvider);
    final kit = ref.watch(kitProfileProvider).valueOrNull;
    final connected = conn.isConnected;

    return PopScope(
      // 홈(루트)에서 뒤로가기 → 종료 확인. 다른 화면은 정상적으로 pop.
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
            Text('Eduino',
                style: AppType.mono(size: 18, weight: FontWeight.w800)),
            Text(' AI',
                style: AppType.mono(
                    size: 18,
                    weight: FontWeight.w800,
                    color: AppColors.accent)),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [
            _StatusCard(conn: conn, kit: kit),
            Gap.h24,
            // ── 블루투스 실습 (모든 교구 공통) ──
            _Section('블루투스 실습'),
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
              subtitle: '앱 ↔ PC 시리얼 모니터 문자 주고받기',
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
              icon: Icons.code,
              title: '명령 ↔ 코드',
              subtitle: '이 동작 = 이 아두이노 코드 (코딩 교육)',
              onTap: () => context.push(Routes.learn),
            ),
            Gap.h24,
            // ── 교구 제어 (킷 선택 기반) ──
            _Section('교구 제어'),
            _MenuTile(
              icon: Icons.tune,
              title: '교구 제어판',
              subtitle: kit == null ? '먼저 교구를 선택하세요' : '내 교구: ${kit.name}',
              accent: kit == null ? AppColors.textMuted : AppColors.signal,
              onTap: () =>
                  context.push(kit == null ? Routes.kit : Routes.control),
            ),
            Gap.h8,
            _MenuTile(
              icon: Icons.smart_toy_outlined,
              title: '내 교구 선택',
              subtitle: kit == null
                  ? 'RC카 / 스마트 팩토리·홈·팜'
                  : '선택됨: ${kit.name} · 변경',
              onTap: () => context.push(Routes.kit),
            ),
            Gap.h8,
            _MenuTile(
              icon: Icons.emoji_events_outlined,
              title: '미션 · 챌린지',
              subtitle: '랩타임 측정 · 개인 베스트',
              onTap: () => context.push(Routes.missions),
            ),
            Gap.h24,
            // ── 설정 ──
            _Section('설정'),
            _MenuTile(
              icon: Icons.settings_bluetooth,
              title: '블루투스 모듈',
              subtitle: ref.watch(moduleProvider).valueOrNull == null
                  ? 'HM-10 / HC-06 선택'
                  : '선택됨: ${ref.watch(moduleProvider).valueOrNull!.title} · 변경',
              onTap: () => context.push(Routes.module),
            ),
            if (kit == null || kit.isRc) ...[
              Gap.h8,
              _MenuTile(
                icon: Icons.settings_input_component,
                title: '모터 포트 설정',
                subtitle: '바퀴 ↔ 쉴드 포트(M1~M4) 매핑',
                onTap: () => context.push(Routes.motor),
              ),
            ],
          ],
        ),
      ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.sm),
      child: Text(title,
          style: AppType.mono(
              size: 12, color: AppColors.textMuted, letterSpacing: 2)),
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

    return Container(
      padding: const EdgeInsets.all(Gap.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.card,
        border: Border.all(color: connected ? AppColors.signal : AppColors.border),
      ),
      child: Row(
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
              connected ? Icons.bluetooth_connected : Icons.bluetooth_disabled,
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
                            size: 13, weight: FontWeight.w700, color: color)),
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
                  ' · ${kit == null ? "키트 미선택" : kit.name}',
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
            ),
        ],
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
