// Author: eduino
// 공통 힌트 배너(지시서 0.2): info 아이콘 + 블루 tint 배경 + 한 줄 안내.

import 'package:flutter/material.dart';

import '../app/theme.dart';

class HintBanner extends StatelessWidget {
  const HintBanner(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.labTint,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 15, color: AppColors.signal),
          Gap.w8,
          Expanded(
            child: Text(
              text,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, height: 1.35, color: AppColors.signalDeep),
            ),
          ),
        ],
      ),
    );
  }
}
