import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/library.dart';
import '../services/subsonic_api.dart';
import 'album_options_sheet.dart';
import '../state/downloads.dart';
import '../state/playlist_updates.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import '../util/format.dart';
import '../util/music_only.dart';
import '../widgets/album_controls.dart';
import '../widgets/collection_actions.dart';
import '../widgets/cover_image.dart';
import '../widgets/message_page.dart';
import '../widgets/mini_player.dart';
import '../widgets/song_tile.dart';

enum CollectionKind { album, playlist, genre }

void openAlbum(BuildContext context, Album album) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CollectionScreen(
        kind: CollectionKind.album,
        id: album.id,
        title: album.name,
        subtitle: album.subtitle,
        albumArtist: album.artist,
        coverArtId: album.artworkId,
        expectedCount: album.songCount,
      ),
    ),
  );
}

void openPlaylist(BuildContext context, Playlist playlist) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CollectionScreen(
        kind: CollectionKind.playlist,
        id: playlist.id,
        title: playlist.name,
        coverArtId: playlist.artworkId,
        expectedCount: playlist.songCount,
      ),
    ),
  );
}

void openGenre(BuildContext context, Genre genre) {
  Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => CollectionScreen(
        kind: CollectionKind.genre,
        id: genre.name,
        title: genre.name,
        expectedCount: genre.songCount,
      ),
    ),
  );
}

class CollectionScreen extends StatefulWidget {
  const CollectionScreen({
    super.key,
    required this.kind,
    required this.id,
    required this.title,
    this.subtitle,
    this.albumArtist,
    this.coverArtId,
    this.expectedCount,
  });

  final CollectionKind kind;
  final String id;
  final String title;
  final String? subtitle;
  final String? albumArtist;
  final String? coverArtId;
  final int? expectedCount;

  @override
  State<CollectionScreen> createState() => _CollectionScreenState();
}

class _CollectionScreenState extends State<CollectionScreen> {
  late String _title;
  late String? _subtitle;
  late String? _albumArtist;
  late String? _coverArtId;
  late int _count;
  List<Song> _songs = const [];
  var _albumRating = 0;
  var _loading = true;
  String? _error;
  var _seenPlaylistUpdates = 0;
  var _removing = false;

  @override
  void initState() {
    super.initState();
    _title = widget.title;
    _subtitle = widget.subtitle;
    _albumArtist = widget.albumArtist;
    _coverArtId = widget.coverArtId;
    _count = widget.expectedCount ?? 0;
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final client = context.read<SessionController>().client;
    if (client == null) {
      if (!mounted) return;
      if (widget.kind == CollectionKind.album) {
        final songs = withoutMusicOnly(
          context.read<DownloadController>().songsForAlbum(widget.id),
        );
        setState(() {
          _songs = songs;
          _count = songs.length;
          _loading = false;
          _error = null;
        });
        return;
      }
      setState(() {
        _loading = false;
        _error = context.l10n.connectToOpen;
      });
      return;
    }
    setState(() {
      _loading = _songs.isEmpty;
      _error = null;
    });
    try {
      switch (widget.kind) {
        case CollectionKind.album:
          final album = await client.getAlbum(widget.id);
          if (!mounted) return;
          final songs = withoutMusicOnly(album.songs);
          setState(() {
            _title = album.name;
            _subtitle = album.subtitle;
            _albumArtist = album.artist;
            _coverArtId = album.artworkId;
            _count = songs.length;
            _songs = songs;
            _albumRating = album.userRating;
            _loading = false;
          });
        case CollectionKind.playlist:
          final playlist = await client.getPlaylist(widget.id);
          if (!mounted) return;
          setState(() {
            _title = playlist.name;
            _coverArtId = playlist.artworkId;
            _count = playlist.songs.length;
            _songs = playlist.songs;
            _loading = false;
          });
        case CollectionKind.genre:
          final songs = await client.getSongsByGenre(widget.id);
          if (!mounted) return;
          setState(() {
            _count = songs.length;
            _songs = songs;
            _loading = false;
          });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = localizeMessage(context.l10n, describeError(error));
        _loading = false;
      });
    }
  }

  Future<void> _removeTrack(int index) async {
    if (_removing || index < 0 || index >= _songs.length) return;
    final client = context.read<SessionController>().client;
    if (client == null) return;
    final song = _songs[index];
    final previous = List<Song>.from(_songs);
    _removing = true;
    setState(() {
      _songs = [..._songs]..removeAt(index);
      _count = _songs.length;
    });
    try {
      await client.removeFromPlaylist(widget.id, index);
      if (!mounted) return;
      context.read<PlaylistUpdates>().notifyChanged();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.removedSong(song.title))),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _songs = previous;
        _count = previous.length;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizeMessage(context.l10n, describeError(error))),
        ),
      );
    } finally {
      _removing = false;
    }
  }

  IconData get _icon {
    return switch (widget.kind) {
      CollectionKind.album => Icons.album_rounded,
      CollectionKind.playlist => Icons.queue_music_rounded,
      CollectionKind.genre => Icons.sell_rounded,
    };
  }

  @override
  Widget build(BuildContext context) {
    if (widget.kind == CollectionKind.playlist) {
      final updates = context.watch<PlaylistUpdates>().generation;
      if (updates != _seenPlaylistUpdates) {
        _seenPlaylistUpdates = updates;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _load();
        });
      }
    }
    final client = context.read<SessionController>().client;
    final downloads = context.watch<DownloadController>();
    final localCover = downloads.coverFile(_coverArtId);
    final cover = localCover != null || _coverArtId == null
        ? null
        : client?.coverUri(_coverArtId, size: 800)?.toString();
    final width = MediaQuery.sizeOf(context).width;
    final side = (width - 96).clamp(180.0, 280.0);
    final webAlbum = kIsWeb && widget.kind == CollectionKind.album;
    return Scaffold(
      appBar: AppBar(
        actions: [
          if (widget.kind == CollectionKind.album && _songs.isNotEmpty)
            IconButton(
              tooltip: context.l10n.options,
              onPressed: () => openAlbumOptions(
                context,
                albumId: widget.id,
                songs: _songs,
                serverRating: _albumRating,
              ),
              icon: const Icon(Icons.more_vert),
            ),
        ],
      ),
      body: webAlbum
          ? _WebAlbumBody(
              cover: cover,
              localCover: localCover,
              icon: _icon,
              title: _title,
              subtitle: _subtitle,
              countLabel: formatTrackCount(context.l10n, _count),
              controls: AlbumControls(
                albumId: widget.id,
                songs: _loading ? const [] : _songs,
                queueTitle: _title,
              ),
              onRefresh: _load,
              tracks: _trackSlivers(),
            )
          : Column(
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    child: CustomScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      slivers: [
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                            child: Column(
                              children: [
                                Center(
                                  child: SizedBox(
                                    width: side,
                                    height: side,
                                    child: CoverImage(
                                      url: cover,
                                      filePath: localCover,
                                      icon: _icon,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _title,
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (_subtitle != null &&
                                    widget.kind == CollectionKind.album) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    _subtitle!,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Text(
                                  formatTrackCount(context.l10n, _count),
                                  style: const TextStyle(
                                    color: AppColors.muted,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SliverToBoxAdapter(child: _transport()),
                        ..._trackSlivers(),
                      ],
                    ),
                  ),
                ),
                const MiniPlayerSlot(),
              ],
            ),
    );
  }

  Widget _transport() {
    final songs = _loading ? const <Song>[] : _songs;
    return switch (widget.kind) {
      CollectionKind.album => AlbumControls(
        albumId: widget.id,
        songs: songs,
        queueTitle: _title,
      ),
      CollectionKind.playlist => PlaylistControls(
        songs: songs,
        queueTitle: _title,
      ),
      CollectionKind.genre => CollectionActions(
        songs: songs,
        queueTitle: _title,
      ),
    };
  }

  List<Widget> _trackSlivers() {
    if (_loading) {
      return const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ];
    }
    if (_error != null) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: MessagePage(
            icon: Icons.cloud_off_rounded,
            title: context.l10n.couldNotLoadTracks,
            detail: _error,
            onRetry: _load,
          ),
        ),
      ];
    }
    if (_songs.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: MessagePage(
            icon: Icons.music_off_rounded,
            title: context.l10n.noTracks,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.only(bottom: 12),
        sliver: SongSliver(
          songs: _songs,
          queueTitle: _title,
          showArtist: widget.kind != CollectionKind.album,
          albumArtist: _albumArtist,
          groupDiscs: widget.kind == CollectionKind.album,
          onRemove: widget.kind == CollectionKind.playlist
              ? _removeTrack
              : null,
        ),
      ),
    ];
  }
}

class _WebAlbumBody extends StatelessWidget {
  const _WebAlbumBody({
    required this.cover,
    required this.localCover,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.countLabel,
    required this.controls,
    required this.onRefresh,
    required this.tracks,
  });

  final String? cover;
  final String? localCover;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String countLabel;
  final Widget controls;
  final Future<void> Function() onRefresh;
  final List<Widget> tracks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 16, 8),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      const reserved = 176.0;
                      final room = constraints.maxHeight - reserved;
                      final side = min(constraints.maxWidth, max(96.0, room));
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Center(
                            child: SizedBox(
                              width: side,
                              height: side,
                              child: CoverImage(
                                url: cover,
                                filePath: localCover,
                                icon: icon,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            title,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (subtitle != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              subtitle!,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: AppColors.muted),
                            ),
                          ],
                          const SizedBox(height: 4),
                          Text(
                            countLabel,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: max(constraints.maxWidth, 320),
                              child: controls,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
              const VerticalDivider(
                width: 1,
                thickness: 1,
                color: AppColors.outline,
              ),
              Expanded(
                flex: 2,
                child: RefreshIndicator(
                  onRefresh: onRefresh,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: tracks,
                  ),
                ),
              ),
            ],
          ),
        ),
        const MiniPlayerSlot(),
      ],
    );
  }
}
