// Author: eduino
// 방향 반응형 세로 배치 헬퍼 (03-9).
// 세로: 기존 Column 을 그대로 반환 → 세로 레이아웃 회귀 0.
// 가로: 높이가 줄어 고정 채움(Spacer) 구조가 넘치므로 스크롤로 전환하고,
//       Spacer 는 고정 갭으로 치환한다(스크롤 안에서는 높이가 무한이라 Spacer 사용 불가).
//       하단 인셋(iOS 홈 인디케이터/제스처 바)만큼 여백을 더해 잘림을 막는다.

import 'package:flutter/material.dart';

class OrientationFillColumn extends StatelessWidget {
  const OrientationFillColumn({
    super.key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.landscapeGap = 16,
  });

  /// 세로에서 쓰던 children 그대로. 내부의 [Spacer] 는 가로에서 고정 갭으로 바뀐다.
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;
  final double landscapeGap;

  @override
  Widget build(BuildContext context) {
    final landscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;
    if (!landscape) {
      return Column(
        crossAxisAlignment: crossAxisAlignment,
        children: children,
      );
    }
    return SingleChildScrollView(
      padding:
          EdgeInsets.only(bottom: MediaQuery.viewPaddingOf(context).bottom),
      child: Column(
        crossAxisAlignment: crossAxisAlignment,
        children: [
          for (final w in children)
            if (w is Spacer) SizedBox(height: landscapeGap) else w,
        ],
      ),
    );
  }
}
