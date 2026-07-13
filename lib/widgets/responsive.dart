// Author: eduino
// 반응형 레이아웃 — 폰/태블릿/PC 에서 내용이 과도하게 늘어나지 않도록 최대 폭 제한 + 중앙 정렬.
// 폰: 화면을 꽉 채움 / 태블릿·PC: 편안한 폭으로 가운데.

import 'package:flutter/material.dart';

abstract class Breakpoints {
  static const double tablet = 640;
  static const double desktop = 1024;

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tablet;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;
}

/// 스크롤 뷰(ListView 등) 패딩 — 넓은 화면에선 좌우 여백을 늘려 내용을 중앙 폭으로.
/// 폰: 기본 여백만. 태블릿/PC: (화면폭 - maxContent)/2 만큼 좌우 추가.
EdgeInsets pagePadding(
  BuildContext context, {
  double maxContent = 680,
  double horizontal = 16,
  double vertical = 16,
}) {
  final w = MediaQuery.sizeOf(context).width;
  final side = (w - maxContent) / 2;
  final s = side < 0 ? 0.0 : side;
  return EdgeInsets.fromLTRB(horizontal + s, vertical, horizontal + s, vertical);
}

/// 스크롤 본문을 중앙에 두고 최대 폭을 제한한다(상단 정렬).
/// 리스트/컬럼을 감싸 태블릿에서 좌우로 늘어지지 않게.
class CenteredColumn extends StatelessWidget {
  const CenteredColumn({
    super.key,
    required this.child,
    this.maxWidth = 680,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
