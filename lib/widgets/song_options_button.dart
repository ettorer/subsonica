import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/download.dart';
import '../models/library.dart';
import '../screens/collection_screen.dart';
import '../screens/queue_screen.dart';
import '../services/subsonic_api.dart';
import '../state/downloads.dart';
import '../state/favorite_updates.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import 'choice_menu.dart';
import 'playlist_button.dart';

class SongOptionsButton extends StatefulWidget {
  const SongOptionsButton({super.key, required this.song});

  final Song song;

  @override
  State<SongOptionsButton> createState() => _SongOptionsButtonState();
}

class _SongOptionsButtonState extends State<SongOptionsButton> {
  var _busy = false;

  Future<void> _toggleFavorite() async {
    final client = context.read<SessionController>().client;
    final updates = context.read<FavoriteUpdates>();
    if (client == null || _busy) return;
    final song = widget.song;
    final previous = updates.starredFor(song);
    final next = !previous;
    setState(() => _busy = true);
    updates.setStarred(song.id, next);
    try {
      await client.setStarred(song.id, starred: next);
    } catch (error) {
      updates.setStarred(song.id, previous);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizeMessage(context.l10n, describeError(error))),
        ),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showAlbum() {
    final albumId = widget.song.albumId;
    if (albumId == null || albumId.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.noAlbumPage)));
      return;
    }
    openAlbum(
      context,
      Album(
        id: albumId,
        name: widget.song.album.isEmpty ? 'Album' : widget.song.album,
        artist: widget.song.artist,
        coverArt: widget.song.coverArt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final starred = context.watch<FavoriteUpdates>().starredFor(widget.song);
    final albumId = widget.song.albumId;
    final hasAlbum = albumId != null && albumId.isNotEmpty;
    return IconButton(
      tooltip: context.l10n.trackOptions,
      onPressed: () => _openMenu(starred, hasAlbum),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      icon: Icon(
        Icons.more_vert_rounded,
        size: 22,
        color: starred ? AppColors.accent : AppColors.muted,
      ),
    );
  }

  Future<void> _openMenu(bool starred, bool hasAlbum) async {
    final client = context.read<SessionController>().client;
    final downloads = context.read<DownloadController>();
    final entry = downloads.entryFor(widget.song.id);
    final value = await showChoiceMenu(context, [
      MenuChoice(
        value: 'favorite',
        icon: starred ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        label: starred ? context.l10n.unfavorite : context.l10n.favorite,
        enabled: client != null && !widget.song.id.startsWith('phone:'),
      ),
      MenuChoice(
        value: 'queue',
        icon: Icons.queue_music_rounded,
        label: context.l10n.addToQueue,
      ),
      MenuChoice(
        value: 'playlist',
        icon: Icons.playlist_add_rounded,
        label: context.l10n.addToPlaylist,
        enabled: client != null && !widget.song.id.startsWith('phone:'),
      ),
      if (!kIsWeb && !widget.song.id.startsWith('phone:'))
        _downloadChoice(entry),
      MenuChoice(
        value: 'album',
        icon: Icons.album_outlined,
        label: context.l10n.showAlbum,
        enabled: hasAlbum,
      ),
    ]);
    if (!mounted || value == null) return;
    switch (value) {
      case 'favorite':
        await _toggleFavorite();
      case 'queue':
        await addSongsToPlayQueue(context, [widget.song]);
      case 'playlist':
        await showAddToPlaylistSheet(context, widget.song);
      case 'download':
        await _download();
      case 'remove-download':
        await downloads.removeSong(widget.song.id);
      case 'album':
        _showAlbum();
    }
  }

  MenuChoice _downloadChoice(DownloadEntry? entry) {
    final status = entry?.status;
    if (status == DownloadStatus.queued ||
        status == DownloadStatus.downloading) {
      return MenuChoice(
        value: 'remove-download',
        icon: Icons.close_rounded,
        label: context.l10n.cancelDownload,
      );
    }
    if (status == DownloadStatus.complete) {
      return MenuChoice(
        value: 'remove-download',
        icon: Icons.download_done_rounded,
        label: context.l10n.removeDownload,
      );
    }
    return MenuChoice(
      value: 'download',
      icon: Icons.download_rounded,
      label: context.l10n.download,
    );
  }

  Future<void> _download() async {
    final client = context.read<SessionController>().client;
    if (client == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.connectToDownload)));
      return;
    }
    final added = await context.read<DownloadController>().enqueue([
      widget.song,
    ]);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added == 0
              ? context.l10n.trackAlreadyDownloaded
              : context.l10n.downloading,
        ),
      ),
    );
  }
}
