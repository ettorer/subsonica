import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

Widget localCoverImage(String path, {required IconData icon}) {
  return Center(child: Icon(icon, color: AppColors.accent, size: 42));
}
