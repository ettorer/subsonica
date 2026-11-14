// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Italian (`it`).
class AppLocalizationsIt extends AppLocalizations {
  AppLocalizationsIt([String locale = 'it']) : super(locale);

  @override
  String get language => 'Lingua';

  @override
  String get localeAutomatic => 'Automatico';

  @override
  String get settingsTitle => 'Impostazioni';

  @override
  String get logOut => 'Esci';

  @override
  String get offlineLabel => 'Offline';

  @override
  String get offlineMode => 'Modalità offline';

  @override
  String get offlineModeDetail =>
      'Riproduci la musica salvata su questo telefono';

  @override
  String get karaoke => 'Karaoke';

  @override
  String get karaokeDetail =>
      'Mostra il testo in riproduzione in un browser su questa rete.';

  @override
  String get karaokeOpen => 'Apri questo indirizzo nel browser.';

  @override
  String get karaokeNoAddress =>
      'Connetti il telefono al Wi-Fi, poi spegni e riaccendi Karaoke.';

  @override
  String get karaokeFailed => 'Il server karaoke non si avvia.';

  @override
  String get showKaraokeQr => 'Mostra codice QR';

  @override
  String get karaokeQrTitle => 'Connetti a Karaoke';

  @override
  String get downloadsTitle => 'Download';

  @override
  String get scanPhoneMusic => 'Cerca musica sul telefono';

  @override
  String get scanPhoneMusicNow => 'Cerca musica sul telefono ora';

  @override
  String get scanPhoneMusicDetail =>
      'Legge album e brani dalla cartella Musica di questo telefono.';

  @override
  String get scanningPhoneMusic => 'Ricerca nella cartella Musica…';

  @override
  String phoneMusicFound(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Trovati $count brani.',
      one: 'Trovato 1 brano.',
    );
    return '$_temp0';
  }

  @override
  String get phoneMusicEmpty => 'Nessun file musicale trovato.';

  @override
  String get phoneMusicDenied =>
      'Consenti a Subsonica di leggere la musica su questo telefono.';

  @override
  String get phoneMusicFailed =>
      'Impossibile leggere il catalogo musicale del telefono.';

  @override
  String onThisPhone(String size) {
    return '$size su questo telefono';
  }

  @override
  String get connectionsTitle => 'Connessioni';

  @override
  String get addConnection => 'Aggiungi connessione';

  @override
  String connectedProfile(String url) {
    return '$url · Connesso';
  }

  @override
  String get edit => 'Modifica';

  @override
  String get delete => 'Elimina';

  @override
  String get cancel => 'Annulla';

  @override
  String get remove => 'Rimuovi';

  @override
  String get close => 'Chiudi';

  @override
  String get back => 'Indietro';

  @override
  String get save => 'Salva';

  @override
  String get retry => 'Riprova';

  @override
  String get tryAgain => 'Riprova';

  @override
  String get show => 'Mostra';

  @override
  String get lyrics => 'Testi';

  @override
  String get musicOnly => 'Solo musica';

  @override
  String get withVocals => 'Con voce';

  @override
  String get playQueue => 'Coda di riproduzione';

  @override
  String get options => 'Opzioni';

  @override
  String get nothingPlaying => 'Nessun brano in riproduzione';

  @override
  String get previousTrack => 'Brano precedente';

  @override
  String get nextTrack => 'Brano successivo';

  @override
  String get shuffle => 'Casuale';

  @override
  String get shuffleOn => 'Casuale attivo';

  @override
  String get loopOff => 'Ripetizione disattivata';

  @override
  String get loopAlbum => 'Ripeti album o playlist';

  @override
  String get loopTrack => 'Ripeti questo brano';

  @override
  String get nowPlaying => 'In riproduzione';

  @override
  String get pause => 'Pausa';

  @override
  String get play => 'Riproduci';

  @override
  String get speed => 'Velocità';

  @override
  String get startRadio => 'Avvia la radio';

  @override
  String get radioDetail => 'I brani simili partono dopo questo';

  @override
  String get radioOffline => 'Non disponibile in modalità offline';

  @override
  String get radioEmpty =>
      'Questo server non ha brani simili per questo brano.';

  @override
  String get radio => 'Radio';

  @override
  String get rating => 'Valutazione';

  @override
  String get connectToRate => 'Connettiti per impostare una valutazione.';

  @override
  String get listenOffline => 'Ascolta offline';

  @override
  String get connect => 'Connetti';

  @override
  String get signIn => 'Accedi';

  @override
  String get connectionSaved => 'Connessione salvata';

  @override
  String get profileName => 'Nome profilo';

  @override
  String get profileNameHint => 'Casa';

  @override
  String get serverUrl => 'Indirizzo del server';

  @override
  String get username => 'Nome utente';

  @override
  String get password => 'Password';

  @override
  String get showPassword => 'Mostra password';

  @override
  String get hidePassword => 'Nascondi password';

  @override
  String get newConnection => 'Nuova connessione';

  @override
  String get connection => 'Connessione';

  @override
  String get deleteProfile => 'Elimina profilo';

  @override
  String get deleteProfileTitle => 'Eliminare il profilo?';

  @override
  String deleteProfileBody(String name) {
    return 'Eliminare $name? Questo telefono dimenticherà quel server.';
  }

  @override
  String get enterProfileName => 'Inserisci un nome per il profilo.';

  @override
  String get enterServerAddress =>
      'Inserisci un indirizzo, ad esempio http://192.168.1.20:4533.';

  @override
  String get enterUsername => 'Inserisci il nome utente.';

  @override
  String get serverAddressHelp =>
      'Usa l\'indirizzo che questo telefono può raggiungere, ad esempio https://subsonica.mydomain.org.';

  @override
  String get profileMissing => 'Quel profilo non è più salvato.';

  @override
  String get profileLabel => 'Profilo';

  @override
  String get playYourLibrary => 'Ascolta la tua libreria Navidrome';

  @override
  String get search => 'Cerca';

  @override
  String get clear => 'Cancella';

  @override
  String get serverConnection => 'Connessione al server';

  @override
  String get tabHome => 'Home';

  @override
  String get tabAlbum => 'Album';

  @override
  String get tabTrack => 'Brano';

  @override
  String get tabArtist => 'Artista';

  @override
  String get tabGenre => 'Genere';

  @override
  String get tabPlaylist => 'Playlist';

  @override
  String get tabFavorites => 'Preferiti';

  @override
  String get noDownloads => 'Nessun download';

  @override
  String get noDownloadsDetail =>
      'Scarica un brano o un album per vederlo qui.';

  @override
  String get playAll => 'Riproduci tutto';

  @override
  String get randomPlay => 'Riproduzione casuale';

  @override
  String get deleteAll => 'Elimina tutto';

  @override
  String get deleteAllDownloadsTitle => 'Eliminare tutti i download?';

  @override
  String get deleteAllDownloadsBody =>
      'Eliminare tutti i download da questo telefono? I brani restano nella libreria.';

  @override
  String get removeDownloadTitle => 'Rimuovere il download?';

  @override
  String removeDownloadBody(String title) {
    return 'Rimuovere $title da questo telefono? Il brano resta nella libreria.';
  }

  @override
  String get removeDownload => 'Rimuovi download';

  @override
  String get downloadFailed => 'Download non riuscito';

  @override
  String get waiting => 'In attesa';

  @override
  String get noLyricsFound => 'Nessun testo trovato';

  @override
  String get instrumental => 'Questo brano è strumentale.';

  @override
  String get lyricsUnavailable =>
      'I testi non sono disponibili in questo momento.';

  @override
  String get couldNotLoadTracks => 'Impossibile caricare i brani';

  @override
  String get noTracks => 'Nessun brano';

  @override
  String removedSong(String title) {
    return 'Rimosso $title';
  }

  @override
  String get albumAlreadyDownloaded => 'Questo album è già stato scaricato.';

  @override
  String get downloadWhenReachable =>
      'Il download inizierà quando il server sarà raggiungibile.';

  @override
  String downloadingTracks(String count) {
    return 'Download di $count';
  }

  @override
  String get connectToOpen => 'Connettiti a un server per aprirlo.';

  @override
  String get downloadAlbum => 'Scarica album';

  @override
  String get removeAlbumDownloadBody =>
      'I brani restano nella libreria. Viene rimossa solo la copia su questo telefono.';

  @override
  String get stop => 'Ferma';

  @override
  String get random => 'Casuale';

  @override
  String get favoriteAlbum => 'Aggiungi album ai preferiti';

  @override
  String get unfavoriteAlbum => 'Rimuovi album dai preferiti';

  @override
  String get favoritePlaylist => 'Aggiungi la playlist ai preferiti';

  @override
  String get unfavoritePlaylist => 'Rimuovi la playlist dai preferiti';

  @override
  String get noAlbumPage => 'Questo brano non ha una pagina album.';

  @override
  String get trackOptions => 'Opzioni brano';

  @override
  String get unfavorite => 'Rimuovi dai preferiti';

  @override
  String get favorite => 'Preferito';

  @override
  String get addToQueue => 'Aggiungi alla coda';

  @override
  String get showAlbum => 'Mostra album';

  @override
  String get cancelDownload => 'Annulla download';

  @override
  String get download => 'Scarica';

  @override
  String get connectToDownload => 'Connettiti per scaricare i brani.';

  @override
  String get trackAlreadyDownloaded => 'Questo brano è già stato scaricato.';

  @override
  String get downloading => 'Download in corso';

  @override
  String get noDownloadedAlbums => 'Nessun album scaricato';

  @override
  String get noDownloadedAlbumsDetail =>
      'Gli album che scarichi compaiono qui quando il server è offline.';

  @override
  String get noDownloadedTracks => 'Nessun brano scaricato';

  @override
  String get noDownloadedTracksDetail =>
      'I brani scaricati si possono ascoltare anche senza server.';

  @override
  String get artistNoTracks => 'Questo artista non ha brani.';

  @override
  String get loadingTracks => 'Caricamento brani';

  @override
  String get artistOptions => 'Opzioni artista';

  @override
  String get artistUnavailable => 'Artista non disponibile';

  @override
  String get noAlbums => 'Nessun album';

  @override
  String get noRecentAlbums => 'Nessun album recente';

  @override
  String get noRecentAlbumsDetail =>
      'Gli album compaiono qui dopo che li ascolti.';

  @override
  String get addToPlaylist => 'Aggiungi alla playlist';

  @override
  String addedToName(String name) {
    return 'Aggiunto a $name';
  }

  @override
  String addedTracksToName(int count, String name) {
    return 'Aggiunti $count brani a $name';
  }

  @override
  String playlistOwnerOnly(String owner) {
    return 'Solo $owner può aggiungere brani a questa playlist.';
  }

  @override
  String get playlistReadOnly =>
      'Navidrome non consente modifiche a questa playlist. Le playlist smart e quelle importate automaticamente restano di sola lettura.';

  @override
  String get newPlaylist => 'Nuova playlist';

  @override
  String get create => 'Crea';

  @override
  String get createPlaylist => 'Crea una nuova playlist';

  @override
  String get queueEmpty => 'La coda è vuota';

  @override
  String get addedToQueue => 'Aggiunto alla coda';

  @override
  String addedTracksToQueue(int count) {
    return 'Aggiunti $count brani alla coda';
  }

  @override
  String get removeFromPlaylist => 'Rimuovi dalla playlist';

  @override
  String get searchFailed => 'Ricerca non riuscita';

  @override
  String get noResults => 'Nessun risultato';

  @override
  String get artists => 'Artisti';

  @override
  String get albums => 'Album';

  @override
  String get tracks => 'Brani';

  @override
  String discNumber(int number) {
    return 'Disco $number';
  }

  @override
  String get genresUnavailable => 'Generi non disponibili';

  @override
  String get noGenres => 'Nessun genere';

  @override
  String get noGenreTags =>
      'I brani di questa libreria non hanno ancora un genere.';

  @override
  String get artistsUnavailable => 'Artisti non disponibili';

  @override
  String get noArtists => 'Nessun artista';

  @override
  String get noArtistsYet => 'Questa libreria non ha ancora artisti.';

  @override
  String get albumsUnavailable => 'Album non disponibili';

  @override
  String get noAlbumsYet => 'Questa libreria non ha ancora album.';

  @override
  String get tracksUnavailable => 'Brani non disponibili';

  @override
  String get tracksSample =>
      'Un campione della libreria. Cerca per trovare un brano.';

  @override
  String get noSongsYet => 'Questa libreria non ha ancora brani.';

  @override
  String get favoritesUnavailable => 'Preferiti non disponibili';

  @override
  String get noFavorites => 'Nessun preferito';

  @override
  String get noFavoritesDetail =>
      'Album, artisti e brani che segni con un cuore in Navidrome compaiono qui.';

  @override
  String get playlistsUnavailable => 'Playlist non disponibili';

  @override
  String get noPlaylists => 'Nessuna playlist';

  @override
  String get noPlaylistsDetail =>
      'Le playlist che crei in Navidrome compaiono qui.';

  @override
  String get rename => 'Rinomina';

  @override
  String createdPlaylist(String name) {
    return 'Creata $name';
  }

  @override
  String get renamePlaylist => 'Rinomina playlist';

  @override
  String renamedPlaylist(String name) {
    return 'Rinominata in $name';
  }

  @override
  String get deletePlaylist => 'Elimina playlist';

  @override
  String deletePlaylistBody(String name) {
    return 'Eliminare $name? I brani restano nella libreria.';
  }

  @override
  String deletedPlaylist(String name) {
    return 'Eliminata $name';
  }

  @override
  String get playlistName => 'Nome playlist';

  @override
  String get addToFavorites => 'Aggiungi ai preferiti';

  @override
  String get serverTimeout =>
      'Il server ha impiegato troppo tempo a rispondere.';

  @override
  String get secureConnectionFailed => 'La connessione sicura non è riuscita.';

  @override
  String get cannotReachServer =>
      'Impossibile raggiungere il server. Controlla l\'indirizzo.';

  @override
  String get notSubsonic =>
      'Il server non ha risposto come Subsonic. Controlla l\'indirizzo.';

  @override
  String get somethingWentWrong => 'Qualcosa è andato storto. Riprova.';

  @override
  String get serverRejected => 'Il server ha rifiutato la richiesta.';

  @override
  String get albumNotFound => 'Album non trovato.';

  @override
  String get artistNotFound => 'Artista non trovato.';

  @override
  String get playlistNotFound => 'Playlist non trovata.';

  @override
  String get serverNoFile => 'Il server non ha inviato il file.';

  @override
  String serverHttp(int code) {
    return 'Il server ha risposto HTTP $code.';
  }

  @override
  String get noTracksToPlay => 'Non ci sono brani da riprodurre.';

  @override
  String get downloadToPlayOffline =>
      'Scarica questi brani per ascoltarli offline.';

  @override
  String get playbackFailed =>
      'Riproduzione non riuscita. Controlla il server e il file.';

  @override
  String get downloadedFileMissing => 'Il file scaricato non c\'è più.';

  @override
  String get unknownArtist => 'Artista sconosciuto';

  @override
  String get unknownAlbum => 'Album sconosciuto';

  @override
  String get untitledPlaylist => 'Playlist senza titolo';

  @override
  String trackCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count brani',
      one: '1 brano',
    );
    return '$_temp0';
  }

  @override
  String albumCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count album',
      one: '1 album',
    );
    return '$_temp0';
  }
}
