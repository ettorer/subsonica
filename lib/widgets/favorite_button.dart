import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/library.dart';
import '../services/subsonic_api.dart';
import '../state/favorite_updates.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';

class FavoriteButton extends StatefulWidget {
  const FavoriteButton({super.key, required this.song});

  final Song song;

  @override
  State<FavoriteButton> createState() => _FavoriteButtonState();
}

class _FavoriteButtonState extends State<FavoriteButton> {
  var _busy = false;

  Future<void> _toggle() async {
    final client = context.read<SessionController>().client;
    final updates = context.read<FavoriteUpdates>();
    if (client == null || _busy) return;
    final song = widget.song;
    final previous = updates.starredFor(song);
    final next = !previous;
    setState(() => _busy = true);
    updates.setStarred(song.id, next);
    try {
      await client.setStarred(song.id, starred: next);
    } catch (error) {
      updates.setStarred(song.id, previous);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(
            SnackBar(
              content: Text(localizeMessage(context.l10n, describeError(error))),
            ),
          );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final starred = context.watch<FavoriteUpdates>().starredFor(widget.song);
    return IconButton(
      tooltip: starred ? context.l10n.unfavorite : context.l10n.addToFavorites,
      onPressed: _busy ? null : _toggle,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints.tightFor(width: 44, height: 44),
      icon: Icon(
        starred ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        size: 22,
        color: starred ? AppColors.accent : AppColors.muted,
      ),
    );
  }
}
