// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:music_player_app/theme/theme_provider.dart';

void main() {
  test('theme provider toggles between light and dark mode', () {
    final provider = ThemeProvider();

    expect(provider.isDarkMode, isFalse);
    provider.toggleTheme(true);
    expect(provider.isDarkMode, isTrue);
    provider.toggleTheme(false);
    expect(provider.isDarkMode, isFalse);

    provider.dispose();
  });
}
