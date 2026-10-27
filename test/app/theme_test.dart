import 'package:checkscan/app/motion.dart';
import 'package:checkscan/app/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('themes expose the matching palette', () {
    expect(buildAppTheme().extension<AppPalette>(), AppPalette.light);
    expect(buildAppTheme(Brightness.dark).extension<AppPalette>(), AppPalette.dark);
    expect(buildAppTheme(Brightness.dark).brightness, Brightness.dark);
  });

  testWidgets('context.palette follows the theme brightness', (tester) async {
    late AppPalette seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(Brightness.dark),
        home: Builder(builder: (context) {
          seen = context.palette;
          return const SizedBox();
        }),
      ),
    );
    expect(seen, AppPalette.dark);
  });

  testWidgets('FadeSlideIn reaches full opacity', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FadeSlideIn(index: 3, child: Text('x'))));
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
  });

  testWidgets('TabFade replays when it becomes active', (tester) async {
    Widget build(bool active) => MaterialApp(home: TabFade(active: active, child: const Text('x')));
    await tester.pumpWidget(build(false));
    await tester.pumpWidget(build(true));
    await tester.pump(const Duration(milliseconds: 20));
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, lessThan(1));
    await tester.pumpAndSettle();
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
  });
}
