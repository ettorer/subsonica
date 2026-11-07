import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/library.dart';
import '../services/subsonic_api.dart';
import '../state/player_controller.dart';
import '../widgets/song_options_button.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/cover_image.dart';
import '../widgets/message_page.dart';
import 'artist_screen.dart';
import 'collection_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key, required this.query});

  final String query;

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  SearchResult? _result;
  var _loading = false;
  String? _error;
  var _request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _search();
    });
  }

  @override
  void didUpdateWidget(SearchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.query != widget.query) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _search();
      });
    }
  }

  Future<void> _search() async {
    final query = widget.query.trim();
    if (query.isEmpty) {
      setState(() {
        _loading = true;
        _error = null;
        _result = null;
      });
      return;
    }
    final client = context.read<SessionController>().client;
    if (client == null) return;
    final request = ++_request;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await client.search(query);
      if (!mounted || request != _request) return;
      setState(() {
        _result = result;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = localizeMessage(context.l10n, describeError(error));
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return ColoredBox(
      color: AppColors.background,
      child: _loading && result == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && result == null
          ? MessagePage(
              icon: Icons.cloud_off_rounded,
              title: context.l10n.searchFailed,
              detail: _error,
              onRetry: _search,
            )
          : result == null || result.isEmpty
          ? MessagePage(
              icon: Icons.search_off_rounded,
              title: context.l10n.noResults,
            )
          : ListView(
              padding: const EdgeInsets.only(bottom: 16),
              children: [
                if (result.artists.isNotEmpty)
                  _Section(
                    title: context.l10n.artists,
                    children: [
                      for (final artist in result.artists)
                        ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.surfaceHigh,
                            foregroundColor: AppColors.accent,
                            child: Text(
                              artist.name.characters.first.toUpperCase(),
                            ),
                          ),
                          title: Text(artist.name),
                          onTap: () => openArtist(context, artist),
                        ),
                    ],
                  ),
                if (result.albums.isNotEmpty)
                  _Section(
                    title: context.l10n.albums,
                    children: [
                      for (final album in result.albums)
                        _AlbumResult(album: album),
                    ],
                  ),
                if (result.songs.isNotEmpty)
                  _Section(
                    title: context.l10n.tracks,
                    children: [
                      for (var i = 0; i < result.songs.length; i++)
                        _SongResult(songs: result.songs, index: i),
                    ],
                  ),
              ],
            ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        ...children,
      ],
    );
  }
}

class _AlbumResult extends StatelessWidget {
  const _AlbumResult({required this.album});

  final Album album;

  @override
  Widget build(BuildContext context) {
    final client = context.read<SessionController>().client;
    final cover = client?.coverUri(album.artworkId, size: 160)?.toString();
    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 48,
        child: CoverImage(
          url: cover,
          icon: Icons.album_rounded,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      title: Text(album.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        album.subtitle,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      onTap: () => openAlbum(context, album),
    );
  }
}

class _SongResult extends StatelessWidget {
  const _SongResult({required this.songs, required this.index});

  final List<Song> songs;
  final int index;

  @override
  Widget build(BuildContext context) {
    final song = songs[index];
    final client = context.read<SessionController>().client;
    final cover = client?.coverUri(song.artworkId, size: 160)?.toString();
    return ListTile(
      leading: SizedBox(
        width: 48,
        height: 48,
        child: CoverImage(
          url: cover,
          icon: Icons.music_note_rounded,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(song.artist, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: SongOptionsButton(song: song),
      onTap: () {
        context.read<PlayerController>().playSongs(
          songs,
          startIndex: index,
          shuffle: false,
          queueTitle: 'Search',
        );
      },
    );
  }
}
