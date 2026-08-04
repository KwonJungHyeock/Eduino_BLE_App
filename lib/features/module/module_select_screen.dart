// Author: eduino
// 통신 모듈 선택 — 시작 시 HM-10(BLE) / HC-06(Classic SPP) 중 사용하는 모듈을 고른다.
// 선택에 따라 스캔 방식과 AT 예제 등이 맞춰진다.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../app/theme.dart';
import '../../core/bt/bt_transport.dart';
import '../../providers/module_providers.dart';

class ModuleSelectScreen extends ConsumerWidget {
  const ModuleSelectScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(moduleProvider).valueOrNull;
    final canPop = current != null && context.canPop();
    // HC-06(클래식 SPP)은 안드로이드 전용. 웹/iOS 에서는 비활성.
    final isAndroid =
        !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

    return Scaffold(
      appBar: AppBar(
        title: const Text('블루투스 모듈 선택'),
        leading: canPop
            ? IconButton(
                tooltip: '뒤로',
                icon: const Icon(Icons.arrow_back),
                onPressed: () => context.pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [
            Text(
              '키트에 연결된 블루투스 모듈을 선택하세요. 모듈에 따라 연결 방식이 달라집니다.',
              style:
                  AppType.mono(size: 13, color: AppColors.textMuted, height: 1.5),
            ),
            const SizedBox(height: Gap.lg),
            _ModuleCard(
              module: BtModule.ble,
              icon: Icons.bluetooth_audio,
              title: 'HM-10',
              badge: 'BLE',
              desc: '저전력 블루투스(BLE). iOS·안드로이드 모두 지원. 파란 기판의 4핀 모듈.',
              selected: current == BtModule.ble,
              enabled: true,
              onTap: () => _pick(context, ref, BtModule.ble),
            ),
            // HC-06(Classic SPP)은 안드로이드 전용 — iOS/웹에서는 카드 자체를 숨긴다
            // (배포 체크리스트: iOS에서 HC-06 옵션 노출 금지).
            if (isAndroid) ...[
              Gap.h16,
              _ModuleCard(
                module: BtModule.spp,
                icon: Icons.settings_bluetooth,
                title: 'HC-06',
                badge: 'Classic SPP',
                desc: '클래식 블루투스(SPP). 안드로이드 전용. RX/TX 를 아두이노에 연결하는 시리얼 모듈.',
                selected: current == BtModule.spp,
                enabled: true,
                onTap: () => _pick(context, ref, BtModule.spp),
              ),
            ],
            Gap.h24,
            Container(
              padding: const EdgeInsets.all(Gap.md),
              decoration: BoxDecoration(
                color: AppColors.signalTint,
                borderRadius: Radii.card,
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.signal),
                  Gap.w16,
                  Expanded(
                    child: Text(
                      isAndroid
                          ? '잘 모르겠다면: 파란 4핀 모듈이면 HM-10, RX/TX 로 아두이노에 직접 연결했다면 HC-06 인 경우가 많아요. 나중에 홈에서 바꿀 수 있습니다.'
                          : 'iOS에서는 HM-10(BLE)만 지원해요. 파란 4핀 BLE 모듈을 사용하세요.',
                      style: AppType.mono(
                          size: 11, color: AppColors.textMuted, height: 1.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pick(BuildContext context, WidgetRef ref, BtModule m) async {
    HapticFeedback.selectionClick();
    await ref.read(moduleProvider.notifier).select(m);
    if (!context.mounted) return;
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(Routes.home);
    }
  }
}

class _ModuleCard extends StatelessWidget {
  const _ModuleCard({
    required this.module,
    required this.icon,
    required this.title,
    required this.badge,
    required this.desc,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final BtModule module;
  final IconData icon;
  final String title;
  final String badge;
  final String desc;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: Radii.card,
        child: Container(
          padding: const EdgeInsets.all(Gap.md),
          decoration: BoxDecoration(
            color: selected ? AppColors.signalTint : AppColors.surface,
            borderRadius: Radii.card,
            border: Border.all(
              color: selected ? AppColors.signal : AppColors.border,
              width: selected ? 2 : 1,
            ),
            boxShadow: selected ? Shadows.lift : Shadows.tap, // 소프트 뎁스 토큰
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: selected ? AppColors.signal : AppColors.surfaceHigh,
                  borderRadius: Radii.chip,
                ),
                child: Icon(icon,
                    color: selected ? Colors.white : AppColors.signal,
                    size: 26),
              ),
              Gap.w16,
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(title,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w800)),
                        Gap.w8,
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.signal,
                            borderRadius: Radii.chip,
                          ),
                          child: Text(badge,
                              style: AppType.mono(
                                  size: 10,
                                  weight: FontWeight.w700,
                                  color: Colors.white)),
                        ),
                      ],
                    ),
                    Gap.h4,
                    Text(desc,
                        style: AppType.mono(
                            size: 11,
                            color: AppColors.textMuted,
                            height: 1.5)),
                  ],
                ),
              ),
              if (selected)
                const Padding(
                  padding: EdgeInsets.only(left: Gap.sm),
                  child: Icon(Icons.check_circle, color: AppColors.signal),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
