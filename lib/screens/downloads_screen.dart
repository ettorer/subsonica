import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/download.dart';
import '../state/downloads.dart';
import '../state/player_controller.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import '../util/format.dart';
import '../widgets/choice_menu.dart';
import '../widgets/cover_image.dart';
import '../widgets/message_page.dart';
import '../widgets/mini_player.dart';
import 'now_playing_screen.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final downloads = context.watch<DownloadController>();
    final entries = downloads.entries;
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.downloadsTitle),
        actions: [
          if (entries.isNotEmpty)
            IconButton(
              tooltip: context.l10n.options,
              onPressed: () => _openDownloadsMenu(context),
              icon: const Icon(Icons.more_vert_rounded),
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: entries.isEmpty
                ? MessagePage(
                    icon: Icons.download_rounded,
                    title: context.l10n.noDownloads,
                    detail: context.l10n.noDownloadsDetail,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 16),
                    itemCount: entries.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                          child: Text(
                            context.l10n.onThisPhone(
                              formatByteSize(downloads.byteCount),
                            ),
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        );
                      }
                      return _DownloadRow(entry: entries[index - 1]);
                    },
                  ),
          ),
          const MiniPlayerSlot(),
        ],
      ),
    );
  }
}

Future<void> _openDownloadsMenu(BuildContext context) async {
  final downloads = context.read<DownloadController>();
  final complete = [
    for (final item in downloads.entries)
      if (item.isComplete) item.song,
  ];
  final value = await showChoiceMenu(context, [
    MenuChoice(
      value: 'play',
      icon: Icons.play_arrow_rounded,
      label: context.l10n.playAll,
      enabled: complete.isNotEmpty,
    ),
    MenuChoice(
      value: 'random',
      icon: Icons.shuffle_rounded,
      label: context.l10n.randomPlay,
      enabled: complete.isNotEmpty,
    ),
    MenuChoice(
      value: 'delete',
      icon: Icons.delete_outline_rounded,
      label: context.l10n.deleteAll,
    ),
  ]);
  if (value == null || !context.mounted) return;
  switch (value) {
    case 'play':
      openNowPlaying(context);
      context.read<PlayerController>().playSongs(
        complete,
        startIndex: 0,
        shuffle: false,
        queueTitle: context.l10n.downloadsTitle,
      );
    case 'random':
      openNowPlaying(context);
      context.read<PlayerController>().playSongs(
        complete,
        startIndex: 0,
        shuffle: true,
        queueTitle: context.l10n.downloadsTitle,
      );
    case 'delete':
      await _confirmDeleteAll(context);
  }
}

Future<void> _confirmDeleteAll(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(context.l10n.deleteAllDownloadsTitle),
        content: Text(context.l10n.deleteAllDownloadsBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) return;
  final downloads = context.read<DownloadController>();
  final ids = [for (final entry in downloads.entries) entry.song.id];
  for (final id in ids) {
    await downloads.removeSong(id);
  }
}

class _DownloadRow extends StatelessWidget {
  const _DownloadRow({required this.entry});

  final DownloadEntry entry;

  @override
  Widget build(BuildContext context) {
    final song = entry.song;
    final downloads = context.watch<DownloadController>();
    final client = context.read<SessionController>().client;
    final coverFile = downloads.coverFile(song.artworkId);
    final coverUrl = coverFile == null
        ? client?.coverUri(song.artworkId, size: 200)?.toString()
        : null;
    final total = entry.total;
    final progress = entry.status == DownloadStatus.downloading &&
            total != null &&
            total > 0
        ? entry.received / total
        : null;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
      minLeadingWidth: 48,
      leading: SizedBox(
        width: 48,
        height: 48,
        child: CoverImage(
          url: coverUrl,
          filePath: coverFile,
          icon: Icons.music_note_rounded,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${displayName(context.l10n, song.artist)} · ${_detail(context, entry)}',
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: AppColors.muted),
      ),
      isThreeLine: progress != null,
      onTap: entry.isComplete ? () => _play(context) : null,
      trailing: _actions(context),
    );
  }

  void _play(BuildContext context) {
    final songs = [
      for (final item in context.read<DownloadController>().entries)
        if (item.isComplete) item.song,
    ];
    final index = songs.indexWhere((song) => song.id == entry.song.id);
    openNowPlaying(context);
    context.read<PlayerController>().playSongs(
      songs,
      startIndex: index < 0 ? 0 : index,
      shuffle: false,
      queueTitle: context.l10n.downloadsTitle,
    );
  }

  Future<void> _confirmRemove(BuildContext context) async {
    final song = entry.song;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(context.l10n.removeDownloadTitle),
          content: Text(context.l10n.removeDownloadBody(song.title)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(context.l10n.cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(context.l10n.remove),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    await context.read<DownloadController>().removeSong(song.id);
  }

  Widget _actions(BuildContext context) {
    final downloads = context.read<DownloadController>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (entry.status == DownloadStatus.failed)
          IconButton(
            tooltip: context.l10n.tryAgain,
            onPressed: () => downloads.retry(entry.song.id),
            icon: const Icon(Icons.refresh_rounded),
          ),
        if (progressValue != null)
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(
              value: progressValue,
              strokeWidth: 2.4,
            ),
          )
        else if (entry.status == DownloadStatus.downloading ||
            entry.status == DownloadStatus.queued)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        IconButton(
          tooltip: context.l10n.removeDownload,
          onPressed: () => _confirmRemove(context),
          icon: const Icon(Icons.delete_outline_rounded),
        ),
      ],
    );
  }

  double? get progressValue {
    final total = entry.total;
    if (entry.status != DownloadStatus.downloading ||
        total == null ||
        total <= 0) {
      return null;
    }
    return (entry.received / total).clamp(0, 1);
  }

  String _detail(BuildContext context, DownloadEntry entry) {
    return switch (entry.status) {
      DownloadStatus.queued => context.l10n.waiting,
      DownloadStatus.downloading => _progressLabel(entry),
      DownloadStatus.complete => formatByteSize(entry.byteSize),
      DownloadStatus.failed => localizeMessage(
        context.l10n,
        entry.error ?? 'Download failed',
      ),
    };
  }

  String _progressLabel(DownloadEntry entry) {
    final total = entry.total;
    if (total == null || total <= 0) return formatByteSize(entry.received);
    return '${formatByteSize(entry.received)} / ${formatByteSize(total)}';
  }
}
