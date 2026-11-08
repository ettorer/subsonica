import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_lyric/flutter_lyric.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/library.dart';
import '../services/lyrics_client.dart';
import '../state/downloads.dart';
import '../state/lyric_progress.dart';
import '../state/player_controller.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/cover_image.dart';
import '../widgets/playback_slider.dart';

void openLyrics(BuildContext context) {
  Navigator.of(context)
      .push(MaterialPageRoute<void>(builder: (_) => const LyricsScreen()));
}

class LyricsScreen extends StatefulWidget {
  const LyricsScreen({super.key});

  @override
  State<LyricsScreen> createState() => _LyricsScreenState();
}

class _LyricsScreenState extends State<LyricsScreen> {
  static const _unset = Object();

  late final LyricsClient _client;
  late final PlayerLyricProgress _progress;
  late final LyricController _controller;
  Object? _songId = _unset;
  var _generation = 0;
  var _loading = true;
  String? _error;
  LyricMatch? _match;

  static final _preset = LyricPresets.appleMusic.copyWith(
    highlight: const LyricHighlight.solid(AppColors.accent, tailFadeWidth: 12),
    textStyle: TextStyle(
      fontSize: kIsWeb ? 24 : 18,
      fontWeight: FontWeight.w500,
      height: 1.28,
      color: const Color(0xD9F6F3EC),
    ),
    activeTextStyle: TextStyle(
      fontSize: kIsWeb ? 26 : 20,
      fontWeight: FontWeight.w700,
      height: 1.28,
      color: AppColors.text,
    ),
    textAlign: TextAlign.center,
    contentAlignment: LyricContentAlignment.center,
    padding: const EdgeInsets.symmetric(horizontal: 20),
    lineSpacing: 12,
    activeAnchor: const LyricAnchor.fraction(
      .5,
      target: LyricAnchorTarget.mainText,
    ),
    selectionAnchor: const LyricAnchor.fraction(
      .5,
      target: LyricAnchorTarget.mainText,
    ),
    edgeFade: const LyricEdgeFade.fraction(top: .04, bottom: .05),
    distanceBlur: const LyricDistanceBlur(maxSigma: 0, whenBrowsing: false),
    lineMotion: const LyricLineMotion(waveAmplitude: 0),
    wordEffects: const LyricWordEffects(simulateTiming: true),
  );

  @override
  void initState() {
    super.initState();
    _client = LyricsClient();
    _progress = PlayerLyricProgress(context.read<PlayerController>());
    _controller = LyricController(progressSource: _progress);
  }

  @override
  void dispose() {
    _controller.dispose();
    _progress.dispose();
    _client.close();
    super.dispose();
  }

  void _follow(Song? song) {
    final id = song?.id;
    if (id == _songId) return;
    _songId = id;
    final generation = ++_generation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load(song, generation);
    });
  }

  Future<void> _load(Song? song, int generation) async {
    if (!mounted || generation != _generation) return;
    _controller.clear();
    if (song == null) {
      setState(() {
        _loading = false;
        _match = null;
        _error = null;
      });
      return;
    }
    setState(() {
      _loading = true;
      _match = null;
      _error = null;
    });
    try {
      final downloads = context.read<DownloadController>();
      final server = context.read<SessionController>().client;
      final saved = await downloads.savedLyrics(song.id);
      if (!mounted || generation != _generation) return;
      final match =
          saved ??
          await _client.find(
            song,
            serverLyrics: server == null
                ? null
                : () => server.songLyrics(song.id),
          );
      if (!mounted || generation != _generation) return;
      if (saved == null) await downloads.saveLyrics(song.id, match);
      if (!mounted || generation != _generation) return;
      if (match.synced && match.lrc.trim().isNotEmpty) {
        _controller.load(match.lrc);
      }
      setState(() {
        _loading = false;
        _match = match;
      });
    } on LyricsException catch (error) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _loading = false;
        _error = 'Lyrics are unavailable right now.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final player = context.watch<PlayerController>();
    final song = player.lyricsTrack;
    _follow(song);
    final client = context.read<SessionController>().client;
    final downloads = context.read<DownloadController>();
    final coverFile = downloads.coverFile(song?.artworkId);
    final coverUrl = coverFile == null
        ? client?.coverUri(song?.artworkId, size: 800)?.toString()
        : null;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          tooltip: context.l10n.close,
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
        ),
        centerTitle: true,
        title: Text(context.l10n.lyrics),
        actions: [
          if (player.canSwitchMusicOnly)
            IconButton(
              tooltip: player.musicOnly
                  ? context.l10n.withVocals
                  : context.l10n.musicOnly,
              onPressed: player.toggleMusicOnly,
              color: player.musicOnly ? AppColors.accent : null,
              icon: Icon(
                player.musicOnly ? Icons.mic_off_rounded : Icons.mic_rounded,
              ),
            ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (coverFile != null || coverUrl != null)
            _Backdrop(url: coverUrl, filePath: coverFile),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
                  child: Column(
                    children: [
                      Text(
                        song?.title ?? context.l10n.nothingPlaying,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      if (song != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          displayName(context.l10n, song.artist),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.muted),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(child: _body(player)),
                if (_caption != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                    child: Text(
                      _caption!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.muted),
                    ),
                  ),
                _plain
                    ? Padding(
                        padding: const EdgeInsets.fromLTRB(4, 0, 8, 4),
                        child: Row(
                          children: [
                            _playButton(player, song),
                            const Expanded(child: PlaybackSlider()),
                          ],
                        ),
                      )
                    : _playButton(player, song),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String? get _caption {
    final match = _match;
    if (match == null || !match.found || match.instrumental) return null;
    return match.source;
  }

  bool get _plain {
    final match = _match;
    return match != null &&
        match.found &&
        !match.instrumental &&
        !match.synced &&
        match.plain.trim().isNotEmpty;
  }

  Widget _playButton(PlayerController player, Song? song) {
    return IconButton(
      tooltip: player.playing ? context.l10n.pause : context.l10n.play,
      onPressed: song == null ? null : player.togglePlayPause,
      iconSize: 36,
      color: AppColors.accent,
      icon: Icon(
        player.playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
      ),
    );
  }

  Widget _body(PlayerController player) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.accent),
      );
    }
    if (_error != null) {
      return _message(localizeMessage(context.l10n, _error!));
    }
    final match = _match;
    if (player.current == null) {
      return _message(context.l10n.nothingPlaying);
    }
    if (match == null || !match.found) {
      return _message(context.l10n.noLyricsFound);
    }
    if (match.instrumental) {
      return _message(context.l10n.instrumental);
    }
    if (!match.synced) {
      return _PlainLyrics(text: match.plain);
    }
    return LyricView(
      controller: _controller,
      preset: _preset,
      onLineTap: (details) {
        final time = details.line.start;
        player.seek(time < Duration.zero ? Duration.zero : time);
        if (!player.playing) player.togglePlayPause();
      },
    );
  }

  Widget _message(String text) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleMedium
              ?.copyWith(color: AppColors.muted),
        ),
      ),
    );
  }
}

class _PlainLyrics extends StatelessWidget {
  const _PlainLyrics({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: (constraints.maxHeight - 20).clamp(0, double.infinity),
            ),
            child: Center(
              child: Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: kIsWeb ? 24 : 18,
                  fontWeight: FontWeight.w600,
                  height: 1.45,
                  color: AppColors.text,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.url, required this.filePath});

  final String? url;
  final String? filePath;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 32, sigmaY: 32),
            child: Transform.scale(
              scale: 1.2,
              child: CoverImage(
                url: url,
                filePath: filePath,
                icon: Icons.music_note_rounded,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x990E1014),
                  Color(0xE60E1014),
                  AppColors.background,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
