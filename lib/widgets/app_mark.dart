import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppMark extends StatelessWidget {
  const AppMark({super.key, this.size = 72});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.accent,
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(
        Icons.album_rounded,
        color: AppColors.onAccent,
        size: size * 0.52,
      ),
    );
  }
}
