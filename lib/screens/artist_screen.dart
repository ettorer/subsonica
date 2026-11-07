import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/library.dart';
import '../services/subsonic_api.dart';
import '../state/player_controller.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import '../util/format.dart';
import '../widgets/album_card.dart';
import '../widgets/choice_menu.dart';
import '../widgets/message_page.dart';
import '../widgets/mini_player.dart';
import '../widgets/playlist_button.dart';
import 'collection_screen.dart';
import 'queue_screen.dart';

void openArtist(BuildContext context, Artist artist) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ArtistScreen(artistId: artist.id, name: artist.name),
    ),
  );
}

class ArtistScreen extends StatefulWidget {
  const ArtistScreen({super.key, required this.artistId, required this.name});

  final String artistId;
  final String name;

  @override
  State<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends State<ArtistScreen> {
  Artist? _artist;
  var _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final client = context.read<SessionController>().client;
    if (client == null) return;
    setState(() {
      _loading = _artist == null;
      _error = null;
    });
    try {
      final artist = await client.getArtist(widget.artistId);
      if (!mounted) return;
      setState(() {
        _artist = artist;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = localizeMessage(context.l10n, describeError(error));
        _loading = false;
      });
    }
  }

  Future<void> _openMenu() async {
    final value = await showChoiceMenu(context, [
      MenuChoice(
        value: 'play',
        icon: Icons.play_arrow_rounded,
        label: context.l10n.playAll,
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
      ),
    ]);
    if (!mounted || value == null) return;
    await _onAction(value);
  }

  Future<void> _onAction(String action) async {
    final songs = await _collectTracks();
    if (!mounted || songs == null) return;
    if (songs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.artistNoTracks)),
      );
      return;
    }
    final artist = _artist;
    final title = artist?.name ?? widget.name;
    switch (action) {
      case 'play':
        await context.read<PlayerController>().playSongs(
          songs,
          startIndex: 0,
          shuffle: false,
          queueTitle: title,
        );
      case 'queue':
        if (!mounted) return;
        await addSongsToPlayQueue(context, songs);
      case 'playlist':
        if (!mounted) return;
        await showAddSongsToPlaylistSheet(context, songs, label: title);
    }
  }

  Future<List<Song>?> _collectTracks() async {
    final artist = _artist;
    final client = context.read<SessionController>().client;
    if (artist == null || client == null) return null;
    final cached = artist.albums.every(
      (album) => album.songs.isNotEmpty && album.songs.length >= album.songCount,
    );
    if (cached) {
      return [for (final album in artist.albums) ...album.songs];
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          canPop: false,
          child: Center(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(context.l10n.loadingTracks),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    try {
      final songs = <Song>[];
      const batch = 4;
      final albums = artist.albums;
      for (var i = 0; i < albums.length; i += batch) {
        final slice = albums.skip(i).take(batch);
        final loaded = await Future.wait(
          slice.map((album) => client.getAlbum(album.id)),
        );
        for (final album in loaded) {
          songs.addAll(album.songs);
        }
      }
      if (mounted) Navigator.of(context).pop();
      return songs;
    } catch (error) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(localizeMessage(context.l10n, describeError(error))),
          ),
        );
      }
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final artist = _artist;
    return Scaffold(
      appBar: AppBar(
        title: Text(artist?.name ?? widget.name),
        actions: [
          if (artist != null && artist.albums.isNotEmpty)
            IconButton(
              tooltip: context.l10n.artistOptions,
              onPressed: _openMenu,
              icon: const Icon(Icons.more_vert_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _body(artist)),
          const MiniPlayerSlot(),
        ],
      ),
    );
  }

  Widget _body(Artist? artist) {
    return _loading && artist == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null && artist == null
          ? MessagePage(
              icon: Icons.cloud_off_rounded,
              title: context.l10n.artistUnavailable,
              detail: _error,
              onRetry: _load,
            )
          : LayoutBuilder(
              builder: (context, constraints) {
                final albums = artist?.albums ?? const <Album>[];
                final cross = albumCrossCount(constraints.maxWidth);
                return RefreshIndicator(
                  onRefresh: _load,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                          child: Text(
                            formatAlbumCount(context.l10n, albums.length),
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ),
                      ),
                      if (albums.isEmpty)
                        SliverFillRemaining(
                          hasScrollBody: false,
                          child: MessagePage(
                            icon: Icons.album_outlined,
                            title: context.l10n.noAlbums,
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                          sliver: SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
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
                  ),
                );
              },
            );
  }
}
