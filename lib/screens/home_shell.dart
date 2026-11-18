import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/library.dart';
import '../theme/app_colors.dart';
import '../state/downloads.dart';
import '../state/player_controller.dart';
import '../state/session_controller.dart';
import '../widgets/choice_menu.dart';
import '../widgets/library_tab_bar.dart';
import '../widgets/mini_player.dart';
import 'albums_tab.dart';
import 'home_tab.dart';
import 'artists_tab.dart';
import 'collection_screen.dart';
import 'downloads_screen.dart';
import 'favorites_tab.dart';
import 'genres_tab.dart';
import 'offline_library.dart';
import 'playlists_tab.dart';
import 'search_screen.dart';
import 'settings_screen.dart';
import 'tracks_tab.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  final _search = TextEditingController();
  final _searchFocus = FocusNode();
  Timer? _debounce;
  var _tab = 0;
  var _offlineTab = 0;
  var _query = '';
  var _submittedQuery = '';
  List<Song> _trackSongs = const [];

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      setState(() => _submittedQuery = '');
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _submittedQuery = trimmed);
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _search.clear();
    setState(() {
      _query = '';
      _submittedQuery = '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final downloads = context.watch<DownloadController>();
    final offline =
        downloads.preferOffline ||
        (!session.isConnected && downloads.hasCompleted);
    final l10n = context.l10n;
    final searching = !offline && _query.trim().isNotEmpty;
    final tabs = offline
        ? LibraryTabBar.offlineItems(l10n)
        : LibraryTabBar.onlineItems(l10n);
    return Scaffold(
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
              child: Row(
                children: [
                  Expanded(
                    child: offline
                        ? Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                              child: Text(
                                l10n.offlineLabel,
                                style: const TextStyle(
                                  color: AppColors.accent,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                          )
                        : TextField(
                            controller: _search,
                            focusNode: _searchFocus,
                            textInputAction: TextInputAction.search,
                            onTapOutside: (_) => _searchFocus.unfocus(),
                            onChanged: _onSearchChanged,
                            onSubmitted: (value) {
                              _debounce?.cancel();
                              setState(() {
                                _query = value;
                                _submittedQuery = value.trim();
                              });
                            },
                            decoration: InputDecoration(
                              hintText: l10n.search,
                              prefixIcon: const Icon(
                                Icons.search,
                                color: AppColors.muted,
                              ),
                              suffixIcon: _query.isEmpty
                                  ? null
                                  : IconButton(
                                      tooltip: l10n.clear,
                                      onPressed: _clearSearch,
                                      icon: const Icon(
                                        Icons.close,
                                        color: AppColors.muted,
                                      ),
                                    ),
                              filled: true,
                              fillColor: AppColors.surface,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 12,
                              ),
                              border: _searchBorder(focused: false),
                              enabledBorder: _searchBorder(focused: false),
                              focusedBorder: _searchBorder(focused: true),
                            ),
                          ),
                  ),
                  IconButton(
                    tooltip: l10n.options,
                    onPressed: () => _openMenu(offline, searching),
                    icon: const Icon(Icons.more_vert, color: AppColors.text),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              fit: StackFit.expand,
              children: [
                ExcludeSemantics(
                  excluding: searching,
                  child: offline
                      ? OfflineLibrary(tab: _offlineTab)
                      : IndexedStack(
                          index: _tab,
                          children: [
                            const HomeTab(),
                            const AlbumsTab(),
                            TracksTab(onSongsLoaded: _onTracksLoaded),
                            const ArtistsTab(),
                            const GenresTab(),
                            const PlaylistsTab(),
                            const FavoritesTab(),
                          ],
                        ),
                ),
                if (searching) SearchScreen(query: _submittedQuery),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MiniPlayerSlot(
                  safeBottom: false,
                  transport: kIsWeb,
                  onTrackTap: (song) => openSongAlbum(context, song),
                ),
                LibraryTabBar(
                  index: offline ? _offlineTab : _tab,
                  items: tabs,
                  onSelected: (index) {
                    _searchFocus.unfocus();
                    setState(() {
                      if (offline) {
                        _offlineTab = index;
                      } else {
                        _tab = index;
                      }
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _onTracksLoaded(List<Song> songs) {
    if (!mounted) return;
    setState(() => _trackSongs = songs);
  }

  Future<void> _openMenu(bool offline, bool searching) async {
    final l10n = context.l10n;
    final value = await showChoiceMenu(context, [
      if (_tab == 2 && !offline && !searching) ...[
        MenuChoice(
          value: 'track-play-all',
          icon: Icons.play_arrow_rounded,
          label: l10n.playAll,
          enabled: _trackSongs.isNotEmpty,
        ),
        MenuChoice(
          value: 'track-random',
          icon: Icons.shuffle_rounded,
          label: l10n.random,
          enabled: _trackSongs.isNotEmpty,
        ),
      ],
      if (!kIsWeb)
        MenuChoice(
          value: 'downloads',
          icon: Icons.download_rounded,
          label: l10n.downloadsTitle,
        ),
      if (offline)
        MenuChoice(
          value: 'connection',
          icon: Icons.link_rounded,
          label: l10n.serverConnection,
        ),
      MenuChoice(
        value: 'settings',
        icon: Icons.settings_rounded,
        label: l10n.settingsTitle,
      ),
      if (kIsWeb)
        MenuChoice(
          value: 'logout',
          icon: Icons.logout_rounded,
          label: l10n.logOut,
        ),
    ]);
    if (!mounted || value == null) return;
    switch (value) {
      case 'track-play-all':
        await context.read<PlayerController>().playSongs(
          _trackSongs,
          startIndex: 0,
          shuffle: false,
          queueTitle: l10n.tracks,
        );
      case 'track-random':
        await context.read<PlayerController>().playSongs(
          _trackSongs,
          startIndex: 0,
          shuffle: true,
          queueTitle: l10n.tracks,
        );
      case 'downloads':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const DownloadsScreen()),
        );
      case 'settings':
        Navigator.of(
          context,
        ).push(MaterialPageRoute<void>(builder: (_) => const SettingsScreen()));
      case 'logout':
        unawaited(context.read<SessionController>().signOut());
      case 'connection':
        context.read<SessionController>().openConnection();
    }
  }

  OutlineInputBorder _searchBorder({required bool focused}) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: focused
          ? const BorderSide(color: AppColors.accent, width: 1.2)
          : BorderSide.none,
    );
  }
}
