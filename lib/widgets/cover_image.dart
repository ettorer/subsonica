import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'cover_file.dart';

bool serverArtwork(String? artworkId) {
  if (artworkId == null || artworkId.isEmpty) return false;
  return !artworkId.startsWith('phone-');
}

class CoverImage extends StatelessWidget {
  const CoverImage({
    super.key,
    required this.url,
    required this.icon,
    this.filePath,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  final String? url;
  final String? filePath;
  final IconData icon;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A3428), Color(0xFF1C212B)],
          ),
        ),
        child: _picture(),
      ),
    );
  }

  Widget _picture() {
    final path = filePath;
    if (path != null) return localCoverImage(path, icon: icon);
    final imageUrl = url;
    if (imageUrl == null) return _Placeholder(icon: icon);
    return LayoutBuilder(
      builder: (context, constraints) {
        final cacheWidth =
            (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                .round();
        return CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          memCacheWidth: cacheWidth > 0 ? cacheWidth : null,
          fadeInDuration: const Duration(milliseconds: 120),
          fadeOutDuration: const Duration(milliseconds: 80),
          placeholder: (context, _) => _Placeholder(icon: icon),
          errorWidget: (context, _, _) => _Placeholder(icon: icon),
        );
      },
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(child: Icon(icon, color: AppColors.accent, size: 42));
  }
}
