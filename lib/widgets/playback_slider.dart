import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/player_controller.dart';
import '../theme/app_colors.dart';
import '../util/format.dart';

class PlaybackSlider extends StatefulWidget {
  const PlaybackSlider({super.key});

  @override
  State<PlaybackSlider> createState() => _PlaybackSliderState();
}

class _PlaybackSliderState extends State<PlaybackSlider> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerController>();
    return AnimatedBuilder(
      animation: Listenable.merge([
        player.positionListenable,
        player.durationListenable,
      ]),
      builder: (context, _) {
        final duration = player.durationListenable.value;
        final shown = _drag == null
            ? player.positionListenable.value
            : Duration(milliseconds: _drag!.round());
        final totalMs = duration.inMilliseconds <= 0
            ? 1
            : duration.inMilliseconds;
        final value = shown.inMilliseconds.clamp(0, totalMs).toDouble();
        return Row(
          children: [
            _Clock(text: formatClock(shown), align: TextAlign.left),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 7,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 16,
                  ),
                  activeTrackColor: AppColors.accent,
                  inactiveTrackColor: AppColors.outline,
                  thumbColor: AppColors.accent,
                  overlayColor: AppColors.accent.withValues(alpha: 0.18),
                ),
                child: Slider(
                  value: value,
                  max: totalMs.toDouble(),
                  onChanged: duration == Duration.zero
                      ? null
                      : (next) => setState(() => _drag = next),
                  onChangeEnd: (next) async {
                    await player.seek(Duration(milliseconds: next.round()));
                    if (mounted) setState(() => _drag = null);
                  },
                ),
              ),
            ),
            _Clock(text: formatClock(duration), align: TextAlign.right),
          ],
        );
      },
    );
  }
}

class MiniProgressBar extends StatelessWidget {
  const MiniProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.read<PlayerController>();
    return AnimatedBuilder(
      animation: Listenable.merge([
        player.positionListenable,
        player.durationListenable,
      ]),
      builder: (context, _) {
        final total = player.durationListenable.value.inMilliseconds;
        final position = player.positionListenable.value.inMilliseconds;
        final value = total <= 0 ? 0.0 : (position / total).clamp(0.0, 1.0);
        return LinearProgressIndicator(
          value: value,
          minHeight: 2,
          backgroundColor: AppColors.outline,
          color: AppColors.accent,
        );
      },
    );
  }
}

class _Clock extends StatelessWidget {
  const _Clock({required this.text, required this.align});

  final String text;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      child: Text(
        text,
        textAlign: align,
        style: const TextStyle(
          color: AppColors.muted,
          fontSize: 12,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
