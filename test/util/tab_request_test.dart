import 'package:checkscan/core/state/tab_request.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a request notifies once and is consumed by take', () {
    final request = TabRequest();
    var notified = 0;
    request.addListener(() => notified += 1);

    request.request(2);

    expect(notified, 1);
    expect(request.take(), 2);
    expect(request.take(), isNull);
  });
}
