import 'package:checkscan/core/scan/provider_secrets.dart';
import 'package:checkscan/core/scan/providers_backend.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('secretSpecsFromProvidersJson uses opaque provider keys', () {
    const raw = '''
    [
      {"id":"eq_payload","label":"EQ"},
      {"id":"ru_fns","label":"RU","secrets":[{"id":"token"}]}
    ]
    ''';
    final specs = secretSpecsFromProvidersJson(raw);
    expect(specs, hasLength(1));
    expect(specs.single.key, 'ru_fns.token');
    expect(specs.single.label, 'RU');
  });

  test('ProviderSecrets persists trimmed values', () async {
    SharedPreferences.setMockInitialValues({});
    final store = ProviderSecrets();
    await store.load();
    await store.set('ru_fns.token', '  abc  ');
    expect(store.values['ru_fns.token'], 'abc');

    final again = ProviderSecrets();
    await again.load();
    expect(again.values['ru_fns.token'], 'abc');

    await again.set('ru_fns.token', '   ');
    expect(again.values.containsKey('ru_fns.token'), isFalse);
  });
}
