import 'package:flutter_test/flutter_test.dart';
import 'package:subsonica/remote/lrc.dart';

void main() {
  test('lrc stamps become milliseconds and drop metadata', () {
    final lines = parseLrc('''
[ar:Someone]
[00:12.34] Hello
[1:02.5] Hi
[00:01.00][00:03.00] Twice
''');
    expect(lines.map((line) => line.timeMs), [1000, 3000, 12340, 62500]);
    expect(lines.map((line) => line.text), ['Twice', 'Twice', 'Hello', 'Hi']);
  });
}
