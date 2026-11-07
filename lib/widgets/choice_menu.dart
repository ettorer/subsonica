import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class MenuChoice {
  const MenuChoice({
    required this.value,
    required this.icon,
    required this.label,
    this.enabled = true,
  });

  final String value;
  final IconData icon;
  final String label;
  final bool enabled;
}

Future<String?> showChoiceMenu(
  BuildContext context,
  List<MenuChoice> choices,
) {
  return showDialog<String>(
    context: context,
    barrierColor: const Color(0x99000000),
    builder: (context) {
      return Dialog(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final choice in choices)
                InkWell(
                  onTap: choice.enabled
                      ? () => Navigator.of(context).pop(choice.value)
                      : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 16,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          choice.icon,
                          size: 22,
                          color: choice.enabled
                              ? AppColors.text
                              : AppColors.muted,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            choice.label,
                            style: TextStyle(
                              color: choice.enabled
                                  ? AppColors.text
                                  : AppColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}
