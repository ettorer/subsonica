import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../screens/lyrics_screen.dart';
import '../screens/now_playing_screen.dart';
import '../screens/playback_speed_sheet.dart';
import '../screens/queue_screen.dart';
import '../state/player_controller.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import 'cover_image.dart';
import 'favorite_button.dart';
import 'playback_slider.dart';
import 'playlist_button.dart';

class MiniPlayerSlot extends StatelessWidget {
  const MiniPlayerSlot({
    super.key,
    this.safeBottom = true,
    this.transport = false,
  });

  final bool safeBottom;
  final bool transport;

  @override
  Widget build(BuildContext context) {
    final hasTrack = context.watch<PlayerController>().hasTrack;
    if (!hasTrack) return const SizedBox.shrink();
    final player = transport ? const _WebTransportPlayer() : const MiniPlayer();
    if (!safeBottom) return player;
    return SafeArea(top: false, child: player);
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
          onTap: kIsWeb ? null : () => openNowPlaying(context),
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

class _WebTransportPlayer extends StatelessWidget {
  const _WebTransportPlayer();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 6, 0, 6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final screen = MediaQuery.sizeOf(context).width;
              final upper = constraints.maxWidth - 280;
              final titleWidth = upper <= 140
                  ? constraints.maxWidth / 3
                  : (screen / 3 - 20).clamp(140.0, upper);
              return Row(
                children: [
                  SizedBox(
                    width: titleWidth,
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
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                song.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                displayName(l10n, song.artist),
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
                      ],
                    ),
                  ),
                  const Expanded(child: PlaybackSlider(compact: true)),
                  _BarButton(
                    tooltip: l10n.previousTrack,
                    icon: Icons.skip_previous_rounded,
                    onPressed: player.previous,
                  ),
                  _BarButton(
                    tooltip: player.playing ? l10n.pause : l10n.play,
                    icon: player.playing
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    onPressed: player.buffering ? null : player.togglePlayPause,
                  ),
                  _BarButton(
                    tooltip: l10n.nextTrack,
                    icon: Icons.skip_next_rounded,
                    onPressed: player.next,
                  ),
                  _BarButton(
                    tooltip: player.shuffleEnabled
                        ? l10n.shuffleOn
                        : l10n.shuffle,
                    icon: Icons.shuffle_rounded,
                    color: player.shuffleEnabled
                        ? AppColors.accent
                        : AppColors.muted,
                    onPressed: player.toggleShuffle,
                  ),
                  _BarButton(
                    tooltip: switch (player.loopMode) {
                      LoopMode.off => l10n.loopOff,
                      LoopMode.all => l10n.loopAlbum,
                      LoopMode.one => l10n.loopTrack,
                    },
                    icon: player.loopMode == LoopMode.one
                        ? Icons.repeat_one_rounded
                        : Icons.repeat_rounded,
                    color: player.loopMode == LoopMode.off
                        ? AppColors.muted
                        : AppColors.accent,
                    onPressed: player.cycleLoop,
                  ),
                  _BarButton(
                    tooltip: l10n.lyrics,
                    icon: Icons.lyrics_rounded,
                    onPressed: () => openLyrics(context),
                  ),
                  PlaylistButton(song: song),
                  FavoriteButton(key: ValueKey(song.id), song: song),
                  _BarButton(
                    tooltip: l10n.options,
                    icon: Icons.more_vert_rounded,
                    onPressed: () => openPlaybackSpeed(context),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BarButton extends StatelessWidget {
  const _BarButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.color = AppColors.text,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: 24,
      color: color,
      visualDensity: VisualDensity.compact,
      icon: Icon(icon),
    );
  }
}
