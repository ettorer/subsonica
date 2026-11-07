import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/library.dart';
import '../services/subsonic_api.dart';
import '../state/playlist_updates.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import '../util/format.dart';
import '../widgets/cover_image.dart';
import '../widgets/create_playlist_tile.dart';
import '../widgets/message_page.dart';
import '../widgets/playlist_name_dialog.dart';
import 'collection_screen.dart';

class PlaylistsTab extends StatefulWidget {
  const PlaylistsTab({super.key});

  @override
  State<PlaylistsTab> createState() => _PlaylistsTabState();
}

class _PlaylistsTabState extends State<PlaylistsTab> {
  List<Playlist> _playlists = const [];
  var _loading = true;
  String? _error;
  var _seenUpdates = 0;
  var _creating = false;

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
    if (_creating) return;
    final client = context.read<SessionController>().client;
    if (client == null) return;
    final name = await askPlaylistName(
      context,
      title: context.l10n.newPlaylist,
      confirmLabel: context.l10n.create,
    );
    if (!mounted || name == null || name.isEmpty) return;
    setState(() => _creating = true);
    try {
      await client.createPlaylist(name);
      if (!mounted) return;
      context.read<PlaylistUpdates>().notifyChanged();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.createdPlaylist(name))));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(localizeMessage(context.l10n, describeError(error))),
        ),
      );
    } finally {
      if (mounted) setState(() => _creating = false);
    }
  }

  Future<void> _openMenu(Playlist playlist, BuildContext tileContext) async {
    final box = tileContext.findRenderObject() as RenderBox?;
    final overlay = Overlay.of(tileContext).context.findRenderObject();
    if (box == null || overlay is! RenderBox) return;
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    final action = await showMenu<String>(
      context: tileContext,
      position: RelativeRect.fromRect(
        origin & box.size,
        Offset.zero & overlay.size,
      ),
      items: [
        PopupMenuItem(value: 'rename', child: Text(context.l10n.rename)),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            context.l10n.delete,
            style: const TextStyle(color: AppColors.danger),
          ),
        ),
      ],
    );
    if (!mounted || action == null) return;
    switch (action) {
      case 'rename':
        await _rename(playlist);
      case 'delete':
        await _delete(playlist);
    }
  }

  Future<void> _rename(Playlist playlist) async {
    final client = context.read<SessionController>().client;
    if (client == null) return;
    final name = await askPlaylistName(
      context,
      title: context.l10n.renamePlaylist,
      confirmLabel: context.l10n.rename,
      initialName: playlist.name,
    );
    if (!mounted || name == null || name.isEmpty || name == playlist.name) {
      return;
    }
    try {
      await client.renamePlaylist(playlist.id, name);
      if (!mounted) return;
      context.read<PlaylistUpdates>().notifyChanged();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(context.l10n.renamedPlaylist(name))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(localizeMessage(context.l10n, describeError(error))),
        ),
      );
    }
  }

  Future<void> _delete(Playlist playlist) async {
    final client = context.read<SessionController>().client;
    if (client == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.deletePlaylist),
          content: Text(
            context.l10n.deletePlaylistBody(playlist.name),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.cancel),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.danger),
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(context.l10n.delete),
            ),
          ],
        );
      },
    );
    if (!mounted || confirmed != true) return;
    try {
      await client.deletePlaylist(playlist.id);
      if (!mounted) return;
      context.read<PlaylistUpdates>().notifyChanged();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text(context.l10n.deletedPlaylist(playlist.name))),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(localizeMessage(context.l10n, describeError(error))),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final updates = context.watch<PlaylistUpdates>().generation;
    if (updates != _seenUpdates) {
      _seenUpdates = updates;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _load();
      });
    }
    if (_loading && _playlists.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _playlists.isEmpty) {
      return MessagePage(
        icon: Icons.cloud_off_rounded,
        title: context.l10n.playlistsUnavailable,
        detail: _error,
        onRetry: _load,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _playlists.isEmpty ? 2 : _playlists.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return CreatePlaylistTile(busy: _creating, onTap: _create);
          }
          if (_playlists.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 48),
              child: MessagePage(
                icon: Icons.queue_music_outlined,
                title: context.l10n.noPlaylists,
                detail: context.l10n.noPlaylistsDetail,
              ),
            );
          }
          final playlist = _playlists[index - 1];
          return Builder(
            builder: (tileContext) {
              return ListTile(
                leading: SizedBox(
                  width: 48,
                  height: 48,
                  child: CoverImage(
                    url: tileContext
                        .read<SessionController>()
                        .client
                        ?.coverUri(playlist.artworkId, size: 160)
                        ?.toString(),
                    icon: Icons.queue_music_rounded,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                title: Text(
                  playlist.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  formatTrackCount(context.l10n, playlist.songCount),
                ),
                onTap: () => openPlaylist(tileContext, playlist),
                onLongPress: () => _openMenu(playlist, tileContext),
              );
            },
          );
        },
      ),
    );
  }
}
