import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/download.dart';
import '../models/library.dart';
import '../services/subsonic_api.dart';
import '../state/download_controller.dart';
import '../state/player_controller.dart';
import '../state/rating_updates.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/rating_bar.dart';

void openPlaybackSpeed(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surface,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const PlaybackSpeedSheet(),
  );
}

class PlaybackSpeedSheet extends StatefulWidget {
  const PlaybackSpeedSheet({super.key});

  @override
  State<PlaybackSpeedSheet> createState() => _PlaybackSpeedSheetState();
}

class _PlaybackSpeedSheetState extends State<PlaybackSpeedSheet> {
  static const _min = 0.5;
  static const _max = 2.0;
  static const _presets = [0.7, 0.85, 1.0, 1.25, 1.5];
  static const _valueWidth = 44.0;
  double? _drag;
  var _startingRadio = false;
  String? _radioMessage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final player = context.watch<PlayerController>();
    final downloads = context.watch<DownloadController>();
    final offline = downloads.preferOffline;
    final connected = context.watch<SessionController>().client != null;
    final song = player.current;
    final speed = (_drag ?? player.speed).clamp(_min, _max);
    final entry = song == null ? null : downloads.entryFor(song.id);
    final downloaded = entry?.isComplete == true;
    final inProgress =
        entry?.status == DownloadStatus.queued ||
        entry?.status == DownloadStatus.downloading;
    final bottom = MediaQuery.paddingOf(context).bottom;
    final canStartRadio =
        connected && !offline && player.current != null && !_startingRadio;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 16, 12 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              l10n.speed,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.speed_rounded, color: AppColors.muted),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 2,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 6,
                    ),
                    overlayShape: const RoundSliderOverlayShape(
                      overlayRadius: 14,
                    ),
                    activeTrackColor: AppColors.accent,
                    inactiveTrackColor: AppColors.outline,
                    thumbColor: AppColors.accent,
                    overlayColor: AppColors.accent.withValues(alpha: 0.18),
                  ),
                  child: Slider(
                    value: speed,
                    min: _min,
                    max: _max,
                    onChanged: (next) {
                      final snapped = _snap(next);
                      setState(() => _drag = snapped);
                      context.read<PlayerController>().setSpeed(snapped);
                    },
                    onChangeEnd: (next) {
                      context.read<PlayerController>().setSpeed(_snap(next));
                      setState(() => _drag = null);
                    },
                  ),
                ),
              ),
              Container(
                width: _valueWidth,
                height: 26,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  speed.toStringAsFixed(2),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 24,
              right: _valueWidth,
              top: 2,
            ),
            child: Row(
              children: [
                for (var i = 0; i < _presets.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Expanded(
                    child: _SpeedPreset(
                      label: _presets[i] == 1 ? '1' : _presets[i].toString(),
                      selected: (speed - _presets[i]).abs() < 0.001,
                      onPressed: () {
                        setState(() => _drag = null);
                        context.read<PlayerController>().setSpeed(_presets[i]);
                      },
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (song != null) ...[
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.outline),
            Padding(
              padding: const EdgeInsets.only(left: 8, top: 12),
              child: Text(
                l10n.rating,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            RatingBar(
              rating: context.watch<RatingUpdates>().songRating(song),
              onChanged: (next) => _rateSong(song, next),
            ),
            const Divider(height: 1, color: AppColors.outline),
            DownloadSheetTile(
              downloaded: downloaded,
              label: downloaded
                  ? l10n.removeDownload
                  : inProgress
                  ? l10n.cancelDownload
                  : l10n.download,
              onPressed: () => _downloadSong(song, entry?.status),
            ),
          ],
          const Divider(height: 1, color: AppColors.outline),
          ListTile(
            contentPadding: const EdgeInsets.only(left: 8, right: 8),
            enabled: canStartRadio,
            leading: _startingRadio
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  )
                : Icon(
                    Icons.radio_rounded,
                    color: canStartRadio ? AppColors.text : AppColors.muted,
                  ),
            title: Text(l10n.startRadio),
            subtitle: Text(
              offline ? l10n.radioOffline : l10n.radioDetail,
              style: const TextStyle(color: AppColors.muted),
            ),
            onTap: canStartRadio ? _startRadio : null,
          ),
          if (_radioMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: Text(
                _radioMessage!,
                style: const TextStyle(color: AppColors.danger, height: 1.35),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _rateSong(Song song, int next) async {
    final ratings = context.read<RatingUpdates>();
    final previous = ratings.songRating(song);
    if (next == previous) return;
    final client = context.read<SessionController>().client;
    if (client == null) {
      _snack(context.l10n.connectToRate);
      return;
    }
    ratings.setSong(song.id, next);
    try {
      await client.setRating(song.id, next);
    } catch (error) {
      ratings.setSong(song.id, previous);
      if (!mounted) return;
      _snack(localizeMessage(context.l10n, describeError(error)));
    }
  }

  Future<void> _downloadSong(Song song, DownloadStatus? status) async {
    final downloads = context.read<DownloadController>();
    if (status == DownloadStatus.complete) {
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
      if (confirmed != true || !mounted) return;
      await context.read<DownloadController>().removeSong(song.id);
      return;
    }
    if (status == DownloadStatus.queued ||
        status == DownloadStatus.downloading) {
      await downloads.removeSong(song.id);
      return;
    }
    if (context.read<SessionController>().client == null) {
      _snack(context.l10n.connectToDownload);
      return;
    }
    final added = await downloads.enqueue([song]);
    if (!mounted) return;
    _snack(
      added == 0
          ? context.l10n.trackAlreadyDownloaded
          : context.l10n.downloading,
    );
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _startRadio() async {
    final song = context.read<PlayerController>().current;
    final client = context.read<SessionController>().client;
    if (song == null || client == null) return;
    setState(() {
      _startingRadio = true;
      _radioMessage = null;
    });
    try {
      final similar = await client.getSimilarSongs(song.id);
      if (!mounted) return;
      final started = await context.read<PlayerController>().startRadio(
        similar,
      );
      if (!mounted) return;
      if (!started) {
        final failure = context.read<PlayerController>().error;
        setState(() {
          _startingRadio = false;
          _radioMessage = failure == null
              ? context.l10n.radioEmpty
              : localizeMessage(context.l10n, failure);
        });
        return;
      }
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _startingRadio = false;
        _radioMessage = localizeMessage(context.l10n, describeError(error));
      });
    }
  }

  double _snap(double speed) {
    final steps = ((speed - _min) / 0.01).round();
    return (_min + steps * 0.01).clamp(_min, _max);
  }
}

class _SpeedPreset extends StatelessWidget {
  const _SpeedPreset({
    required this.label,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.accent : AppColors.surfaceHigh,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.onAccent : AppColors.text,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
