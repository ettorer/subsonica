import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/library.dart';
import '../state/player_controller.dart';
import '../theme/app_colors.dart';

class CollectionActions extends StatelessWidget {
  const CollectionActions({
    super.key,
    required this.songs,
    required this.queueTitle,
  });

  final List<Song> songs;
  final String queueTitle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final player = context.watch<PlayerController>();
    final enabled = songs.isNotEmpty;
    final randomActive =
        enabled && player.shuffleEnabled && player.matchesQueue(songs);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          Expanded(
            child: FilledButton.icon(
              onPressed: enabled
                  ? () => context.read<PlayerController>().playSongs(
                      songs,
                      startIndex: 0,
                      shuffle: false,
                      queueTitle: queueTitle,
                    )
                  : null,
              icon: const Icon(Icons.play_arrow_rounded, size: 20),
              label: Text(l10n.play, maxLines: 1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: enabled
                  ? () => context.read<PlayerController>().stop()
                  : null,
              icon: const Icon(Icons.stop_rounded, size: 20),
              label: Text(l10n.stop, maxLines: 1),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: enabled
                  ? () => context.read<PlayerController>().playSongs(
                      songs,
                      startIndex: 0,
                      shuffle: true,
                      queueTitle: queueTitle,
                    )
                  : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: randomActive
                    ? AppColors.accent
                    : AppColors.text,
                side: BorderSide(
                  color: randomActive ? AppColors.accent : AppColors.outline,
                ),
              ),
              icon: const Icon(Icons.shuffle_rounded, size: 18),
              label: Text(l10n.random, maxLines: 1),
            ),
          ),
        ],
      ),
    );
  }
}
