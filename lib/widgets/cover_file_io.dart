import 'dart:io';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

Widget localCoverImage(String path, {required IconData icon}) {
  return Image.file(
    File(path),
    fit: BoxFit.cover,
    width: double.infinity,
    height: double.infinity,
    errorBuilder: (context, _, _) =>
        Center(child: Icon(icon, color: AppColors.accent, size: 42)),
  );
}
