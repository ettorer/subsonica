import 'package:flutter/widgets.dart';

import '../services/settings_store.dart';

class LocaleController extends ChangeNotifier {
  LocaleController(this._store, String preference)
    : _preference = knownLocale(preference) {
    _locale = localeFor(_preference);
  }

  final SettingsStore _store;
  String _preference;
  Locale? _locale;

  String get preference => _preference;
  Locale? get locale => _locale;

  Future<void> setPreference(String value) async {
    final next = knownLocale(value);
    if (next == _preference) return;
    _preference = next;
    _locale = localeFor(next);
    notifyListeners();
    await _store.saveLocale(next);
  }
}

String knownLocale(String value) {
  return switch (value) {
    'en' || 'it' => value,
    _ => 'auto',
  };
}

Locale? localeFor(String value) {
  return switch (value) {
    'en' => const Locale('en'),
    'it' => const Locale('it'),
    _ => null,
  };
}
