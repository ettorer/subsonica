import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';

class LibraryTabBar extends StatelessWidget {
  const LibraryTabBar({
    super.key,
    required this.index,
    required this.onSelected,
    required this.items,
  });

  final int index;
  final ValueChanged<int> onSelected;
  final List<(IconData, IconData, String)> items;

  static List<(IconData, IconData, String)> onlineItems(AppLocalizations l10n) {
    return [
      (Icons.home_outlined, Icons.home_rounded, l10n.tabHome),
      ...libraryItems(l10n),
    ];
  }

  static List<(IconData, IconData, String)> libraryItems(
    AppLocalizations l10n,
  ) {
    return [
      (Icons.album_outlined, Icons.album_rounded, l10n.tabAlbum),
      (Icons.music_note_outlined, Icons.music_note_rounded, l10n.tabTrack),
      (Icons.person_outline_rounded, Icons.person_rounded, l10n.tabArtist),
      (Icons.sell_outlined, Icons.sell_rounded, l10n.tabGenre),
      (Icons.queue_music_outlined, Icons.queue_music_rounded, l10n.tabPlaylist),
      (
        Icons.favorite_border_rounded,
        Icons.favorite_rounded,
        l10n.tabFavorites,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.outline)),
      ),
      child: SizedBox(
        height: 58,
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _Tab(
                  selected: i == index,
                  icon: i == index ? items[i].$2 : items[i].$1,
                  label: items[i].$3,
                  onTap: () => onSelected(i),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.selected,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final bool selected;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.accent : AppColors.muted;
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
