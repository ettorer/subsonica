import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../state/download_controller.dart';
import '../widgets/album_card.dart';
import '../widgets/message_page.dart';
import '../widgets/song_tile.dart';
import 'collection_screen.dart';

class OfflineLibrary extends StatelessWidget {
  const OfflineLibrary({super.key, required this.tab});

  final int tab;

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadController>();
    if (tab == 0) return _Albums(downloads: downloads);
    return _Tracks(downloads: downloads);
  }
}

class _Albums extends StatelessWidget {
  const _Albums({required this.downloads});

  final DownloadController downloads;

  @override
  Widget build(BuildContext context) {
    final albums = downloads.albums;
    if (albums.isEmpty) {
      return MessagePage(
        icon: Icons.download_rounded,
        title: context.l10n.noDownloadedAlbums,
        detail: context.l10n.noDownloadedAlbumsDetail,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final cross = albumCrossCount(constraints.maxWidth);
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: cross,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 14,
                  childAspectRatio: albumChildAspectRatio(
                    constraints.maxWidth,
                    cross,
                  ),
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) => AlbumCard(
                    album: albums[index],
                    onTap: () => openAlbum(context, albums[index]),
                  ),
                  childCount: albums.length,
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Tracks extends StatelessWidget {
  const _Tracks({required this.downloads});

  final DownloadController downloads;

  @override
  Widget build(BuildContext context) {
    final songs = downloads.tracks;
    if (songs.isEmpty) {
      return MessagePage(
        icon: Icons.download_rounded,
        title: context.l10n.noDownloadedTracks,
        detail: context.l10n.noDownloadedTracksDetail,
      );
    }
    return CustomScrollView(
      slivers: [
        SongSliver(songs: songs, queueTitle: context.l10n.downloadsTitle),
      ],
    );
  }
}
