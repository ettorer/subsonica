import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/library.dart';
import '../state/player_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/message_page.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_tile.dart';

void openPlayQueue(BuildContext context) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(builder: (_) => const QueueScreen()),
  );
}

Future<void> addSongsToPlayQueue(
  BuildContext context,
  List<Song> songs,
) async {
  if (songs.isEmpty) return;
  await context.read<PlayerController>().appendSongs(songs);
  if (!context.mounted) return;
  final count = songs.length;
  final l10n = context.l10n;
  final text = count == 1
      ? l10n.addedToQueue
      : l10n.addedTracksToQueue(count);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(text),
      action: SnackBarAction(
        label: l10n.show,
        onPressed: () => openPlayQueue(context),
      ),
    ),
  );
}

class QueueScreen extends StatelessWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerController>();
    final songs = player.queue;
    final source = queueLabel(context.l10n, player.queueTitle);
    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.playQueue)),
      body: Column(
        children: [
          Expanded(
            child: songs.isEmpty
                ? MessagePage(
                    icon: Icons.queue_music_rounded,
                    title: context.l10n.queueEmpty,
                  )
                : CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                          child: Text(
                            source,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ),
                      ),
                      SongSliver(songs: songs, queueTitle: source),
                    ],
                  ),
          ),
          const MiniPlayerSlot(),
        ],
      ),
    );
  }
}
