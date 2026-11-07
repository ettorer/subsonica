import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/library.dart';
import '../services/subsonic_api.dart';
import '../state/playlist_updates.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import '../util/format.dart';
import 'cover_image.dart';
import 'create_playlist_tile.dart';
import 'playlist_name_dialog.dart';

class PlaylistButton extends StatelessWidget {
  const PlaylistButton({super.key, required this.song});

  final Song song;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: context.l10n.addToPlaylist,
      onPressed: () => showAddToPlaylistSheet(context, song),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      icon: const Icon(
        Icons.playlist_add_rounded,
        size: 24,
        color: AppColors.muted,
      ),
    );
  }
}

Future<void> showAddToPlaylistSheet(BuildContext context, Song song) {
  return showAddSongsToPlaylistSheet(
    context,
    [song],
    label: song.title,
  );
}

Future<void> showAddSongsToPlaylistSheet(
  BuildContext context,
  List<Song> songs, {
  required String label,
}) {
  return showDialog<void>(
    context: context,
    barrierColor: const Color(0x99000000),
    builder: (context) {
      final media = MediaQuery.of(context);
      final height = media.size.height * 0.55;
      return Dialog(
        alignment: Alignment.bottomCenter,
        insetPadding: EdgeInsets.zero,
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        constraints: BoxConstraints(
          minWidth: media.size.width,
          maxWidth: media.size.width,
          maxHeight: height,
        ),
        child: SizedBox(
          width: media.size.width,
          height: height,
          child: Padding(
            padding: EdgeInsets.only(bottom: media.padding.bottom),
            child: Column(
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.outline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(child: _AddToPlaylistSheet(songs: songs, label: label)),
              ],
            ),
          ),
        ),
      );
    },
  );
}

class _AddToPlaylistSheet extends StatefulWidget {
  const _AddToPlaylistSheet({required this.songs, required this.label});

  final List<Song> songs;
  final String label;

  @override
  State<_AddToPlaylistSheet> createState() => _AddToPlaylistSheetState();
}

class _AddToPlaylistSheetState extends State<_AddToPlaylistSheet> {
  List<Playlist> _playlists = const [];
  var _loading = true;
  String? _error;
  String? _addingId;

  static const _creatingId = '__creating__';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    final client = context.read<SessionController>().client;
    if (client == null) return;
    setState(() {
      _loading = _playlists.isEmpty;
      _error = null;
    });
    try {
      final playlists = await client.getPlaylists();
      if (!mounted) return;
      setState(() {
        _playlists = playlists;
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

  Future<void> _create() async {
    if (_addingId != null) return;
    final name = await askPlaylistName(
      context,
      title: context.l10n.newPlaylist,
      confirmLabel: context.l10n.create,
    );
    if (!mounted || name == null || name.isEmpty) return;
    final client = context.read<SessionController>().client;
    if (client == null) return;
    setState(() {
      _addingId = _creatingId;
      _error = null;
    });
    try {
      await client.createPlaylist(
        name,
        songIds: [for (final song in widget.songs) song.id],
      );
      if (!mounted) return;
      context.read<PlaylistUpdates>().notifyChanged();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(_addedText(name))),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _addingId = null;
        _error = localizeMessage(context.l10n, describeError(error));
      });
    }
  }

  Future<void> _add(Playlist playlist) async {
    final client = context.read<SessionController>().client;
    if (client == null || _addingId != null) return;
    setState(() {
      _addingId = playlist.id;
      _error = null;
    });
    try {
      await client.addSongsToPlaylist(playlist.id, [
        for (final song in widget.songs) song.id,
      ]);
      if (!mounted) return;
      context.read<PlaylistUpdates>().notifyChanged();
      final messenger = ScaffoldMessenger.of(context);
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(_addedText(playlist.name))),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _addingId = null;
        _error = _playlistChangeMessage(error, playlist);
      });
    }
  }

  String _addedText(String name) {
    final count = widget.songs.length;
    if (count == 1) return context.l10n.addedToName(name);
    return context.l10n.addedTracksToName(count, name);
  }

  String _playlistChangeMessage(Object error, Playlist playlist) {
    final message = describeError(error);
    final denied = message.toLowerCase().contains('not authorized');
    if (!denied) return message;
    final username = context
        .read<SessionController>()
        .config
        ?.username
        .trim();
    final owner = playlist.owner;
    if (owner.isNotEmpty && username != null && owner != username) {
      return context.l10n.playlistOwnerOnly(owner);
    }
    return context.l10n.playlistReadOnly;
  }

  @override
  Widget build(BuildContext context) {
    final client = context.read<SessionController>().client;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.addToPlaylist,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 4),
              Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: AppColors.muted),
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppColors.danger)),
                if (_playlists.isEmpty)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: _load,
                      child: Text(context.l10n.tryAgain),
                    ),
                  ),
              ],
            ],
          ),
        ),
        Expanded(child: _body(client)),
      ],
    );
  }

  Widget _body(SubsonicClient? client) {
    if (_loading && _playlists.isEmpty && _error == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final creating = _addingId == _creatingId;
    return ListView.builder(
      itemCount: _playlists.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) return _createRow(creating);
        final playlist = _playlists[index - 1];
        final adding = _addingId == playlist.id;
        final cover = client
            ?.coverUri(playlist.artworkId, size: 160)
            ?.toString();
        return InkWell(
          onTap: _addingId == null ? () => _add(playlist) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CoverImage(
                    url: cover,
                    icon: Icons.queue_music_rounded,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        playlist.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        playlist.owner.isEmpty
                            ? formatTrackCount(context.l10n, playlist.songCount)
                            : '${formatTrackCount(context.l10n, playlist.songCount)} · ${playlist.owner}',
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (adding)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _createRow(bool creating) {
    return CreatePlaylistTile(
      busy: creating,
      onTap: _addingId == null ? _create : null,
    );
  }
}
