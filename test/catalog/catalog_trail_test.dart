import 'package:checkscan/features/catalog/catalog_trail.dart';
import 'package:checkscan/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('app bar shows only the current title and puts ancestors plus actions in one menu', (tester) async {
    String? opened;
    var deleted = false;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          appBar: CatalogAppBar(
            title: 'Молоко',
            ancestors: [
              CatalogCrumb(label: 'Каталог', onTap: () => opened = 'catalog'),
              CatalogCrumb(label: 'Товары', onTap: () => opened = 'products'),
            ],
            actions: [
              const CatalogAction(label: 'В чеках', onSelected: _noop),
              CatalogAction(label: 'Удалить товар', destructive: true, onSelected: () => deleted = true),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Молоко'), findsOneWidget);
    expect(find.text('Каталог'), findsNothing);
    expect(find.text('Товары'), findsNothing);
    expect(find.text('В чеках'), findsNothing);
    expect(find.byIcon(Icons.delete_outline), findsNothing);
    expect(find.byIcon(Icons.more_horiz), findsNothing);

    await tester.tap(find.byTooltip('Ещё'));
    await tester.pumpAndSettle();
    expect(find.text('Каталог'), findsOneWidget);
    expect(find.text('Товары'), findsOneWidget);
    expect(find.text('В чеках'), findsOneWidget);
    expect(find.text('Удалить товар'), findsOneWidget);

    await tester.tap(find.text('Удалить товар'));
    await tester.pumpAndSettle();
    expect(deleted, isTrue);
    expect(opened, isNull);
  });
}

void _noop() {}
