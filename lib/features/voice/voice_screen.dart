// Author: eduino
// 음성 제어 — speech_to_text ko-KR. 키워드 → 단일 문자 명령(g/b/l/r/s).
// "정지" 최우선. RC 펌웨어에 LED 없어 "불 켜/꺼" 제거.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../app/theme.dart';
import '../../core/protocol/commands.dart';
import '../../providers/bt_providers.dart';
import '../../providers/car_controller.dart';
import '../../widgets/surface_card.dart';
import '../../widgets/orientation_fill.dart';

class VoiceScreen extends ConsumerStatefulWidget {
  const VoiceScreen({super.key});

  @override
  ConsumerState<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends ConsumerState<VoiceScreen> {
  final SpeechToText _stt = SpeechToText();
  bool _available = false;
  bool _listening = false;
  String _heard = '';
  String _mapped = '';
  bool _sent = false; // 이번 듣기 세션에서 명령을 이미 보냈는지(중복 전송 방지)

  // 키워드 → 단일 문자 명령. "정지"를 맨 앞에 둬 최우선 매칭(안전).
  static final List<(List<String>, DriveCmd)> _rules = [
    (['정지', '멈춰', '멈춤', '스톱', '스탑', '그만', '서'], DriveCmd.stop),
    (['전진', '앞으로', '고', '출발', '직진'], DriveCmd.forward),
    (['후진', '뒤로', '백'], DriveCmd.back),
    (['왼쪽', '왼', '좌'], DriveCmd.left),
    (['오른쪽', '오른', '우'], DriveCmd.right),
  ];

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final ok = await _stt.initialize(
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted) setState(() => _listening = false);
        }
      },
      onError: (_) {
        if (mounted) setState(() => _listening = false);
      },
    );
    if (mounted) setState(() => _available = ok);
  }

  Future<void> _listen() async {
    if (!_available) {
      await _init();
      if (!_available) return;
    }
    HapticFeedback.selectionClick();
    setState(() {
      _listening = true;
      _heard = '';
      _mapped = '';
      _sent = false;
    });
    await _stt.listen(
      localeId: 'ko_KR',
      // 지연 원인 제거: 기존엔 r.finalResult(발화 종료 후 침묵 감지)까지 기다려 전송했다.
      // 명령 어휘가 짧으므로 부분결과에서 키워드가 잡히는 즉시 1회 전송하고 멈춘다.
      onResult: (r) {
        if (r.recognizedWords != _heard) {
          setState(() => _heard = r.recognizedWords);
        }
        if (_sent) return;
        final cmd = _match(r.recognizedWords);
        if (cmd != null) {
          _sent = true;
          _send(cmd);
          _stt.stop();
        } else if (r.finalResult) {
          setState(() => _mapped = '매칭 없음');
        }
      },
    );
  }

  Future<void> _stopListening() async {
    await _stt.stop();
    if (mounted) setState(() => _listening = false);
  }

  // 인식 문자열 → 명령 매칭(부분결과에도 사용). 매칭 없으면 null.
  DriveCmd? _match(String text) {
    final t = text.replaceAll(' ', '');
    for (final rule in _rules) {
      if (rule.$1.any((k) => t.contains(k.replaceAll(' ', '')))) return rule.$2;
    }
    return null;
  }

  // 매칭된 명령 전송(통신 규약 불변 — 기존과 동일한 CarController 경유).
  void _send(DriveCmd cmd) {
    final car = ref.read(carControllerProvider);
    setState(() => _mapped = '${cmd.label} (${cmd.code})');
    if (cmd == DriveCmd.stop) {
      car.driveStop();
    } else {
      car.driveCmd(cmd);
    }
  }

  @override
  Widget build(BuildContext context) {
    final connected = ref.watch(connectionProvider).isConnected;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(Gap.md),
        child: OrientationFillColumn(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('인식된 말',
                      style:
                          AppType.mono(size: 12, color: AppColors.textMuted)),
                  Gap.h8,
                  Text(_heard.isEmpty ? '—' : _heard,
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  if (_mapped.isNotEmpty) ...[
                    Gap.h8,
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.tintOf(AppColors.accent),
                        borderRadius: Radii.pill,
                      ),
                      child: Text('→ 전송 $_mapped',
                          style: AppType.mono(
                              size: 13,
                              weight: FontWeight.w700,
                              color: AppColors.accent)),
                    ),
                  ],
                ],
              ),
            ),
            Gap.h16,
            Text('사용할 수 있는 말',
                style: AppType.mono(
                    size: 12, color: AppColors.textMuted, letterSpacing: 2)),
            Gap.h8,
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in _rules)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: Radii.pill,
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Text('${r.$1.first} → ${r.$2.code}',
                        style: AppType.mono(
                            size: 12,
                            weight: FontWeight.w600,
                            color: AppColors.listTitle)),
                  ),
              ],
            ),
            if (!_available) ...[
              Gap.h16,
              Container(
                padding: const EdgeInsets.all(Gap.md),
                decoration: BoxDecoration(
                  color: AppColors.warn.withValues(alpha: 0.10),
                  borderRadius: Radii.card,
                  border:
                      Border.all(color: AppColors.warn.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.mic_off_outlined, color: AppColors.warn),
                    Gap.w12,
                    Expanded(
                      child: Text(
                        '이 기기에서 음성 인식을 사용할 수 없어요. 마이크 권한과 한국어(음성) 지원을 확인해 주세요.',
                        style: AppType.mono(
                            size: 12,
                            color: AppColors.textPrimary,
                            height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const Spacer(),
            Center(
              child: Semantics(
                button: true,
                enabled: connected,
                label: _listening ? '음성 듣기 중지' : '음성 명령 듣기',
                child: GestureDetector(
                  onTap: connected
                      ? (_listening ? _stopListening : _listen)
                      : null,
                  child: Container(
                    width: 108,
                    height: 108,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _listening
                          ? AppColors.warn
                          : AppColors.accent,
                      boxShadow: [
                        BoxShadow(
                          color: (_listening
                                  ? AppColors.warn
                                  : AppColors.accent)
                              .withValues(alpha: 0.4),
                          blurRadius: 20,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Icon(_listening ? Icons.stop : Icons.mic,
                        color: Colors.white, size: 44),
                  ),
                ),
              ),
            ),
            Gap.h16,
            Text(
              connected
                  ? (_listening ? '듣는 중… 말해보세요' : '버튼을 누르고 명령을 말하세요')
                  : '연결 후 사용할 수 있어요',
              textAlign: TextAlign.center,
              style: AppType.mono(size: 12, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
