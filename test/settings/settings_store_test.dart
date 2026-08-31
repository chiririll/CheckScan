import 'package:checkscan/core/settings/settings_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('SettingsStore persists trimmed values and survives bad json', () async {
    SharedPreferences.setMockInitialValues({});
    final store = SettingsStore();
    await store.load();
    await store.set('ru_fns.token', '  abc  ');
    expect(store.values['ru_fns.token'], 'abc');

    final again = SettingsStore();
    await again.load();
    expect(again.values['ru_fns.token'], 'abc');

    await again.set('ru_fns.token', '   ');
    expect(again.values.containsKey('ru_fns.token'), isFalse);
  });

  test('broken json becomes empty snapshot', () async {
    SharedPreferences.setMockInitialValues({'provider_secrets': '{not-json'});
    final store = SettingsStore();
    await store.load();
    expect(store.snapshot(), isEmpty);
  });
}
