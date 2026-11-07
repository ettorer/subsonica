import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class RatingBar extends StatefulWidget {
  const RatingBar({super.key, required this.rating, required this.onChanged});

  final int rating;
  final ValueChanged<int> onChanged;

  @override
  State<RatingBar> createState() => _RatingBarState();
}

class _RatingBarState extends State<RatingBar> {
  static const _starSize = 32.0;
  static const _gap = 6.0;

  int? _drag;
  var _dragging = false;
  final _box = GlobalKey();

  double get _groupWidth => 6 * _starSize + 5 * _gap;

  int get _shown {
    final rating = _drag ?? widget.rating;
    if (rating < 0) return 0;
    if (rating > 5) return 5;
    return rating;
  }

  int _at(double dx) {
    final box = _box.currentContext?.findRenderObject() as RenderBox?;
    final width = box?.size.width ?? 0;
    if (width <= 0) return 0;
    final start = (width - _groupWidth) / 2;
    final cell = _starSize + _gap;
    var best = 0;
    var bestDistance = double.infinity;
    for (var index = 0; index < 6; index++) {
      final center = start + index * cell + _starSize / 2;
      final distance = (dx - center).abs();
      if (distance < bestDistance) {
        best = index;
        bestDistance = distance;
      }
    }
    return best;
  }

  void _preview(double dx) {
    final next = _at(dx);
    if (_drag == next) return;
    setState(() => _drag = next);
  }

  void _finish(double? dx) {
    final next = dx == null ? _drag : _at(dx);
    setState(() => _drag = null);
    if (next == null || next == widget.rating) return;
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final shown = _shown;
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: GestureDetector(
        key: _box,
        behavior: HitTestBehavior.opaque,
        onTapDown: (details) => _preview(details.localPosition.dx),
        onTapUp: (details) => _finish(details.localPosition.dx),
        onTapCancel: () {
          if (_dragging) return;
          setState(() => _drag = null);
        },
        onHorizontalDragStart: (details) {
          _dragging = true;
          _preview(details.localPosition.dx);
        },
        onHorizontalDragUpdate: (details) => _preview(details.localPosition.dx),
        onHorizontalDragEnd: (_) {
          _dragging = false;
          _finish(null);
        },
        onHorizontalDragCancel: () {
          _dragging = false;
          setState(() => _drag = null);
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var index = 0; index < 6; index++) ...[
              if (index > 0) const SizedBox(width: _gap),
              index == 0
                  ? const _ZeroStar()
                  : Icon(
                      shown >= index
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      size: _starSize,
                      color: shown >= index ? AppColors.accent : AppColors.muted,
                    ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ZeroStar extends StatelessWidget {
  const _ZeroStar();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: _RatingBarState._starSize,
      height: _RatingBarState._starSize,
      child: CustomPaint(
        foregroundPainter: _SlashPainter(),
        child: Icon(
          Icons.star_border_rounded,
          color: AppColors.danger,
          size: _RatingBarState._starSize,
        ),
      ),
    );
  }
}

class _SlashPainter extends CustomPainter {
  const _SlashPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final start = Offset(size.width * 0.22, size.height * 0.20);
    final end = Offset(size.width * 0.78, size.height * 0.80);
    canvas.drawLine(
      start,
      end,
      Paint()
        ..color = AppColors.danger
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class DownloadSheetTile extends StatelessWidget {
  const DownloadSheetTile({
    super.key,
    required this.downloaded,
    required this.label,
    required this.onPressed,
  });

  final bool downloaded;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.only(left: 8, right: 8),
      leading: Icon(
        Icons.download_rounded,
        color: downloaded ? AppColors.accent : AppColors.text,
      ),
      title: Text(label),
      onTap: onPressed,
    );
  }
}
