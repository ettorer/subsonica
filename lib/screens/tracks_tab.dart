import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/library.dart';
import '../services/subsonic_api.dart';
import '../state/session_controller.dart';
import '../l10n/context_l10n.dart';
import '../theme/app_colors.dart';
import '../widgets/collection_actions.dart';
import '../widgets/message_page.dart';
import '../widgets/song_tile.dart';

class TracksTab extends StatefulWidget {
  const TracksTab({super.key});

  @override
  State<TracksTab> createState() => _TracksTabState();
}

class _TracksTabState extends State<TracksTab> {
  List<Song> _songs = const [];
  var _loading = true;
  String? _error;
  var _request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final client = context.read<SessionController>().client;
    if (client == null) return;
    final request = ++_request;
    setState(() {
      _loading = _songs.isEmpty;
      _error = null;
    });
    try {
      final songs = await client.getRandomSongs();
      if (!mounted || request != _request) return;
      setState(() {
        _songs = songs;
        _loading = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = describeError(error);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _songs.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _songs.isEmpty) {
      return MessagePage(
        icon: Icons.cloud_off_rounded,
        title: context.l10n.tracksUnavailable,
        detail: localizeMessage(context.l10n, _error!),
        onRetry: _load,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                CollectionActions(
                  songs: _songs,
                  queueTitle: context.l10n.tracks,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                  child: Text(
                    context.l10n.tracksSample,
                    style: const TextStyle(color: AppColors.muted, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
          if (_songs.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: MessagePage(
                icon: Icons.music_note_outlined,
                title: context.l10n.noTracks,
                detail: context.l10n.noSongsYet,
              ),
            )
          else
            SongSliver(
              songs: _songs,
              queueTitle: context.l10n.tracks,
              showArtist: true,
              showCover: true,
            ),
          const SliverPadding(padding: EdgeInsets.only(bottom: 12)),
        ],
      ),
    );
  }
}
