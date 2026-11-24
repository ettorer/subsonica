import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/library.dart';
import '../state/library_tabs.dart';
import 'library_tab_bar.dart';
import 'mini_player.dart';

class ShellPlaybackBar extends StatelessWidget {
  const ShellPlaybackBar({super.key, this.onTrackTap});

  final ValueChanged<Song>? onTrackTap;

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return const MiniPlayerSlot();
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MiniPlayerSlot(
            safeBottom: false,
            transport: true,
            onTrackTap: onTrackTap,
          ),
          LibraryTabBar(
            index: context.watch<LibraryTabs>().index,
            items: LibraryTabBar.onlineItems(context.l10n),
            onSelected: (index) => goToLibraryTab(context, index),
          ),
        ],
      ),
    );
  }
}
