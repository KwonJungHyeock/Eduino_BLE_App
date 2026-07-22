// Author: eduino
// 전송 명령 표시 — 조이스틱·방향·기울기 공통 컴포넌트(통일). 코랄 tint 칩 카드.
//   [아이콘] 전송 → g  전진   (정지 시 회색)

import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../core/protocol/commands.dart';

class DriveCmdDisplay extends StatelessWidget {
  const DriveCmdDisplay({super.key, required this.cmd});
  final DriveCmd cmd;

  IconData get _icon => switch (cmd) {
        DriveCmd.forward => Icons.keyboard_arrow_up,
        DriveCmd.back => Icons.keyboard_arrow_down,
        DriveCmd.left => Icons.keyboard_arrow_left,
        DriveCmd.right => Icons.keyboard_arrow_right,
        DriveCmd.rotLeft => Icons.rotate_left,
        DriveCmd.rotRight => Icons.rotate_right,
        DriveCmd.stop => Icons.stop,
      };

  @override
  Widget build(BuildContext context) {
    final isStop = cmd == DriveCmd.stop;
    const accent = AppColors.accent;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.tintOf(accent),
        borderRadius: Radii.pill,
        border: Border.all(color: accent.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isStop ? AppColors.chipGray : accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_icon,
                color: isStop ? AppColors.chipGrayIcon : Colors.white, size: 24),
          ),
          Gap.w12,
          Text('전송 → ',
              style: AppType.mono(size: 14, color: AppColors.listTitle)),
          Text(cmd.code,
              style: AppType.mono(
                  size: 24,
                  weight: FontWeight.w800,
                  color: isStop ? AppColors.listDesc : accent)),
          Gap.w12,
          Text(cmd.label,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.listTitle)),
        ],
      ),
    );
  }
}
