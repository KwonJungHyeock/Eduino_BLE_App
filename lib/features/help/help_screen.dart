// Author: eduino
// 도움말 & FAQ — 초보자(학생·교사)가 막혔을 때 스스로 해결하도록. 배선/펌웨어 안내 포함.

import 'package:flutter/material.dart';

import '../../app/theme.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const List<(String, String)> _faqs = [
    (
      '블루투스가 연결되지 않아요',
      '① 휴대폰 블루투스가 켜져 있는지 확인하세요.\n'
          '② 앱 권한(블루투스·근처 기기)을 허용했는지 확인하세요.\n'
          '③ RC카/교구의 전원이 켜져 있고 가까이(1~2m) 있는지 확인하세요.\n'
          '④ "다시 스캔"을 눌러 목록을 새로고침하세요.',
    ),
    (
      '연결은 됐는데 조작이 안 돼요',
      '① RC카 설정에서 휠·모터 포트(M1~M4)가 실제 배선과 같은지 확인하세요.\n'
          '② 아두이노에 통합 펌웨어(eduino_all_in_one.ino)가 올라가 있어야 합니다.\n'
          '③ 속도 상한이 너무 낮지 않은지 확인하세요.',
    ),
    (
      '아이폰에서 HC-06이 안 보여요',
      'iOS는 HC-06 같은 Classic 블루투스(SPP)를 지원하지 않습니다.\n'
          '아이폰에서는 HM-10(BLE) 모듈을 사용하세요. HC-06은 안드로이드에서만 동작합니다.',
    ),
    (
      '라인트레이싱이 동작하지 않아요',
      '① RC카 설정에서 "IR 라인센서"가 켜져 있는지 확인하세요.\n'
          '② 라인트레이싱 화면에서 "시작"을 눌렀는지 확인하세요.\n'
          '③ 라인 민감도 슬라이더로 검은 선 판정 임계를 조정하세요.',
    ),
    (
      '자율주행(초음파)이 이상해요',
      '① 초음파 센서(TRIG/ECHO) 배선을 확인하세요.\n'
          '② 장애물 임계거리를 상황에 맞게 조정하세요.\n'
          '③ 거리 값이 화면에 표시되는지(텔레메트리) 확인하세요.',
    ),
    (
      '펌웨어(아두이노 코드)는 어디에 있나요',
      '저장소의 docs/firmware 폴더에 통합 펌웨어와 예제가 있습니다.\n'
          '앱의 포트/핀 설정과 스케치의 값을 똑같이 맞춰야 정상 동작합니다.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('도움말 & FAQ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [
            Text('자주 묻는 질문을 눌러 펼쳐보세요.',
                style:
                    AppType.mono(size: 13, color: AppColors.textMuted, height: 1.5)),
            Gap.h16,
            for (final (q, a) in _faqs) ...[
              _FaqTile(question: q, answer: a),
              Gap.h8,
            ],
            Gap.h16,
            Container(
              padding: const EdgeInsets.all(Gap.md),
              decoration: BoxDecoration(
                color: AppColors.signalTint,
                borderRadius: Radii.card,
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.school_outlined, color: AppColors.signalDeep),
                  Gap.w12,
                  Expanded(
                    child: Text(
                      '수업에서 막히는 부분이 있으면 배선도와 펌웨어 예제를 먼저 확인하세요. 앱 설정과 코드의 핀을 맞추는 것이 핵심입니다.',
                      style: AppType.mono(
                          size: 12, color: AppColors.signalDeep, height: 1.5),
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
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: Radii.card,
        border: Border.all(color: AppColors.border),
        boxShadow: Shadows.soft,
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          shape: const RoundedRectangleBorder(borderRadius: Radii.card),
          collapsedShape:
              const RoundedRectangleBorder(borderRadius: Radii.card),
          iconColor: AppColors.signal,
          collapsedIconColor: AppColors.textMuted,
          title: Text(question,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          childrenPadding: const EdgeInsets.fromLTRB(Gap.md, 0, Gap.md, Gap.md),
          expandedAlignment: Alignment.centerLeft,
          children: [
            Text(answer,
                style: AppType.mono(
                    size: 12.5, color: AppColors.textMuted, height: 1.7)),
          ],
        ),
      ),
    );
  }
}
