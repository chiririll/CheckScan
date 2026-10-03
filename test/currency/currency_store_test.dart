import 'package:checkscan/core/currency/currency_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('order survives a reload and is cleaned on the way in', () async {
    SharedPreferences.setMockInitialValues({});
    await CurrencyStore().save(['rsd', 'junk', 'RUB', 'RSD']);

    final reloaded = CurrencyStore();
    await reloaded.load();
    expect(reloaded.order, ['RSD', 'RUB']);
  });

  test('no saved order means no preference', () async {
    SharedPreferences.setMockInitialValues({});
    final store = CurrencyStore();
    await store.load();
    expect(store.order, isEmpty);
  });
}
