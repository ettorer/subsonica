const libraryAlphabet = [
  '#',
  'A',
  'B',
  'C',
  'D',
  'E',
  'F',
  'G',
  'H',
  'I',
  'J',
  'K',
  'L',
  'M',
  'N',
  'O',
  'P',
  'Q',
  'R',
  'S',
  'T',
  'U',
  'V',
  'W',
  'X',
  'Y',
  'Z',
];

const _folded = {
  'À': 'A',
  'Á': 'A',
  'Â': 'A',
  'Ã': 'A',
  'Ä': 'A',
  'Å': 'A',
  'Ç': 'C',
  'È': 'E',
  'É': 'E',
  'Ê': 'E',
  'Ë': 'E',
  'Ì': 'I',
  'Í': 'I',
  'Î': 'I',
  'Ï': 'I',
  'Ñ': 'N',
  'Ò': 'O',
  'Ó': 'O',
  'Ô': 'O',
  'Õ': 'O',
  'Ö': 'O',
  'Ù': 'U',
  'Ú': 'U',
  'Û': 'U',
  'Ü': 'U',
};

/// Uppercase A–Z bucket for a library name. Anything else is `#`.
String libraryLetter(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '#';
  final runes = trimmed.runes;
  if (runes.isEmpty) return '#';
  final first = String.fromCharCodes([runes.first]).toUpperCase();
  if (first.length == 1) {
    final code = first.codeUnitAt(0);
    if (code >= 65 && code <= 90) return first;
  }
  return _folded[first] ?? '#';
}

/// `#` is 0. `A` is 1, through `Z` at 26.
int libraryLetterRank(String letter) {
  if (letter.length == 1) {
    final code = letter.codeUnitAt(0);
    if (code >= 65 && code <= 90) return code - 64;
  }
  return 0;
}

/// First alphabet entry that any name falls into.
String? firstLibraryLetter(Iterable<String> names) {
  final present = {for (final name in names) libraryLetter(name)};
  for (final letter in libraryAlphabet) {
    if (present.contains(letter)) return letter;
  }
  return null;
}

int? indexOfLibraryLetter(List<String> names, String letter) {
  for (var i = 0; i < names.length; i++) {
    if (libraryLetter(names[i]) == letter) return i;
  }
  return null;
}
