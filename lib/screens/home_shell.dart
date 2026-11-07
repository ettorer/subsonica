import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../theme/app_colors.dart';
import '../state/download_controller.dart';
import '../state/session_controller.dart';
import '../widgets/library_tab_bar.dart';
import '../widgets/mini_player.dart';
import 'albums_tab.dart';
import 'artists_tab.dart';
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
    final tabs = LibraryTabBar.libraryItems(l10n);
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
                              padding: const EdgeInsets.symmetric(horizontal: 8),
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
                  PopupMenuButton<String>(
                    tooltip: l10n.options,
                    icon: const Icon(Icons.more_vert, color: AppColors.text),
                    onSelected: (value) => _openMenu(context, value),
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        value: 'downloads',
                        child: Text(l10n.downloadsTitle),
                      ),
                      if (offline)
                        PopupMenuItem(
                          value: 'connection',
                          child: Text(l10n.serverConnection),
                        ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Text(l10n.settingsTitle),
                      ),
                    ],
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
                    children: const [
                      AlbumsTab(),
                      TracksTab(),
                      ArtistsTab(),
                      GenresTab(),
                      PlaylistsTab(),
                      FavoritesTab(),
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
                const MiniPlayerSlot(safeBottom: false),
                LibraryTabBar(
                  index: offline ? _offlineTab : _tab,
                  items: offline ? tabs.take(2).toList() : tabs,
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

  void _openMenu(BuildContext context, String value) {
    switch (value) {
      case 'downloads':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const DownloadsScreen()),
        );
      case 'settings':
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
        );
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
