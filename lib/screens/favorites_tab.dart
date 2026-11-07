import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/library.dart';
import '../services/subsonic_api.dart';
import '../state/favorite_updates.dart';
import '../state/session_controller.dart';
import '../l10n/context_l10n.dart';
import '../theme/app_colors.dart';
import '../util/format.dart';
import '../widgets/collection_actions.dart';
import '../widgets/cover_image.dart';
import '../widgets/message_page.dart';
import '../widgets/song_tile.dart';
import 'artist_screen.dart';
import 'collection_screen.dart';

class FavoritesTab extends StatefulWidget {
  const FavoritesTab({super.key});

  @override
  State<FavoritesTab> createState() => _FavoritesTabState();
}

class _FavoritesTabState extends State<FavoritesTab> {
  Favorites _favorites = const Favorites();
  var _loading = true;
  String? _error;
  var _seenUpdates = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final client = context.read<SessionController>().client;
    if (client == null) return;
    setState(() {
      _loading = _favorites.isEmpty;
      _error = null;
    });
    try {
      final favorites = await client.getFavorites();
      if (!mounted) return;
      setState(() {
        _favorites = favorites;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = describeError(error);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final updates = context.watch<FavoriteUpdates>().generation;
    if (updates != _seenUpdates) {
      _seenUpdates = updates;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    if (_loading && _favorites.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _favorites.isEmpty) {
      return MessagePage(
        icon: Icons.cloud_off_rounded,
        title: context.l10n.favoritesUnavailable,
        detail: localizeMessage(context.l10n, _error!),
        onRetry: _load,
      );
    }
    final client = context.read<SessionController>().client;
    final favorites = _favorites;
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (favorites.songs.isNotEmpty)
            SliverToBoxAdapter(
              child: CollectionActions(
                songs: favorites.songs,
                queueTitle: context.l10n.tabFavorites,
              ),
            ),
          if (favorites.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: MessagePage(
                icon: Icons.favorite_border_rounded,
                title: context.l10n.noFavorites,
                detail: context.l10n.noFavoritesDetail,
              ),
            ),
          if (favorites.albums.isNotEmpty) ...[
            SliverToBoxAdapter(child: _SectionTitle(context.l10n.albums)),
            SliverList.builder(
              itemCount: favorites.albums.length,
              itemBuilder: (context, index) {
                final album = favorites.albums[index];
                return ListTile(
                  leading: SizedBox(
                    width: 48,
                    height: 48,
                    child: CoverImage(
                      url: client
                          ?.coverUri(album.artworkId, size: 160)
                          ?.toString(),
                      icon: Icons.album_rounded,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  title: Text(
                    album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(displayName(context.l10n, album.subtitle)),
                  onTap: () => openAlbum(context, album),
                );
              },
            ),
          ],
          if (favorites.artists.isNotEmpty) ...[
            SliverToBoxAdapter(child: _SectionTitle(context.l10n.artists)),
            SliverList.builder(
              itemCount: favorites.artists.length,
              itemBuilder: (context, index) {
                final artist = favorites.artists[index];
                return ListTile(
                  leading: const Icon(
                    Icons.person_rounded,
                    color: AppColors.accent,
                  ),
                  title: Text(
                    artist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    formatAlbumCount(context.l10n, artist.albumCount),
                  ),
                  onTap: () => openArtist(context, artist),
                );
              },
            ),
          ],
          if (favorites.songs.isNotEmpty) ...[
            SliverToBoxAdapter(child: _SectionTitle(context.l10n.tracks)),
            SongSliver(
              songs: favorites.songs,
              queueTitle: context.l10n.tabFavorites,
              showArtist: true,
            ),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 12)),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.muted,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
