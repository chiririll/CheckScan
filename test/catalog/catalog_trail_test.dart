import 'package:checkscan/features/catalog/catalog_trail.dart';
import 'package:checkscan/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('shows the current crumb as title and ancestors in a popup', (tester) async {
    String? opened;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          appBar: AppBar(
            title: CatalogTrail(
              crumbs: [
                CatalogCrumb(label: 'Каталог', onTap: () => opened = 'catalog'),
                CatalogCrumb(label: 'Категории', onTap: () => opened = 'list'),
                CatalogCrumb(label: 'Молоко'),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Молоко'), findsOneWidget);
    expect(find.text('Каталог'), findsNothing);
    expect(find.text('Категории'), findsNothing);

    await tester.tap(find.byTooltip('Назад по каталогу'));
    await tester.pumpAndSettle();
    expect(find.text('Каталог'), findsOneWidget);
    expect(find.text('Категории'), findsOneWidget);

    await tester.tap(find.text('Каталог'));
    await tester.pumpAndSettle();
    expect(opened, 'catalog');
  });
}
