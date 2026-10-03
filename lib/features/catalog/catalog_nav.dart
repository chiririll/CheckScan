import 'package:flutter/material.dart';

import '../../core/state/app_state.dart';
import '../widgets/navigation.dart';
import 'catalog_page.dart';

const catalogRouteName = 'catalog';

abstract final class CatalogTab {
  static const unassigned = 0;
  static const products = 1;
  static const categories = 2;
}

/// Pops back to the catalog if it is on the stack, otherwise pushes it, then shows [tab].
void openCatalog(BuildContext context, AppState state, {int tab = CatalogTab.unassigned}) {
  state.catalogTab.request(tab);
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
  pushPage<void>(context, CatalogPage(state: state, initialTab: tab), name: catalogRouteName);
}
