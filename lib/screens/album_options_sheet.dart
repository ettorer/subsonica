import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/library.dart';
import '../services/subsonic_api.dart';
import '../state/downloads.dart';
import '../state/rating_updates.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import '../util/format.dart';
import '../widgets/rating_bar.dart';

void openAlbumOptions(
  BuildContext context, {
  required String albumId,
  required List<Song> songs,
  required int serverRating,
}) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => AlbumOptionsSheet(
      albumId: albumId,
      songs: songs,
      serverRating: serverRating,
    ),
  );
}

class AlbumOptionsSheet extends StatefulWidget {
  const AlbumOptionsSheet({
    super.key,
    required this.albumId,
    required this.songs,
    required this.serverRating,
  });

  final String albumId;
  final List<Song> songs;
  final int serverRating;

  @override
  State<AlbumOptionsSheet> createState() => _AlbumOptionsSheetState();
}

class _AlbumOptionsSheetState extends State<AlbumOptionsSheet> {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final downloads = context.watch<DownloadController>();
    final rating = context.watch<RatingUpdates>().albumRating(
      widget.albumId,
      widget.serverRating,
    );
    final downloaded =
        widget.songs.isNotEmpty &&
        widget.songs.every(
          (song) => downloads.entryFor(song.id)?.isComplete == true,
        );
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 16, 12 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              l10n.rating,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          RatingBar(rating: rating, onChanged: (next) => _rate(rating, next)),
          if (!kIsWeb) ...[
            const Divider(height: 1, color: AppColors.outline),
            DownloadSheetTile(
              downloaded: downloaded,
              label: downloaded ? l10n.removeDownload : l10n.downloadAlbum,
              onPressed: downloaded ? _remove : _download,
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _rate(int previous, int next) async {
    if (next == previous) return;
    final client = context.read<SessionController>().client;
    if (client == null) {
      _snack(context.l10n.connectToRate);
      return;
    }
    final ratings = context.read<RatingUpdates>();
    ratings.setAlbum(widget.albumId, next);
    try {
      await client.setRating(widget.albumId, next);
    } catch (error) {
      ratings.setAlbum(widget.albumId, previous);
      if (!mounted) return;
      _snack(localizeMessage(context.l10n, describeError(error)));
    }
  }

  Future<void> _download() async {
    final added = await context.read<DownloadController>().enqueue(
      widget.songs,
    );
    if (!mounted) return;
    final waiting = context.read<SessionController>().client == null;
    final message = added == 0
        ? context.l10n.albumAlreadyDownloaded
        : waiting
        ? context.l10n.downloadWhenReachable
        : context.l10n.downloadingTracks(formatTrackCount(context.l10n, added));
    _snack(message);
  }

  Future<void> _remove() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.removeDownloadTitle),
          content: Text(context.l10n.removeAlbumDownloadBody),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.remove),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) return;
    await context.read<DownloadController>().removeAlbum(widget.albumId);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
