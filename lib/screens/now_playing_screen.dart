import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../screens/lyrics_screen.dart';
import '../screens/playback_speed_sheet.dart';
import '../screens/queue_screen.dart';
import '../state/player_controller.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/cover_image.dart';
import '../widgets/favorite_button.dart';
import '../widgets/playback_slider.dart';
import '../widgets/playlist_button.dart';

void openNowPlaying(BuildContext context) {
  if (ModalRoute.of(context)?.settings.name == NowPlayingScreen.routeName) {
    return;
  }
  Navigator.of(context).push(
    PageRouteBuilder<void>(
      settings: const RouteSettings(name: NowPlayingScreen.routeName),
      transitionDuration: const Duration(milliseconds: 280),
      reverseTransitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return const NowPlayingScreen();
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final tween = Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).chain(CurveTween(curve: Curves.easeOutCubic));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
    ),
  );
}

class NowPlayingScreen extends StatelessWidget {
  const NowPlayingScreen({super.key});

  static const routeName = '/now-playing';

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final player = context.watch<PlayerController>();
    final song = player.lyricsTrack;
    final client = context.read<SessionController>().client;
    final cover = client?.coverUri(song?.artworkId, size: 800)?.toString();
    final albumTitle = player.queueTitle.isEmpty
        ? l10n.nowPlaying
        : queueLabel(l10n, player.queueTitle);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: l10n.close,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
        ),
        actions: [
          if (player.canSwitchMusicOnly)
            IconButton(
              tooltip: player.musicOnly ? l10n.withVocals : l10n.musicOnly,
              onPressed: player.toggleMusicOnly,
              color: player.musicOnly ? AppColors.accent : null,
              icon: Icon(
                player.musicOnly ? Icons.mic_off_rounded : Icons.mic_rounded,
              ),
            ),
          IconButton(
            tooltip: l10n.lyrics,
            onPressed: song == null ? null : () => openLyrics(context),
            icon: const Icon(Icons.lyrics_rounded),
          ),
          IconButton(
            tooltip: l10n.playQueue,
            onPressed: () => openPlayQueue(context),
            icon: const Icon(Icons.queue_music_rounded),
          ),
          IconButton(
            tooltip: l10n.options,
            onPressed: () => openPlaybackSpeed(context),
            icon: const Icon(Icons.more_vert_rounded),
          ),
        ],
      ),
      body: song == null
          ? Column(
              children: [
                _AlbumTitle(albumTitle),
                Expanded(child: Center(child: Text(l10n.nothingPlaying))),
              ],
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                if (cover != null)
                  _Backdrop(key: ValueKey('backdrop-$cover'), url: cover),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                    child: Column(
                      children: [
                        _AlbumTitle(albumTitle),
                        Expanded(
                          child: Center(
                            child: AspectRatio(
                              aspectRatio: 1,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x73000000),
                                      blurRadius: 28,
                                      offset: Offset(0, 16),
                                    ),
                                  ],
                                ),
                                child: CoverImage(
                                  key: ValueKey(song.artworkId ?? song.id),
                                  url: cover,
                                  icon: Icons.music_note_rounded,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            PlaylistButton(song: song),
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    song.title,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    song.artist,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            FavoriteButton(key: ValueKey(song.id), song: song),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const PlaybackSlider(),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _TransportButton(
                              tooltip: player.shuffleEnabled
                                  ? l10n.shuffleOn
                                  : l10n.shuffle,
                              icon: Icons.shuffle_rounded,
                              color: player.shuffleEnabled
                                  ? AppColors.accent
                                  : AppColors.muted,
                              onPressed: player.toggleShuffle,
                            ),
                            _TransportButton(
                              tooltip: l10n.previousTrack,
                              icon: Icons.skip_previous_rounded,
                              iconSize: 40,
                              onPressed: player.previous,
                            ),
                            _PlayButton(
                              playing: player.playing,
                              buffering: player.buffering,
                              onPressed: player.togglePlayPause,
                            ),
                            _TransportButton(
                              tooltip: l10n.nextTrack,
                              icon: Icons.skip_next_rounded,
                              iconSize: 40,
                              onPressed: player.next,
                            ),
                            _TransportButton(
                              tooltip: _loopTooltip(l10n, player.loopMode),
                              icon: player.loopMode == LoopMode.one
                                  ? Icons.repeat_one_rounded
                                  : Icons.repeat_rounded,
                              color: player.loopMode == LoopMode.off
                                  ? AppColors.muted
                                  : AppColors.accent,
                              onPressed: player.cycleLoop,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _loopTooltip(AppLocalizations l10n, LoopMode mode) {
    return switch (mode) {
      LoopMode.off => l10n.loopOff,
      LoopMode.all => l10n.loopAlbum,
      LoopMode.one => l10n.loopTrack,
    };
  }
}

class _AlbumTitle extends StatelessWidget {
  const _AlbumTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 10),
      child: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.muted,
        ),
      ),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({super.key, required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: Transform.scale(
              scale: 1.2,
              child: CoverImage(
                url: url,
                icon: Icons.music_note_rounded,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x990E1014),
                  Color(0xE60E1014),
                  AppColors.background,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({
    required this.playing,
    required this.buffering,
    required this.onPressed,
  });

  final bool playing;
  final bool buffering;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.accent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: buffering ? null : onPressed,
        child: SizedBox(
          width: 72,
          height: 72,
          child: buffering
              ? const Padding(
                  padding: EdgeInsets.all(22),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    color: AppColors.onAccent,
                  ),
                )
              : Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 40,
                  color: AppColors.onAccent,
                ),
        ),
      ),
    );
  }
}

class _TransportButton extends StatelessWidget {
  const _TransportButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.iconSize = 26,
    this.color = AppColors.text,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;
  final double iconSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      iconSize: iconSize,
      color: color,
      icon: Icon(icon),
    );
  }
}
