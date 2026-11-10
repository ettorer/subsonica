import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/library.dart';
import '../services/subsonic_api.dart';
import '../state/favorite_updates.dart';
import '../state/player_controller.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';

class AlbumControls extends StatefulWidget {
  const AlbumControls({
    super.key,
    required this.albumId,
    required this.songs,
    required this.queueTitle,
  });

  final String albumId;
  final List<Song> songs;
  final String queueTitle;

  @override
  State<AlbumControls> createState() => _AlbumControlsState();
}

class _AlbumControlsState extends State<AlbumControls> {
  var _starring = false;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoriteUpdates>();
    final songs = widget.songs;
    final enabled = songs.isNotEmpty;
    final starred = enabled && songs.every(favorites.starredFor);
    return PlaybackBar(
      songs: songs,
      queueTitle: widget.queueTitle,
      starred: starred,
      favoriteTooltip: starred
          ? context.l10n.unfavoriteAlbum
          : context.l10n.favoriteAlbum,
      onFavorite:
          enabled && !_starring && !widget.albumId.startsWith('phone-album:')
          ? () => _toggleFavorite(starred)
          : null,
    );
  }

  Future<void> _toggleFavorite(bool starred) async {
    final client = context.read<SessionController>().client;
    final updates = context.read<FavoriteUpdates>();
    if (client == null || _starring) return;
    final next = !starred;
    setState(() => _starring = true);
    for (final song in widget.songs) {
      updates.setStarred(song.id, next);
    }
    try {
      await client.setAlbumStarred(widget.albumId, starred: next);
    } catch (error) {
      for (final song in widget.songs) {
        updates.setStarred(song.id, starred);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizeMessage(context.l10n, describeError(error))),
        ),
      );
    } finally {
      if (mounted) setState(() => _starring = false);
    }
  }
}

class PlaylistControls extends StatefulWidget {
  const PlaylistControls({
    super.key,
    required this.songs,
    required this.queueTitle,
  });

  final List<Song> songs;
  final String queueTitle;

  @override
  State<PlaylistControls> createState() => _PlaylistControlsState();
}

class _PlaylistControlsState extends State<PlaylistControls> {
  var _starring = false;

  @override
  Widget build(BuildContext context) {
    final favorites = context.watch<FavoriteUpdates>();
    final songs = widget.songs;
    final enabled = songs.isNotEmpty;
    final starred = enabled && songs.every(favorites.starredFor);
    return PlaybackBar(
      songs: songs,
      queueTitle: widget.queueTitle,
      starred: starred,
      favoriteTooltip: starred
          ? context.l10n.unfavoritePlaylist
          : context.l10n.favoritePlaylist,
      onFavorite: enabled && !_starring ? () => _toggleFavorite(starred) : null,
    );
  }

  Future<void> _toggleFavorite(bool starred) async {
    final client = context.read<SessionController>().client;
    final updates = context.read<FavoriteUpdates>();
    if (client == null || _starring) return;
    final next = !starred;
    final ids = [for (final song in widget.songs) song.id];
    setState(() => _starring = true);
    for (final id in ids) {
      updates.setStarred(id, next);
    }
    try {
      await client.setSongsStarred(ids, starred: next);
    } catch (error) {
      for (final id in ids) {
        updates.setStarred(id, starred);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizeMessage(context.l10n, describeError(error))),
        ),
      );
    } finally {
      if (mounted) setState(() => _starring = false);
    }
  }
}

class PlaybackBar extends StatelessWidget {
  const PlaybackBar({
    super.key,
    required this.songs,
    required this.queueTitle,
    required this.starred,
    required this.favoriteTooltip,
    required this.onFavorite,
  });

  final List<Song> songs;
  final String queueTitle;
  final bool starred;
  final String favoriteTooltip;
  final VoidCallback? onFavorite;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerController>();
    final enabled = songs.isNotEmpty;
    final current = enabled && player.matchesQueue(songs);
    final playing = current && player.playing;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _IconControl(
            tooltip: current && player.shuffleEnabled
                ? context.l10n.shuffleOn
                : context.l10n.random,
            icon: Icons.shuffle_rounded,
            color: current && player.shuffleEnabled
                ? AppColors.accent
                : AppColors.muted,
            onPressed: enabled ? () => _random(player, current) : null,
          ),
          _IconControl(
            tooltip: context.l10n.previousTrack,
            icon: Icons.skip_previous_rounded,
            iconSize: 32,
            onPressed: enabled ? () => _previous(player, current) : null,
          ),
          const SizedBox(width: 6),
          _PlayControl(
            playing: playing,
            busy: current && player.buffering,
            onPressed: enabled ? () => _play(player, current) : null,
          ),
          const SizedBox(width: 6),
          _IconControl(
            tooltip: context.l10n.nextTrack,
            icon: Icons.skip_next_rounded,
            iconSize: 32,
            onPressed: enabled ? () => _next(player, current) : null,
          ),
          _IconControl(
            tooltip: favoriteTooltip,
            icon: starred
                ? Icons.favorite_rounded
                : Icons.favorite_border_rounded,
            color: starred ? AppColors.accent : AppColors.muted,
            onPressed: onFavorite,
          ),
        ],
      ),
    );
  }

  void _random(PlayerController player, bool current) {
    if (current) {
      player.toggleShuffle();
      return;
    }
    player.playSongs(
      songs,
      startIndex: 0,
      shuffle: true,
      queueTitle: queueTitle,
    );
  }

  void _play(PlayerController player, bool current) {
    if (current) {
      player.togglePlayPause();
      return;
    }
    player.playSongs(
      songs,
      startIndex: 0,
      shuffle: false,
      queueTitle: queueTitle,
    );
  }

  void _previous(PlayerController player, bool current) {
    if (current) {
      player.previous();
      return;
    }
    final last = songs.length - 1;
    player.playSongs(
      songs,
      startIndex: last < 0 ? 0 : last,
      shuffle: false,
      queueTitle: queueTitle,
    );
  }

  void _next(PlayerController player, bool current) {
    if (current) {
      player.next();
      return;
    }
    player.playSongs(
      songs,
      startIndex: 0,
      shuffle: false,
      queueTitle: queueTitle,
    );
  }
}

class _IconControl extends StatelessWidget {
  const _IconControl({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
    this.iconSize = 24,
    this.color = AppColors.text,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;
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

class _PlayControl extends StatelessWidget {
  const _PlayControl({
    required this.playing,
    required this.busy,
    required this.onPressed,
  });

  final bool playing;
  final bool busy;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onPressed == null ? AppColors.surfaceHigh : AppColors.accent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: busy ? null : onPressed,
        child: SizedBox(
          width: 52,
          height: 52,
          child: busy
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.onAccent,
                  ),
                )
              : Icon(
                  playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  size: 30,
                  color: AppColors.onAccent,
                ),
        ),
      ),
    );
  }
}
