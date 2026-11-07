import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/library.dart';
import '../services/subsonic_api.dart';
import '../state/session_controller.dart';
import '../l10n/context_l10n.dart';
import '../theme/app_colors.dart';
import '../util/format.dart';
import '../widgets/message_page.dart';
import 'artist_screen.dart';

class ArtistsTab extends StatefulWidget {
  const ArtistsTab({super.key});

  @override
  State<ArtistsTab> createState() => _ArtistsTabState();
}

class _ArtistsTabState extends State<ArtistsTab> {
  List<ArtistSection> _sections = const [];
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
      _loading = _sections.isEmpty;
      _error = null;
    });
    try {
      final sections = await client.getArtists();
      if (!mounted) return;
      setState(() {
        _sections = sections;
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
    if (_loading && _sections.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _sections.isEmpty) {
      return MessagePage(
        icon: Icons.cloud_off_rounded,
        title: context.l10n.artistsUnavailable,
        detail: localizeMessage(context.l10n, _error!),
        onRetry: _load,
      );
    }
    if (_sections.isEmpty) {
      return MessagePage(
        icon: Icons.person_outline_rounded,
        title: context.l10n.noArtists,
        detail: context.l10n.noArtistsYet,
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          for (final section in _sections) ...[
            SliverPersistentHeader(
              pinned: true,
              delegate: _LetterHeader(section.letter),
            ),
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final artist = section.artists[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.surfaceHigh,
                    foregroundColor: AppColors.accent,
                    child: Text(
                      artist.name.characters.first.toUpperCase(),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  title: Text(
                    artist.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    formatAlbumCount(context.l10n, artist.albumCount),
                  ),
                  onTap: () => openArtist(context, artist),
                );
              }, childCount: section.artists.length),
            ),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: 12)),
        ],
      ),
    );
  }
}

class _LetterHeader extends SliverPersistentHeaderDelegate {
  const _LetterHeader(this.letter);

  final String letter;

  @override
  double get minExtent => 32;

  @override
  double get maxExtent => 32;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return ColoredBox(
      color: AppColors.background,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            letter,
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(_LetterHeader oldDelegate) => oldDelegate.letter != letter;
}
