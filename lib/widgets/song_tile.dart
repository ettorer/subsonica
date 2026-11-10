import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/library.dart';
import '../state/downloads.dart';
import '../state/player_controller.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import '../util/format.dart';
import 'cover_image.dart';
import 'song_options_button.dart';

class SongTile extends StatelessWidget {
  const SongTile({
    super.key,
    required this.song,
    required this.onTap,
    this.number,
    this.showCover = false,
    this.subtitle,
    this.active = false,
    this.playing = false,
    this.onRemove,
  });

  final Song song;
  final VoidCallback onTap;
  final int? number;
  final bool showCover;
  final String? subtitle;
  final bool active;
  final bool playing;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.accent : AppColors.text;
    return Material(
      color: active ? AppColors.accent.withValues(alpha: 0.12) : null,
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 11, 8, 11),
                child: Row(
                  children: [
                    _leading(context, color),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            song.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.muted,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      formatClock(Duration(seconds: song.duration)),
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 12,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onRemove != null)
                  IconButton(
                    tooltip: context.l10n.removeFromPlaylist,
                    onPressed: onRemove,
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints.tightFor(
                      width: 44,
                      height: 44,
                    ),
                    icon: const Icon(
                      Icons.remove_circle_outline_rounded,
                      size: 22,
                      color: AppColors.muted,
                    ),
                  ),
                SongOptionsButton(song: song),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _leading(BuildContext context, Color color) {
    if (!showCover) {
      return SizedBox(
        width: 32,
        child: active && playing
            ? const Icon(
                Icons.graphic_eq_rounded,
                color: AppColors.accent,
                size: 18,
              )
            : Text(
                number == null ? '' : '$number',
                style: TextStyle(color: color, fontSize: 13),
              ),
      );
    }
    final downloads = context.read<DownloadController>();
    final client = context.read<SessionController>().client;
    final coverFile = downloads.coverFile(song.artworkId);
    final coverUrl = coverFile == null && serverArtwork(song.artworkId)
        ? client?.coverUri(song.artworkId, size: 160)?.toString()
        : null;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: SizedBox(
        width: 48,
        height: 48,
        child: CoverImage(
          url: coverUrl,
          filePath: coverFile,
          icon: Icons.music_note_rounded,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class SongSliver extends StatelessWidget {
  const SongSliver({
    super.key,
    required this.songs,
    required this.queueTitle,
    this.showArtist = true,
    this.showCover = false,
    this.albumArtist,
    this.groupDiscs = false,
    this.onRemove,
  });

  final List<Song> songs;
  final String queueTitle;
  final bool showArtist;
  final bool showCover;
  final String? albumArtist;
  final bool groupDiscs;
  final ValueChanged<int>? onRemove;

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerController>();
    final queueMatches = player.matchesQueue(songs);
    final entries = _entries();
    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final entry = entries[index];
        final song = entry.song;
        if (song == null) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 4),
            child: Text(
              context.l10n.discNumber(entry.disc),
              style: const TextStyle(
                color: AppColors.muted,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          );
        }
        final songIndex = entry.index;
        final active = queueMatches && player.index == songIndex;
        return SongTile(
          song: song,
          number: showCover ? null : (song.track ?? songIndex + 1),
          showCover: showCover,
          subtitle: _subtitle(context, song),
          active: active,
          playing: active && player.playing,
          onRemove: onRemove == null ? null : () => onRemove!(songIndex),
          onTap: () {
            context.read<PlayerController>().playSongs(
              songs,
              startIndex: songIndex,
              shuffle: false,
              queueTitle: queueTitle,
            );
          },
        );
      }, childCount: entries.length),
    );
  }

  String? _subtitle(BuildContext context, Song song) {
    if (showArtist) return displayName(context.l10n, song.artist);
    final collectionArtist = albumArtist;
    if (collectionArtist != null && song.artist != collectionArtist) {
      return displayName(context.l10n, song.artist);
    }
    return null;
  }

  List<_Entry> _entries() {
    final grouped = groupDiscs && songs.any((song) => (song.disc ?? 1) > 1);
    final entries = <_Entry>[];
    var lastDisc = 0;
    for (var i = 0; i < songs.length; i++) {
      final disc = songs[i].disc ?? 1;
      if (grouped && disc != lastDisc) {
        entries.add(_Entry.header(disc));
        lastDisc = disc;
      }
      entries.add(_Entry.track(songs[i], i));
    }
    return entries;
  }
}

class _Entry {
  const _Entry.header(this.disc) : song = null, index = 0;
  const _Entry.track(this.song, this.index) : disc = 0;

  final int disc;
  final Song? song;
  final int index;
}
