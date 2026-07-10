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

    return Scaffold(
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
            Text('시작하기',
                style: AppType.mono(
                    size: 12, color: AppColors.textMuted, letterSpacing: 2)),
            Gap.h8,
            _MenuTile(
              icon: Icons.bluetooth_searching,
              title: '블루투스 연결',
              subtitle: connected ? '연결됨 · 눌러서 관리' : 'HM-10 모듈 스캔·연결',
              accent: connected ? AppColors.signal : AppColors.textPrimary,
              onTap: () => context.push(Routes.connect),
            ),
            Gap.h8,
            _MenuTile(
              icon: Icons.terminal,
              title: 'AT 커맨드',
              subtitle: '모듈 설정 명령 실습 (AT / AT+NAME? …)',
              onTap: () => context.push(Routes.terminal),
            ),
            Gap.h8,
            _MenuTile(
              icon: Icons.forum_outlined,
              title: '시리얼 통신 채팅',
              subtitle: '앱 ↔ PC 시리얼 모니터 문자 주고받기 실습',
              onTap: () => context.push(Routes.basics),
            ),
            Gap.h8,
            _MenuTile(
              icon: Icons.sports_esports_outlined,
              title: '블루투스 컨트롤러',
              subtitle: '조이스틱 · 방향 · 기울기 · 음성 · LED',
              onTap: () => context.push(Routes.controller),
            ),
            Gap.h8,
            _MenuTile(
              icon: Icons.emoji_events_outlined,
              title: '미션 · 챌린지',
              subtitle: '랩타임 측정 · 개인 베스트 기록',
              onTap: () => context.push(Routes.missions),
            ),
            Gap.h8,
            _MenuTile(
              icon: Icons.code,
              title: '명령 ↔ 코드',
              subtitle: '이 동작 = 이 아두이노 코드 (코딩 교육)',
              onTap: () => context.push(Routes.learn),
            ),
            Gap.h24,
            Text('내 장비',
                style: AppType.mono(
                    size: 12, color: AppColors.textMuted, letterSpacing: 2)),
            Gap.h8,
            _MenuTile(
              icon: Icons.settings_bluetooth,
              title: '블루투스 모듈',
              subtitle: ref.watch(moduleProvider).valueOrNull == null
                  ? 'HM-10 / HC-06 선택'
                  : '선택됨: ${ref.watch(moduleProvider).valueOrNull!.title} · 변경',
              accent: AppColors.signal,
              onTap: () => context.push(Routes.module),
            ),
            Gap.h8,
            _MenuTile(
              icon: Icons.smart_toy_outlined,
              title: '에듀이노 교구',
              subtitle: kit == null
                  ? '내 키트 선택 (2휠 · 4휠 · 메탈)'
                  : '선택됨: ${kit.name} · 변경하기',
              accent: kit == null ? AppColors.textPrimary : AppColors.signal,
              onTap: () => context.push(Routes.kit),
            ),
            Gap.h8,
            _MenuTile(
              icon: Icons.settings_input_component,
              title: '모터 포트 설정',
              subtitle: '바퀴 ↔ 쉴드 포트(M1~M4) 매핑',
              onTap: () => context.push(Routes.motor),
            ),
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
