import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_it.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('it'),
  ];

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @localeAutomatic.
  ///
  /// In en, this message translates to:
  /// **'Automatic'**
  String get localeAutomatic;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @logOut.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get logOut;

  /// No description provided for @offlineLabel.
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get offlineLabel;

  /// No description provided for @offlineMode.
  ///
  /// In en, this message translates to:
  /// **'Offline mode'**
  String get offlineMode;

  /// No description provided for @offlineModeDetail.
  ///
  /// In en, this message translates to:
  /// **'Play music saved on this phone'**
  String get offlineModeDetail;

  /// No description provided for @karaoke.
  ///
  /// In en, this message translates to:
  /// **'Karaoke'**
  String get karaoke;

  /// No description provided for @karaokeDetail.
  ///
  /// In en, this message translates to:
  /// **'Show the playing lyrics in a browser on this network.'**
  String get karaokeDetail;

  /// No description provided for @karaokeOpen.
  ///
  /// In en, this message translates to:
  /// **'Open this address in the browser.'**
  String get karaokeOpen;

  /// No description provided for @karaokeNoAddress.
  ///
  /// In en, this message translates to:
  /// **'Connect this phone to Wi-Fi, then turn Karaoke off and on.'**
  String get karaokeNoAddress;

  /// No description provided for @karaokeFailed.
  ///
  /// In en, this message translates to:
  /// **'The karaoke server could not start.'**
  String get karaokeFailed;

  /// No description provided for @downloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Downloads'**
  String get downloadsTitle;

  /// No description provided for @scanPhoneMusic.
  ///
  /// In en, this message translates to:
  /// **'Scan phone music'**
  String get scanPhoneMusic;

  /// No description provided for @scanPhoneMusicNow.
  ///
  /// In en, this message translates to:
  /// **'Scan phone music now'**
  String get scanPhoneMusicNow;

  /// No description provided for @scanPhoneMusicDetail.
  ///
  /// In en, this message translates to:
  /// **'Read albums and tracks from the Music folder on this phone.'**
  String get scanPhoneMusicDetail;

  /// No description provided for @scanningPhoneMusic.
  ///
  /// In en, this message translates to:
  /// **'Scanning the Music folder…'**
  String get scanningPhoneMusic;

  /// No description provided for @phoneMusicFound.
  ///
  /// In en, this message translates to:
  /// **'Found {count, plural, =1{1 track} other{{count} tracks}}.'**
  String phoneMusicFound(int count);

  /// No description provided for @phoneMusicEmpty.
  ///
  /// In en, this message translates to:
  /// **'No music files were found.'**
  String get phoneMusicEmpty;

  /// No description provided for @phoneMusicDenied.
  ///
  /// In en, this message translates to:
  /// **'Allow Subsonica to read music on this phone.'**
  String get phoneMusicDenied;

  /// No description provided for @phoneMusicFailed.
  ///
  /// In en, this message translates to:
  /// **'The phone music catalog could not be read.'**
  String get phoneMusicFailed;

  /// No description provided for @onThisPhone.
  ///
  /// In en, this message translates to:
  /// **'{size} on this phone'**
  String onThisPhone(String size);

  /// No description provided for @connectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get connectionsTitle;

  /// No description provided for @addConnection.
  ///
  /// In en, this message translates to:
  /// **'Add connection'**
  String get addConnection;

  /// No description provided for @connectedProfile.
  ///
  /// In en, this message translates to:
  /// **'{url} · Connected'**
  String connectedProfile(String url);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @tryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @lyrics.
  ///
  /// In en, this message translates to:
  /// **'Lyrics'**
  String get lyrics;

  /// No description provided for @musicOnly.
  ///
  /// In en, this message translates to:
  /// **'Music only'**
  String get musicOnly;

  /// No description provided for @withVocals.
  ///
  /// In en, this message translates to:
  /// **'With vocals'**
  String get withVocals;

  /// No description provided for @playQueue.
  ///
  /// In en, this message translates to:
  /// **'Play queue'**
  String get playQueue;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @nothingPlaying.
  ///
  /// In en, this message translates to:
  /// **'Nothing is playing'**
  String get nothingPlaying;

  /// No description provided for @previousTrack.
  ///
  /// In en, this message translates to:
  /// **'Previous track'**
  String get previousTrack;

  /// No description provided for @nextTrack.
  ///
  /// In en, this message translates to:
  /// **'Next track'**
  String get nextTrack;

  /// No description provided for @shuffle.
  ///
  /// In en, this message translates to:
  /// **'Shuffle'**
  String get shuffle;

  /// No description provided for @shuffleOn.
  ///
  /// In en, this message translates to:
  /// **'Shuffle on'**
  String get shuffleOn;

  /// No description provided for @loopOff.
  ///
  /// In en, this message translates to:
  /// **'Loop off'**
  String get loopOff;

  /// No description provided for @loopAlbum.
  ///
  /// In en, this message translates to:
  /// **'Loop album or playlist'**
  String get loopAlbum;

  /// No description provided for @loopTrack.
  ///
  /// In en, this message translates to:
  /// **'Loop this track'**
  String get loopTrack;

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now playing'**
  String get nowPlaying;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @speed.
  ///
  /// In en, this message translates to:
  /// **'Speed'**
  String get speed;

  /// No description provided for @startRadio.
  ///
  /// In en, this message translates to:
  /// **'Start radio'**
  String get startRadio;

  /// No description provided for @radioDetail.
  ///
  /// In en, this message translates to:
  /// **'Similar songs play after this track'**
  String get radioDetail;

  /// No description provided for @radioOffline.
  ///
  /// In en, this message translates to:
  /// **'Unavailable while offline'**
  String get radioOffline;

  /// No description provided for @radioEmpty.
  ///
  /// In en, this message translates to:
  /// **'This server has no similar songs for this track.'**
  String get radioEmpty;

  /// No description provided for @radio.
  ///
  /// In en, this message translates to:
  /// **'Radio'**
  String get radio;

  /// No description provided for @rating.
  ///
  /// In en, this message translates to:
  /// **'Rating'**
  String get rating;

  /// No description provided for @connectToRate.
  ///
  /// In en, this message translates to:
  /// **'Connect to set a rating.'**
  String get connectToRate;

  /// No description provided for @listenOffline.
  ///
  /// In en, this message translates to:
  /// **'Listen offline'**
  String get listenOffline;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @signIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// No description provided for @connectionSaved.
  ///
  /// In en, this message translates to:
  /// **'Connection saved'**
  String get connectionSaved;

  /// No description provided for @profileName.
  ///
  /// In en, this message translates to:
  /// **'Profile name'**
  String get profileName;

  /// No description provided for @profileNameHint.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get profileNameHint;

  /// No description provided for @serverUrl.
  ///
  /// In en, this message translates to:
  /// **'Server URL'**
  String get serverUrl;

  /// No description provided for @username.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get username;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @newConnection.
  ///
  /// In en, this message translates to:
  /// **'New connection'**
  String get newConnection;

  /// No description provided for @connection.
  ///
  /// In en, this message translates to:
  /// **'Connection'**
  String get connection;

  /// No description provided for @deleteProfile.
  ///
  /// In en, this message translates to:
  /// **'Delete profile'**
  String get deleteProfile;

  /// No description provided for @deleteProfileTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete profile?'**
  String get deleteProfileTitle;

  /// No description provided for @deleteProfileBody.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? This phone will forget that server.'**
  String deleteProfileBody(String name);

  /// No description provided for @enterProfileName.
  ///
  /// In en, this message translates to:
  /// **'Enter a profile name.'**
  String get enterProfileName;

  /// No description provided for @enterServerAddress.
  ///
  /// In en, this message translates to:
  /// **'Enter a server address like http://192.168.1.20:4533.'**
  String get enterServerAddress;

  /// No description provided for @enterUsername.
  ///
  /// In en, this message translates to:
  /// **'Enter the username.'**
  String get enterUsername;

  /// No description provided for @serverAddressHelp.
  ///
  /// In en, this message translates to:
  /// **'Use the address this phone can reach, such as https://subsonica.mydomain.org.'**
  String get serverAddressHelp;

  /// No description provided for @profileMissing.
  ///
  /// In en, this message translates to:
  /// **'That profile is no longer saved.'**
  String get profileMissing;

  /// No description provided for @profileLabel.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileLabel;

  /// No description provided for @playYourLibrary.
  ///
  /// In en, this message translates to:
  /// **'Play your Navidrome library'**
  String get playYourLibrary;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @clear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @serverConnection.
  ///
  /// In en, this message translates to:
  /// **'Server connection'**
  String get serverConnection;

  /// No description provided for @tabHome.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get tabHome;

  /// No description provided for @tabAlbum.
  ///
  /// In en, this message translates to:
  /// **'Album'**
  String get tabAlbum;

  /// No description provided for @tabTrack.
  ///
  /// In en, this message translates to:
  /// **'Track'**
  String get tabTrack;

  /// No description provided for @tabArtist.
  ///
  /// In en, this message translates to:
  /// **'Artist'**
  String get tabArtist;

  /// No description provided for @tabGenre.
  ///
  /// In en, this message translates to:
  /// **'Genre'**
  String get tabGenre;

  /// No description provided for @tabPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Playlist'**
  String get tabPlaylist;

  /// No description provided for @tabFavorites.
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get tabFavorites;

  /// No description provided for @noDownloads.
  ///
  /// In en, this message translates to:
  /// **'No downloads'**
  String get noDownloads;

  /// No description provided for @noDownloadsDetail.
  ///
  /// In en, this message translates to:
  /// **'Download a track or an album and it will be listed here.'**
  String get noDownloadsDetail;

  /// No description provided for @playAll.
  ///
  /// In en, this message translates to:
  /// **'Play all'**
  String get playAll;

  /// No description provided for @randomPlay.
  ///
  /// In en, this message translates to:
  /// **'Random play'**
  String get randomPlay;

  /// No description provided for @deleteAll.
  ///
  /// In en, this message translates to:
  /// **'Delete all'**
  String get deleteAll;

  /// No description provided for @deleteAllDownloadsTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete all downloads?'**
  String get deleteAllDownloadsTitle;

  /// No description provided for @deleteAllDownloadsBody.
  ///
  /// In en, this message translates to:
  /// **'Delete every download from this phone? The tracks stay in the library.'**
  String get deleteAllDownloadsBody;

  /// No description provided for @removeDownloadTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove download?'**
  String get removeDownloadTitle;

  /// No description provided for @removeDownloadBody.
  ///
  /// In en, this message translates to:
  /// **'Remove {title} from this phone? The track stays in the library.'**
  String removeDownloadBody(String title);

  /// No description provided for @removeDownload.
  ///
  /// In en, this message translates to:
  /// **'Remove download'**
  String get removeDownload;

  /// No description provided for @downloadFailed.
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailed;

  /// No description provided for @waiting.
  ///
  /// In en, this message translates to:
  /// **'Waiting'**
  String get waiting;

  /// No description provided for @noLyricsFound.
  ///
  /// In en, this message translates to:
  /// **'No lyrics found'**
  String get noLyricsFound;

  /// No description provided for @instrumental.
  ///
  /// In en, this message translates to:
  /// **'This track is instrumental.'**
  String get instrumental;

  /// No description provided for @lyricsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Lyrics are unavailable right now.'**
  String get lyricsUnavailable;

  /// No description provided for @couldNotLoadTracks.
  ///
  /// In en, this message translates to:
  /// **'Could not load tracks'**
  String get couldNotLoadTracks;

  /// No description provided for @noTracks.
  ///
  /// In en, this message translates to:
  /// **'No tracks'**
  String get noTracks;

  /// No description provided for @removedSong.
  ///
  /// In en, this message translates to:
  /// **'Removed {title}'**
  String removedSong(String title);

  /// No description provided for @albumAlreadyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'This album is already downloaded.'**
  String get albumAlreadyDownloaded;

  /// No description provided for @downloadWhenReachable.
  ///
  /// In en, this message translates to:
  /// **'The download will start when the server is reachable.'**
  String get downloadWhenReachable;

  /// No description provided for @downloadingTracks.
  ///
  /// In en, this message translates to:
  /// **'Downloading {count}'**
  String downloadingTracks(String count);

  /// No description provided for @connectToOpen.
  ///
  /// In en, this message translates to:
  /// **'Connect to a server to open this.'**
  String get connectToOpen;

  /// No description provided for @downloadAlbum.
  ///
  /// In en, this message translates to:
  /// **'Download album'**
  String get downloadAlbum;

  /// No description provided for @removeAlbumDownloadBody.
  ///
  /// In en, this message translates to:
  /// **'The tracks stay in the library. Only the copy on this phone is removed.'**
  String get removeAlbumDownloadBody;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @random.
  ///
  /// In en, this message translates to:
  /// **'Random'**
  String get random;

  /// No description provided for @favoriteAlbum.
  ///
  /// In en, this message translates to:
  /// **'Favorite album'**
  String get favoriteAlbum;

  /// No description provided for @unfavoriteAlbum.
  ///
  /// In en, this message translates to:
  /// **'Remove album from favorites'**
  String get unfavoriteAlbum;

  /// No description provided for @favoritePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Favorite playlist'**
  String get favoritePlaylist;

  /// No description provided for @unfavoritePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Remove playlist from favorites'**
  String get unfavoritePlaylist;

  /// No description provided for @noAlbumPage.
  ///
  /// In en, this message translates to:
  /// **'This track has no album page.'**
  String get noAlbumPage;

  /// No description provided for @trackOptions.
  ///
  /// In en, this message translates to:
  /// **'Track options'**
  String get trackOptions;

  /// No description provided for @unfavorite.
  ///
  /// In en, this message translates to:
  /// **'Remove from favorites'**
  String get unfavorite;

  /// No description provided for @favorite.
  ///
  /// In en, this message translates to:
  /// **'Favorite'**
  String get favorite;

  /// No description provided for @addToQueue.
  ///
  /// In en, this message translates to:
  /// **'Add to play queue'**
  String get addToQueue;

  /// No description provided for @showAlbum.
  ///
  /// In en, this message translates to:
  /// **'Show album page'**
  String get showAlbum;

  /// No description provided for @cancelDownload.
  ///
  /// In en, this message translates to:
  /// **'Cancel download'**
  String get cancelDownload;

  /// No description provided for @download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get download;

  /// No description provided for @connectToDownload.
  ///
  /// In en, this message translates to:
  /// **'Connect to download tracks.'**
  String get connectToDownload;

  /// No description provided for @trackAlreadyDownloaded.
  ///
  /// In en, this message translates to:
  /// **'This track is already downloaded.'**
  String get trackAlreadyDownloaded;

  /// No description provided for @downloading.
  ///
  /// In en, this message translates to:
  /// **'Downloading'**
  String get downloading;

  /// No description provided for @noDownloadedAlbums.
  ///
  /// In en, this message translates to:
  /// **'No downloaded albums'**
  String get noDownloadedAlbums;

  /// No description provided for @noDownloadedAlbumsDetail.
  ///
  /// In en, this message translates to:
  /// **'Albums you download appear here when the server is offline.'**
  String get noDownloadedAlbumsDetail;

  /// No description provided for @noDownloadedTracks.
  ///
  /// In en, this message translates to:
  /// **'No downloaded tracks'**
  String get noDownloadedTracks;

  /// No description provided for @noDownloadedTracksDetail.
  ///
  /// In en, this message translates to:
  /// **'Tracks you download can play with the server disconnected.'**
  String get noDownloadedTracksDetail;

  /// No description provided for @artistNoTracks.
  ///
  /// In en, this message translates to:
  /// **'This artist has no tracks.'**
  String get artistNoTracks;

  /// No description provided for @loadingTracks.
  ///
  /// In en, this message translates to:
  /// **'Loading tracks'**
  String get loadingTracks;

  /// No description provided for @artistOptions.
  ///
  /// In en, this message translates to:
  /// **'Artist options'**
  String get artistOptions;

  /// No description provided for @artistUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Artist unavailable'**
  String get artistUnavailable;

  /// No description provided for @noAlbums.
  ///
  /// In en, this message translates to:
  /// **'No albums'**
  String get noAlbums;

  /// No description provided for @noRecentAlbums.
  ///
  /// In en, this message translates to:
  /// **'No recent albums'**
  String get noRecentAlbums;

  /// No description provided for @noRecentAlbumsDetail.
  ///
  /// In en, this message translates to:
  /// **'Albums show up here after you play them.'**
  String get noRecentAlbumsDetail;

  /// No description provided for @addToPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Add to playlist'**
  String get addToPlaylist;

  /// No description provided for @addedToName.
  ///
  /// In en, this message translates to:
  /// **'Added to {name}'**
  String addedToName(String name);

  /// No description provided for @addedTracksToName.
  ///
  /// In en, this message translates to:
  /// **'Added {count} tracks to {name}'**
  String addedTracksToName(int count, String name);

  /// No description provided for @playlistOwnerOnly.
  ///
  /// In en, this message translates to:
  /// **'Only {owner} can add tracks to this playlist.'**
  String playlistOwnerOnly(String owner);

  /// No description provided for @playlistReadOnly.
  ///
  /// In en, this message translates to:
  /// **'Navidrome is not allowing changes to this playlist. Smart playlists and auto-imported lists stay read-only.'**
  String get playlistReadOnly;

  /// No description provided for @newPlaylist.
  ///
  /// In en, this message translates to:
  /// **'New playlist'**
  String get newPlaylist;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @createPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Create new playlist'**
  String get createPlaylist;

  /// No description provided for @queueEmpty.
  ///
  /// In en, this message translates to:
  /// **'The play queue is empty'**
  String get queueEmpty;

  /// No description provided for @addedToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added to the play queue'**
  String get addedToQueue;

  /// No description provided for @addedTracksToQueue.
  ///
  /// In en, this message translates to:
  /// **'Added {count} tracks to the play queue'**
  String addedTracksToQueue(int count);

  /// No description provided for @removeFromPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Remove from playlist'**
  String get removeFromPlaylist;

  /// No description provided for @searchFailed.
  ///
  /// In en, this message translates to:
  /// **'Search failed'**
  String get searchFailed;

  /// No description provided for @noResults.
  ///
  /// In en, this message translates to:
  /// **'No results'**
  String get noResults;

  /// No description provided for @artists.
  ///
  /// In en, this message translates to:
  /// **'Artists'**
  String get artists;

  /// No description provided for @albums.
  ///
  /// In en, this message translates to:
  /// **'Albums'**
  String get albums;

  /// No description provided for @tracks.
  ///
  /// In en, this message translates to:
  /// **'Tracks'**
  String get tracks;

  /// No description provided for @discNumber.
  ///
  /// In en, this message translates to:
  /// **'Disc {number}'**
  String discNumber(int number);

  /// No description provided for @genresUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Genres unavailable'**
  String get genresUnavailable;

  /// No description provided for @noGenres.
  ///
  /// In en, this message translates to:
  /// **'No genres'**
  String get noGenres;

  /// No description provided for @noGenreTags.
  ///
  /// In en, this message translates to:
  /// **'Tracks in this library have no genre tags yet.'**
  String get noGenreTags;

  /// No description provided for @artistsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Artists unavailable'**
  String get artistsUnavailable;

  /// No description provided for @noArtists.
  ///
  /// In en, this message translates to:
  /// **'No artists'**
  String get noArtists;

  /// No description provided for @noArtistsYet.
  ///
  /// In en, this message translates to:
  /// **'This library does not have any artists yet.'**
  String get noArtistsYet;

  /// No description provided for @albumsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Albums unavailable'**
  String get albumsUnavailable;

  /// No description provided for @noAlbumsYet.
  ///
  /// In en, this message translates to:
  /// **'This library does not have any albums yet.'**
  String get noAlbumsYet;

  /// No description provided for @tracksUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Tracks unavailable'**
  String get tracksUnavailable;

  /// No description provided for @tracksSample.
  ///
  /// In en, this message translates to:
  /// **'A sample from the library. Search to find a specific track.'**
  String get tracksSample;

  /// No description provided for @noSongsYet.
  ///
  /// In en, this message translates to:
  /// **'This library does not have any songs yet.'**
  String get noSongsYet;

  /// No description provided for @favoritesUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Favorites unavailable'**
  String get favoritesUnavailable;

  /// No description provided for @noFavorites.
  ///
  /// In en, this message translates to:
  /// **'No favorites'**
  String get noFavorites;

  /// No description provided for @noFavoritesDetail.
  ///
  /// In en, this message translates to:
  /// **'Albums, artists, and tracks you mark with a heart in Navidrome show up here.'**
  String get noFavoritesDetail;

  /// No description provided for @playlistsUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Playlists unavailable'**
  String get playlistsUnavailable;

  /// No description provided for @noPlaylists.
  ///
  /// In en, this message translates to:
  /// **'No playlists'**
  String get noPlaylists;

  /// No description provided for @noPlaylistsDetail.
  ///
  /// In en, this message translates to:
  /// **'Playlists you create on Navidrome show up here.'**
  String get noPlaylistsDetail;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @createdPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Created {name}'**
  String createdPlaylist(String name);

  /// No description provided for @renamePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Rename playlist'**
  String get renamePlaylist;

  /// No description provided for @renamedPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Renamed to {name}'**
  String renamedPlaylist(String name);

  /// No description provided for @deletePlaylist.
  ///
  /// In en, this message translates to:
  /// **'Delete playlist'**
  String get deletePlaylist;

  /// No description provided for @deletePlaylistBody.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}? The tracks stay in the library.'**
  String deletePlaylistBody(String name);

  /// No description provided for @deletedPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Deleted {name}'**
  String deletedPlaylist(String name);

  /// No description provided for @playlistName.
  ///
  /// In en, this message translates to:
  /// **'Playlist name'**
  String get playlistName;

  /// No description provided for @addToFavorites.
  ///
  /// In en, this message translates to:
  /// **'Add to favorites'**
  String get addToFavorites;

  /// No description provided for @serverTimeout.
  ///
  /// In en, this message translates to:
  /// **'The server took too long to respond.'**
  String get serverTimeout;

  /// No description provided for @secureConnectionFailed.
  ///
  /// In en, this message translates to:
  /// **'The secure connection failed.'**
  String get secureConnectionFailed;

  /// No description provided for @cannotReachServer.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach the server. Check the address.'**
  String get cannotReachServer;

  /// No description provided for @notSubsonic.
  ///
  /// In en, this message translates to:
  /// **'The server did not return a Subsonic response. Check the address.'**
  String get notSubsonic;

  /// No description provided for @somethingWentWrong.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get somethingWentWrong;

  /// No description provided for @serverRejected.
  ///
  /// In en, this message translates to:
  /// **'The server rejected the request.'**
  String get serverRejected;

  /// No description provided for @albumNotFound.
  ///
  /// In en, this message translates to:
  /// **'Album not found.'**
  String get albumNotFound;

  /// No description provided for @artistNotFound.
  ///
  /// In en, this message translates to:
  /// **'Artist not found.'**
  String get artistNotFound;

  /// No description provided for @playlistNotFound.
  ///
  /// In en, this message translates to:
  /// **'Playlist not found.'**
  String get playlistNotFound;

  /// No description provided for @serverNoFile.
  ///
  /// In en, this message translates to:
  /// **'The server did not return the file.'**
  String get serverNoFile;

  /// No description provided for @serverHttp.
  ///
  /// In en, this message translates to:
  /// **'The server returned HTTP {code}.'**
  String serverHttp(int code);

  /// No description provided for @noTracksToPlay.
  ///
  /// In en, this message translates to:
  /// **'There are no tracks to play.'**
  String get noTracksToPlay;

  /// No description provided for @downloadToPlayOffline.
  ///
  /// In en, this message translates to:
  /// **'Download these tracks to play them offline.'**
  String get downloadToPlayOffline;

  /// No description provided for @playbackFailed.
  ///
  /// In en, this message translates to:
  /// **'Playback failed. Check the server and the track file.'**
  String get playbackFailed;

  /// No description provided for @downloadedFileMissing.
  ///
  /// In en, this message translates to:
  /// **'The downloaded file is missing.'**
  String get downloadedFileMissing;

  /// No description provided for @unknownArtist.
  ///
  /// In en, this message translates to:
  /// **'Unknown artist'**
  String get unknownArtist;

  /// No description provided for @unknownAlbum.
  ///
  /// In en, this message translates to:
  /// **'Unknown album'**
  String get unknownAlbum;

  /// No description provided for @untitledPlaylist.
  ///
  /// In en, this message translates to:
  /// **'Untitled playlist'**
  String get untitledPlaylist;

  /// No description provided for @trackCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 track} other{{count} tracks}}'**
  String trackCount(int count);

  /// No description provided for @albumCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 album} other{{count} albums}}'**
  String albumCount(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'it'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'it':
      return AppLocalizationsIt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
