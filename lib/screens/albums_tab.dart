import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/library.dart';
import '../services/subsonic_api.dart';
import '../state/session_controller.dart';
import '../widgets/album_card.dart';
import '../widgets/message_page.dart';
import 'collection_screen.dart';

class AlbumsTab extends StatefulWidget {
  const AlbumsTab({super.key});

  @override
  State<AlbumsTab> createState() => _AlbumsTabState();
}

class _AlbumsTabState extends State<AlbumsTab> {
  final _albums = <Album>[];
  var _loading = true;
  var _loadingMore = false;
  var _hasMore = true;
  var _request = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(reset: true));
  }

  Future<void> _load({required bool reset}) async {
    if (!reset && (_loading || _loadingMore || !_hasMore)) return;
    final client = context.read<SessionController>().client;
    if (client == null) return;
    final request = ++_request;
    setState(() {
      if (reset) {
        _loading = true;
        _error = null;
      } else {
        _loadingMore = true;
      }
    });
    try {
      final page = await client.getAlbums(offset: reset ? 0 : _albums.length);
      if (!mounted || request != _request) return;
      setState(() {
        if (reset) _albums.clear();
        _albums.addAll(page);
        _hasMore = page.length >= SubsonicClient.albumPageSize;
        _loading = false;
        _loadingMore = false;
      });
    } catch (error) {
      if (!mounted || request != _request) return;
      setState(() {
        _error = describeError(error);
        _loading = false;
        _loadingMore = false;
      });
    }
  }

  bool _onScroll(ScrollNotification notification) {
    if (notification.metrics.pixels >
        notification.metrics.maxScrollExtent - 480) {
      _load(reset: false);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _albums.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _albums.isEmpty) {
      return MessagePage(
        icon: Icons.cloud_off_rounded,
        title: context.l10n.albumsUnavailable,
        detail: localizeMessage(context.l10n, _error!),
        onRetry: () => _load(reset: true),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final cross = albumCrossCount(constraints.maxWidth);
        return RefreshIndicator(
          onRefresh: () => _load(reset: true),
          child: NotificationListener<ScrollNotification>(
            onNotification: _onScroll,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                if (_albums.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: MessagePage(
                      icon: Icons.album_outlined,
                      title: context.l10n.noAlbums,
                      detail: context.l10n.noAlbumsYet,
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    sliver: SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
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
                          album: _albums[index],
                          onTap: () => openAlbum(context, _albums[index]),
                        ),
                        childCount: _albums.length,
                      ),
                    ),
                  ),
                if (_loadingMore)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                const SliverPadding(padding: EdgeInsets.only(bottom: 12)),
              ],
            ),
          ),
        );
      },
    );
  }
}
