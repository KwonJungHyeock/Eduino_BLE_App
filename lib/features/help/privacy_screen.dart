// Author: eduino
// 개인정보처리방침 — 오프라인 동작·데이터 미수집을 명확히. 스토어 등록·학교 도입 신뢰 확보.

import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../widgets/home_button.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('개인정보처리방침'),
        actions: const [HomeButton()],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(Gap.md),
          children: [
            Container(
              padding: const EdgeInsets.all(Gap.md),
              decoration: BoxDecoration(
                color: AppColors.mint.withValues(alpha: 0.10),
                borderRadius: Radii.card,
                border: Border.all(color: AppColors.mint.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined,
                      color: AppColors.mint),
                  Gap.w12,
                  Expanded(
                    child: Text(
                      '이 앱은 계정이 필요 없고, 개인정보를 서버로 전송하지 않습니다. 모든 동작은 기기와 교구 사이에서만 이루어집니다.',
                      style: const TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            Gap.h24,
            _Section(
              title: '수집하는 정보',
              body:
                  '이 앱은 이름·이메일·위치 등 개인을 식별하는 정보를 수집하지 않습니다. '
                  '별도의 회원가입이나 로그인이 없습니다.',
            ),
            _Section(
              title: '기기에 저장되는 정보',
              body:
                  '사용 편의를 위해 아래 설정만 휴대폰 내부에 저장합니다. 외부로 전송되지 않으며, 앱 삭제 시 함께 지워집니다.\n'
                  '· 선택한 블루투스 모듈·교구\n'
                  '· RC카 설정(휠·라인센서·LED 핀·모터 포트)\n'
                  '· 마지막으로 연결한 기기(빠른 재연결용)',
            ),
            _Section(
              title: '권한 사용 목적',
              body:
                  '· 블루투스/근처 기기: 교구(RC카·스마트 교구) 연결과 제어에만 사용합니다.\n'
                  '· 위치(안드로이드): 블루투스 기기 스캔을 위해 운영체제가 요구하는 권한이며, 실제 위치를 수집·저장하지 않습니다.\n'
                  '· 마이크: 음성 제어 기능을 사용할 때만 동작하며, 인식은 기기에서 처리됩니다.',
            ),
            _Section(
              title: '제3자 제공',
              body: '수집하는 개인정보가 없으므로 제3자에게 제공하는 정보도 없습니다.',
            ),
            _Section(
              title: '아동·학생 보호',
              body:
                  '이 앱은 교육 현장 사용을 전제로 하며, 개인정보를 수집하지 않아 학생이 안전하게 사용할 수 있습니다.',
            ),
            _Section(
              title: '문의',
              body:
                  '개인정보 처리에 대한 문의는 배포처(학교/기관 담당 또는 EDUINO)로 연락해 주세요.',
            ),
            Gap.h8,
            Text('본 방침은 앱 기능 변경 시 업데이트될 수 있습니다.',
                style: AppType.mono(size: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.body});
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Gap.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          Gap.h8,
          Text(body,
              style: AppType.mono(
                  size: 12.5, color: AppColors.textMuted, height: 1.7)),
        ],
      ),
    );
  }
}
