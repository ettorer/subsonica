import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/library.dart';
import '../services/subsonic_api.dart';
import '../state/session_controller.dart';
import '../l10n/context_l10n.dart';
import '../theme/app_colors.dart';
import '../util/format.dart';
import '../widgets/message_page.dart';
import 'collection_screen.dart';

class GenresTab extends StatefulWidget {
  const GenresTab({super.key});

  @override
  State<GenresTab> createState() => _GenresTabState();
}

class _GenresTabState extends State<GenresTab> {
  List<Genre> _genres = const [];
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
      _loading = _genres.isEmpty;
      _error = null;
    });
    try {
      final genres = await client.getGenres();
      if (!mounted) return;
      setState(() {
        _genres = genres;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = describeError(error);
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _genres.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _genres.isEmpty) {
      return MessagePage(
        icon: Icons.cloud_off_rounded,
        title: context.l10n.genresUnavailable,
        detail: localizeMessage(context.l10n, _error!),
        onRetry: _load,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: _genres.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 120),
                MessagePage(
                  icon: Icons.sell_outlined,
                  title: context.l10n.noGenres,
                  detail: context.l10n.noGenreTags,
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              itemCount: _genres.length,
              itemBuilder: (context, index) {
                final genre = _genres[index];
                return ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.surfaceHigh,
                    foregroundColor: AppColors.accent,
                    child: Icon(Icons.sell_rounded, size: 18),
                  ),
                  title: Text(genre.name),
                  subtitle: Text(
                    '${formatTrackCount(context.l10n, genre.songCount)} · ${formatAlbumCount(context.l10n, genre.albumCount)}',
                  ),
                  onTap: () => openGenre(context, genre),
                );
              },
            ),
    );
  }
}
