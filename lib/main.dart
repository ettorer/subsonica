import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:provider/provider.dart';

import 'l10n/context_l10n.dart';
import 'screens/gate.dart';
import 'services/settings_store.dart';
import 'state/downloads.dart';
import 'state/favorite_updates.dart';
import 'state/karaoke.dart';
import 'state/locale_controller.dart';
import 'state/player_controller.dart';
import 'state/playlist_updates.dart';
import 'state/rating_updates.dart';
import 'state/session_controller.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    await JustAudioBackground.init(
      androidNotificationChannelId: 'com.subsonica.subsonica.audio',
      androidNotificationChannelName: 'Playback',
      androidNotificationChannelDescription: 'Playback controls',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
      androidNotificationIcon: 'drawable/ic_stat_subsonica',
      notificationColor: AppColors.accent,
      artDownscaleWidth: 512,
      artDownscaleHeight: 512,
      preloadArtwork: true,
    );
  }
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
      systemNavigationBarColor: AppColors.background,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );
  final settings = SettingsStore();
  final localePreference = await settings.loadLocale();
  runApp(SubsonicaApp(settings: settings, localePreference: localePreference));
}

class SubsonicaApp extends StatefulWidget {
  const SubsonicaApp({
    super.key,
    required this.settings,
    required this.localePreference,
  });

  final SettingsStore settings;
  final String localePreference;

  @override
  State<SubsonicaApp> createState() => _SubsonicaAppState();
}

class _SubsonicaAppState extends State<SubsonicaApp> {
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();
  late final SettingsStore _settings;
  late final LocaleController _locale;
  late final SessionController _session;
  late final PlayerController _player;
  late final DownloadController _downloads;
  late final FavoriteUpdates _favorites;
  late final PlaylistUpdates _playlists;
  late final RatingUpdates _ratings;
  late final KaraokeController _karaoke;
  var _shownErrorId = 0;

  @override
  void initState() {
    super.initState();
    _settings = widget.settings;
    _locale = LocaleController(_settings, widget.localePreference);
    _session = SessionController(_settings);
    _player = PlayerController();
    _downloads = DownloadController(_settings);
    _player.bindLibrary(_downloads);
    _favorites = FavoriteUpdates();
    _playlists = PlaylistUpdates();
    _ratings = RatingUpdates();
    _karaoke = KaraokeController(
      _settings,
      _player,
      _downloads,
      () => _session.client,
    );
    unawaited(_karaoke.restore());
    _session.addListener(_onSession);
    _player.addListener(_onPlayer);
    _downloads.init();
    _session.bootstrap();
  }

  void _onSession() {
    _player.attach(_session.client);
    _downloads.attach(_session.client);
  }

  void _onPlayer() {
    final message = _player.error;
    final id = _player.errorId;
    if (message == null || id == _shownErrorId) return;
    _shownErrorId = id;
    final messenger = _messengerKey.currentState;
    final context = _messengerKey.currentContext;
    if (messenger == null || context == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(content: Text(localizeMessage(context.l10n, message))),
      );
  }

  @override
  void dispose() {
    _session.removeListener(_onSession);
    _player.removeListener(_onPlayer);
    _session.dispose();
    _locale.dispose();
    _player.dispose();
    _downloads.dispose();
    _favorites.dispose();
    _playlists.dispose();
    _ratings.dispose();
    _karaoke.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<LocaleController>.value(value: _locale),
        ChangeNotifierProvider<SessionController>.value(value: _session),
        ChangeNotifierProvider<PlayerController>.value(value: _player),
        ChangeNotifierProvider<DownloadController>.value(value: _downloads),
        ChangeNotifierProvider<FavoriteUpdates>.value(value: _favorites),
        ChangeNotifierProvider<PlaylistUpdates>.value(value: _playlists),
        ChangeNotifierProvider<RatingUpdates>.value(value: _ratings),
        ChangeNotifierProvider<KaraokeController>.value(value: _karaoke),
      ],
      child: Builder(
        builder: (context) {
          return MaterialApp(
            title: 'Subsonica',
            debugShowCheckedModeBanner: false,
            theme: buildAppTheme(),
            locale: context.watch<LocaleController>().locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            scaffoldMessengerKey: _messengerKey,
            builder: (context, child) {
              final page = child ?? const SizedBox.shrink();
              if (!context.watch<KaraokeController>().active) return page;
              return Stack(
                children: [
                  page,
                  const Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border.fromBorderSide(
                            BorderSide(color: AppColors.remote, width: 4),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Positioned(
                    right: 10,
                    bottom: 8,
                    child: IgnorePointer(
                      child: Icon(
                        Icons.cast_connected_rounded,
                        color: AppColors.remote,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              );
            },
            home: const Gate(),
          );
        },
      ),
    );
  }
}
