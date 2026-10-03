import 'package:shared_preferences/shared_preferences.dart';

import 'currencies.dart';

/// The user's ordered currency list. Empty means "no preference": everything is derived from receipts.
class CurrencyStore {
  static const _key = 'currency_order';

  List<String> order = const [];

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    order = cleanCurrencies(prefs.getStringList(_key) ?? const []);
  }

  Future<void> save(List<String> codes) async {
    order = cleanCurrencies(codes);
    await (await SharedPreferences.getInstance()).setStringList(_key, order);
  }
}
