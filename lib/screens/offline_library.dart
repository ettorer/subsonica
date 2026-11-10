import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../services/local_artists.dart';
import '../state/downloads.dart';
import '../theme/app_colors.dart';
import '../util/format.dart';
import '../widgets/album_card.dart';
import '../widgets/message_page.dart';
import '../widgets/song_tile.dart';
import 'artist_screen.dart';
import 'collection_screen.dart';

class OfflineLibrary extends StatelessWidget {
  const OfflineLibrary({super.key, required this.tab});

  final int tab;

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadController>();
    if (tab == 0) return _Albums(downloads: downloads);
    if (tab == 1) return _Artists(downloads: downloads);
    return _Tracks(downloads: downloads);
  }
}

class _Albums extends StatelessWidget {
  const _Albums({required this.downloads});

  final DownloadController downloads;

  @override
  Widget build(BuildContext context) {
    final albums = downloads.libraryAlbums;
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
    final songs = downloads.libraryTracks;
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

class _Artists extends StatelessWidget {
  const _Artists({required this.downloads});

  final DownloadController downloads;

  @override
  Widget build(BuildContext context) {
    final artists = downloads.libraryArtists;
    if (artists.isEmpty) {
      return MessagePage(
        icon: Icons.person_outline_rounded,
        title: context.l10n.noArtists,
        detail: context.l10n.noArtistsYet,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 12),
      itemCount: artists.length,
      itemBuilder: (context, index) {
        final artist = artists[index];
        final letter = artistLetter(artist.name);
        final showLetter =
            index == 0 || artistLetter(artists[index - 1].name) != letter;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showLetter)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                child: Text(
                  letter,
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.surfaceHigh,
                foregroundColor: AppColors.accent,
                child: Text(
                  artist.name.characters.first.toUpperCase(),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              title: Text(
                artist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(formatAlbumCount(context.l10n, artist.albumCount)),
              onTap: () => openArtist(context, artist),
            ),
          ],
        );
      },
    );
  }
}
