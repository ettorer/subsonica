import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../screens/now_playing_screen.dart';
import '../screens/queue_screen.dart';
import '../state/player_controller.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import '../l10n/context_l10n.dart';
import 'cover_image.dart';
import 'playback_slider.dart';

class MiniPlayerSlot extends StatelessWidget {
  const MiniPlayerSlot({super.key, this.safeBottom = true});

  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    final hasTrack = context.watch<PlayerController>().hasTrack;
    if (!hasTrack) return const SizedBox.shrink();
    const player = MiniPlayer();
    if (!safeBottom) return player;
    return const SafeArea(top: false, child: player);
  }
}

class MiniPlayer extends StatelessWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerController>();
    final song = player.lyricsTrack;
    if (song == null) return const SizedBox.shrink();
    final client = context.read<SessionController>().client;
    final cover = client?.coverUri(song.artworkId, size: 200)?.toString();
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 8),
      child: Material(
        color: AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openNowPlaying(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniProgressBar(),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 4, 8),
                child: Row(
                  children: [
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: CoverImage(
                        url: cover,
                        icon: Icons.music_note_rounded,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            displayName(context.l10n, song.artist),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: context.l10n.playQueue,
                      onPressed: () => openPlayQueue(context),
                      icon: const Icon(Icons.queue_music_rounded),
                    ),
                    IconButton(
                      tooltip: player.playing
                          ? context.l10n.pause
                          : context.l10n.play,
                      onPressed: () =>
                          context.read<PlayerController>().togglePlayPause(),
                      icon: Icon(
                        player.playing
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
