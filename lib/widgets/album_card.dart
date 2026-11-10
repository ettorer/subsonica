import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/library.dart';
import '../state/downloads.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import 'cover_image.dart';

class AlbumCard extends StatelessWidget {
  const AlbumCard({super.key, required this.album, required this.onTap});

  final Album album;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final client = context.read<SessionController>().client;
    final file = context.read<DownloadController>().coverFile(album.artworkId);
    final cover = file == null && serverArtwork(album.artworkId)
        ? client?.coverUri(album.artworkId, size: 480)?.toString()
        : null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CoverImage(
                url: cover,
                filePath: file,
                icon: Icons.album_rounded,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              album.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(
              album.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

int albumCrossCount(double width) {
  if (kIsWeb) {
    final count = width ~/ 220;
    if (count < 2) return 2;
    return count;
  }
  if (width >= 1000) return 5;
  if (width >= 760) return 4;
  if (width >= 520) return 3;
  return 2;
}

double albumChildAspectRatio(double width, int crossCount) {
  const spacing = 14.0;
  const padding = 32.0;
  final tileWidth = (width - padding - (crossCount - 1) * spacing) / crossCount;
  if (tileWidth <= 0) return 0.72;
  return tileWidth / (tileWidth + 52);
}
