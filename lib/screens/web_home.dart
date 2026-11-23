import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/library.dart';
import '../services/subsonic_api.dart';
import '../state/favorite_updates.dart';
import '../state/player_controller.dart';
import '../state/playlist_updates.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import '../util/album_letter_scan.dart';
import '../util/format.dart';
import '../util/library_letter.dart';
import '../util/web_home_layout.dart';
import '../widgets/album_card.dart';
import '../widgets/cover_image.dart';
import 'artist_screen.dart';
import 'collection_screen.dart';

class WebHome extends StatefulWidget {
  const WebHome({super.key, this.active = false, this.shownTick = 0});

  final bool active;
  final int shownTick;

  @override
  State<WebHome> createState() => _WebHomeState();
}

class _WebHomeState extends State<WebHome> {
  static const _albumPage = 200;

  final _recent = <Album>[];
  final _favorites = <Song>[];
  final _suggested = <Song>[];
  final _playlists = <Playlist>[];
  final _albums = <Album>[];
  final _artists = <Artist>[];
  var _albumScan = AlbumLetterScan();

  var _recentLoading = true;
  var _favoritesLoading = true;
  var _suggestedLoading = false;
  var _playlistsLoading = true;
  var _albumsLoading = false;
  var _artistsLoading = true;
  String? _recentError;
  String? _favoritesError;
  String? _suggestedError;
  String? _playlistsError;
  String? _albumsError;
  String? _artistsError;
  String? _albumLetter;
  String? _artistLetter;
  var _albumRequest = 0;
  var _recentRequest = 0;
  var _suggestedRequest = 0;
  var _seenFavorites = 0;
  var _seenPlaylists = 0;
  var _seenTrackChoice = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAll());
  }

  @override
  void didUpdateWidget(WebHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shownAgain =
        widget.active &&
        (!oldWidget.active || widget.shownTick != oldWidget.shownTick);
    if (shownAgain) _loadRecent();
  }

  Future<void> _loadAll() async {
    final albumLetter = _albumLetter;
    final artistLetter = _artistLetter;
    _albumScan = AlbumLetterScan();
    await Future.wait([
      _loadRecent(),
      _loadFavorites(),
      _loadPlaylists(),
      _loadArtists(artistLetter),
      albumLetter == null ? _loadFirstAlbums() : _searchAlbums(albumLetter),
    ]);
  }

  Future<void> _loadRecent() async {
    final client = context.read<SessionController>().client;
    if (client == null) return;
    final request = ++_recentRequest;
    setState(() {
      _recentLoading = _recent.isEmpty;
      _recentError = null;
    });
    try {
      final page = await client.getRecentAlbums(offset: 0, size: 24);
      if (!mounted || request != _recentRequest) return;
      setState(() {
        _recent
          ..clear()
          ..addAll(page);
        _recentLoading = false;
      });
    } catch (error) {
      if (!mounted || request != _recentRequest) return;
      setState(() {
        _recentError = describeError(error);
        _recentLoading = false;
      });
    }
  }

  Future<void> _loadFavorites() async {
    final client = context.read<SessionController>().client;
    if (client == null) return;
    setState(() {
      _favoritesLoading = _favorites.isEmpty;
      _favoritesError = null;
    });
    try {
      final favorites = await client.getFavorites();
      if (!mounted) return;
      setState(() {
        _favorites
          ..clear()
          ..addAll(favorites.songs);
        _favoritesLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _favoritesError = describeError(error);
        _favoritesLoading = false;
      });
    }
  }

  Future<void> _loadPlaylists() async {
    final client = context.read<SessionController>().client;
    if (client == null) return;
    setState(() {
      _playlistsLoading = _playlists.isEmpty;
      _playlistsError = null;
    });
    try {
      final playlists = await client.getPlaylists();
      if (!mounted) return;
      setState(() {
        _playlists
          ..clear()
          ..addAll(playlists);
        _playlistsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _playlistsError = describeError(error);
        _playlistsLoading = false;
      });
    }
  }

  Future<void> _loadSuggested(Song? song) async {
    final client = context.read<SessionController>().client;
    final request = ++_suggestedRequest;
    if (song == null || client == null) {
      if (!mounted) return;
      setState(() {
        _suggested.clear();
        _suggestedLoading = false;
        _suggestedError = null;
      });
      return;
    }
    setState(() {
      _suggestedLoading = true;
      _suggestedError = null;
    });
    try {
      final songs = await client.getSimilarSongs(song.id);
      if (!mounted || request != _suggestedRequest) return;
      setState(() {
        _suggested
          ..clear()
          ..addAll(songs.where((item) => item.id != song.id));
        _suggestedLoading = false;
      });
    } catch (error) {
      if (!mounted || request != _suggestedRequest) return;
      setState(() {
        _suggestedError = describeError(error);
        _suggestedLoading = false;
      });
    }
  }

  Future<void> _loadFirstAlbums() async {
    final client = context.read<SessionController>().client;
    if (client == null) return;
    final request = ++_albumRequest;
    setState(() {
      _albumsLoading = true;
      _albumsError = null;
    });
    try {
      final page = await client.getAlbums(offset: 0, size: _albumPage);
      if (!mounted || request != _albumRequest) return;
      _albumScan.add(page, pageSize: _albumPage);
      final letter = page.isEmpty
          ? libraryAlphabet.first
          : libraryLetter(page.first.name);
      await _searchAlbums(letter, request: request);
    } catch (error) {
      if (!mounted || request != _albumRequest) return;
      setState(() {
        _albumsError = describeError(error);
        _albumsLoading = false;
      });
    }
  }

  Future<void> _searchAlbums(String letter, {int? request}) async {
    final client = context.read<SessionController>().client;
    if (client == null) return;
    final ticket = request ?? ++_albumRequest;
    setState(() {
      _albumLetter = letter;
      _albumsLoading = true;
      _albumsError = null;
    });
    try {
      var guard = 0;
      while (mounted &&
          ticket == _albumRequest &&
          !_albumScan.covers(letter) &&
          guard < 50) {
        guard++;
        final page = await client.getAlbums(
          offset: _albumScan.loaded.length,
          size: _albumPage,
        );
        if (!mounted || ticket != _albumRequest) return;
        final before = _albumScan.loaded.length;
        _albumScan.add(page, pageSize: _albumPage);
        if (_albumScan.loaded.length == before) break;
      }
    } catch (error) {
      if (!mounted || ticket != _albumRequest) return;
      setState(() {
        _albumsError = describeError(error);
        _albumsLoading = false;
      });
      return;
    }
    if (!mounted || ticket != _albumRequest) return;
    setState(() {
      _albumLetter = letter;
      _albums
        ..clear()
        ..addAll(_albumScan.matching(letter));
      _albumsLoading = false;
    });
  }

  Future<void> _loadArtists(String? keepLetter) async {
    final client = context.read<SessionController>().client;
    if (client == null) return;
    setState(() {
      _artistsLoading = _artists.isEmpty;
      _artistsError = null;
    });
    try {
      final sections = await client.getArtists();
      if (!mounted) return;
      final artists = [for (final section in sections) ...section.artists];
      final letter =
          keepLetter ??
          firstLibraryLetter(artists.map((artist) => artist.name));
      setState(() {
        _artists
          ..clear()
          ..addAll(artists);
        _artistLetter = letter ?? _artistLetter;
        _artistsLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _artistsError = describeError(error);
        _artistsLoading = false;
      });
    }
  }

  List<Artist> get _visibleArtists {
    final letter = _artistLetter;
    if (letter == null) return const [];
    return [
      for (final artist in _artists)
        if (libraryLetter(artist.name) == letter) artist,
    ];
  }

  void _followTrackChoice(PlayerController player) {
    if (player.trackChoice == _seenTrackChoice) return;
    final choice = player.trackChoice;
    final song = player.trackChoiceSong;
    _seenTrackChoice = choice;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _seenTrackChoice != choice) return;
      _loadSuggested(song);
    });
  }

  @override
  Widget build(BuildContext context) {
    _followTrackChoice(context.watch<PlayerController>());
    final favoriteUpdates = context.watch<FavoriteUpdates>().generation;
    if (favoriteUpdates != _seenFavorites) {
      _seenFavorites = favoriteUpdates;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadFavorites();
      });
    }
    final playlistUpdates = context.watch<PlaylistUpdates>().generation;
    if (playlistUpdates != _seenPlaylists) {
      _seenPlaylists = playlistUpdates;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadPlaylists();
      });
    }
    final l10n = context.l10n;
    return RefreshIndicator(
      onRefresh: _loadAll,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _SectionTitle(l10n.homeRecent)),
          SliverToBoxAdapter(child: _recentBody()),
          SliverToBoxAdapter(child: _SectionTitle(l10n.homeFavoriteTracks)),
          SliverToBoxAdapter(child: _favoritesBody()),
          SliverToBoxAdapter(child: _SectionTitle(l10n.homeSuggested)),
          SliverToBoxAdapter(child: _suggestedBody()),
          SliverToBoxAdapter(child: _SectionTitle(l10n.homePlaylists)),
          SliverToBoxAdapter(child: _playlistsBody()),
          SliverToBoxAdapter(child: _SectionTitle(l10n.albums)),
          SliverToBoxAdapter(
            child: _LetterBar(
              selected: _albumLetter,
              onSelected: _searchAlbums,
            ),
          ),
          SliverToBoxAdapter(child: _albumsBody()),
          SliverToBoxAdapter(child: _SectionTitle(l10n.artists)),
          SliverToBoxAdapter(
            child: _LetterBar(
              selected: _artistLetter,
              onSelected: (letter) => setState(() => _artistLetter = letter),
            ),
          ),
          SliverToBoxAdapter(child: _artistsBody()),
          const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
        ],
      ),
    );
  }

  Widget _recentBody() {
    if (_recentLoading && _recent.isEmpty) return const _SectionProgress();
    if (_recentError != null && _recent.isEmpty) {
      return _SectionMessage(localizeMessage(context.l10n, _recentError!));
    }
    if (_recent.isEmpty) return _SectionMessage(context.l10n.noRecentAlbums);
    return _Rail(
      itemCount: _recent.length,
      itemBuilder: (context, index) {
        final album = _recent[index];
        return SizedBox(
          width: WebHomeLayout.cover,
          child: AlbumCard(
            album: album,
            onTap: () => openAlbum(context, album),
          ),
        );
      },
    );
  }

  Widget _favoritesBody() {
    if (_favoritesLoading && _favorites.isEmpty) {
      return const _SectionProgress();
    }
    if (_favoritesError != null && _favorites.isEmpty) {
      return _SectionMessage(localizeMessage(context.l10n, _favoritesError!));
    }
    if (_favorites.isEmpty) {
      return _SectionMessage(context.l10n.noFavoriteTracks);
    }
    return _Rail(
      itemCount: _favorites.length,
      itemBuilder: (context, index) {
        final song = _favorites[index];
        return _TrackCard(
          song: song,
          onTap: () {
            context.read<PlayerController>().playSongs(
              _favorites,
              startIndex: index,
              shuffle: false,
              queueTitle: context.l10n.tabFavorites,
            );
          },
        );
      },
    );
  }

  Widget _suggestedBody() {
    if (_seenTrackChoice == 0 &&
        _suggested.isEmpty &&
        _suggestedError == null) {
      return _SectionMessage(context.l10n.homeSuggestedIdle);
    }
    if (_suggestedLoading && _suggested.isEmpty) {
      return const _SectionProgress();
    }
    if (_suggestedError != null && _suggested.isEmpty) {
      return _SectionMessage(localizeMessage(context.l10n, _suggestedError!));
    }
    if (_suggested.isEmpty) return _SectionMessage(context.l10n.radioEmpty);
    return _Rail(
      itemCount: _suggested.length,
      itemBuilder: (context, index) {
        final song = _suggested[index];
        return _TrackCard(
          song: song,
          onTap: () {
            context.read<PlayerController>().playSongs(
              _suggested,
              startIndex: index,
              shuffle: false,
              queueTitle: context.l10n.homeSuggested,
            );
          },
        );
      },
    );
  }

  Widget _playlistsBody() {
    if (_playlistsLoading && _playlists.isEmpty) {
      return const _SectionProgress();
    }
    if (_playlistsError != null && _playlists.isEmpty) {
      return _SectionMessage(localizeMessage(context.l10n, _playlistsError!));
    }
    if (_playlists.isEmpty) return _SectionMessage(context.l10n.noPlaylists);
    return _Rail(
      itemCount: _playlists.length,
      itemBuilder: (context, index) {
        final playlist = _playlists[index];
        return _PlaylistCard(
          playlist: playlist,
          onTap: () => openPlaylist(context, playlist),
        );
      },
    );
  }

  Widget _albumsBody() {
    if (_albumsLoading && _albums.isEmpty) return const _SectionProgress();
    if (_albumsError != null && _albums.isEmpty) {
      return _SectionMessage(localizeMessage(context.l10n, _albumsError!));
    }
    if (_albums.isEmpty) return _SectionMessage(context.l10n.noAlbums);
    return _Rail(
      itemCount: _albums.length,
      itemBuilder: (context, index) {
        final album = _albums[index];
        return SizedBox(
          width: WebHomeLayout.cover,
          child: AlbumCard(
            album: album,
            onTap: () => openAlbum(context, album),
          ),
        );
      },
    );
  }

  Widget _artistsBody() {
    final visible = _visibleArtists;
    if (_artistsLoading && _artists.isEmpty) return const _SectionProgress();
    if (_artistsError != null && _artists.isEmpty) {
      return _SectionMessage(localizeMessage(context.l10n, _artistsError!));
    }
    if (visible.isEmpty) return _SectionMessage(context.l10n.noArtists);
    return _Rail(
      itemCount: visible.length,
      itemBuilder: (context, index) {
        final artist = visible[index];
        return _ArtistCard(
          artist: artist,
          onTap: () => openArtist(context, artist),
        );
      },
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({required this.itemCount, required this.itemBuilder});

  final int itemCount;
  final Widget Function(BuildContext context, int index) itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: WebHomeLayout.railHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(width: 12),
        itemBuilder: itemBuilder,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: WebHomeLayout.titleHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 0),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: Theme.of(context).textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _SectionProgress extends StatelessWidget {
  const _SectionProgress();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: WebHomeLayout.emptyHeight,
      child: Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2.4),
        ),
      ),
    );
  }
}

class _SectionMessage extends StatelessWidget {
  const _SectionMessage(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: WebHomeLayout.emptyHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppColors.muted),
          ),
        ),
      ),
    );
  }
}

class _LetterBar extends StatelessWidget {
  const _LetterBar({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: WebHomeLayout.alphabetHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        itemCount: libraryAlphabet.length,
        itemBuilder: (context, index) {
          final letter = libraryAlphabet[index];
          final on = letter == selected;
          return SizedBox(
            width: 32,
            child: TextButton(
              onPressed: () => onSelected(letter),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(32, 36),
                foregroundColor: on ? AppColors.onAccent : AppColors.text,
                backgroundColor: on ? AppColors.accent : Colors.transparent,
                shape: const StadiumBorder(),
              ),
              child: Text(
                letter,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TrackCard extends StatelessWidget {
  const _TrackCard({required this.song, required this.onTap});

  final Song song;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final client = context.read<SessionController>().client;
    final cover = client?.coverUri(song.artworkId, size: 300)?.toString();
    return SizedBox(
      width: WebHomeLayout.cover,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CoverImage(url: cover, icon: Icons.music_note_rounded),
              ),
              const SizedBox(height: 8),
              Text(
                song.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName(context.l10n, song.artist),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ArtistCard extends StatelessWidget {
  const _ArtistCard({required this.artist, required this.onTap});

  final Artist artist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final client = context.read<SessionController>().client;
    final coverId = artist.coverArt;
    final cover = coverId == null || coverId.isEmpty
        ? null
        : client?.coverUri(coverId, size: 300)?.toString();
    return SizedBox(
      width: WebHomeLayout.cover,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CoverImage(url: cover, icon: Icons.person_rounded),
              ),
              const SizedBox(height: 8),
              Text(
                artist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatAlbumCount(context.l10n, artist.albumCount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaylistCard extends StatelessWidget {
  const _PlaylistCard({required this.playlist, required this.onTap});

  final Playlist playlist;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final client = context.read<SessionController>().client;
    final cover = client?.coverUri(playlist.artworkId, size: 300)?.toString();
    return SizedBox(
      width: WebHomeLayout.cover,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CoverImage(url: cover, icon: Icons.queue_music_rounded),
              ),
              const SizedBox(height: 8),
              Text(
                playlist.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                formatTrackCount(context.l10n, playlist.songCount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
