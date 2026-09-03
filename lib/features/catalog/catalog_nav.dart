import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import 'catalog_page.dart';

const catalogRouteName = 'catalog';

void openCatalog(BuildContext context, AppState state, {int tab = 0}) {
  state.catalog.requestTab(tab);
  final nav = Navigator.of(context);
  var found = false;
  nav.popUntil((route) {
    if (route.settings.name == catalogRouteName) {
      found = true;
      return true;
    }
    return route.isFirst;
  });
  if (found || !context.mounted) return;
  nav.push(
    MaterialPageRoute<void>(
      settings: const RouteSettings(name: catalogRouteName),
      builder: (_) => CatalogPage(state: state, initialTab: tab),
    ),
  );
}
