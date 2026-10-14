import 'package:autouni_app/core/session/session_events.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('notifyExpired chega a todos os ouvintes', () async {
    final events = SessionEvents();
    var a = 0;
    var b = 0;
    events.expired.listen((_) => a++);
    events.expired.listen((_) => b++);

    events.notifyExpired();
    await Future<void>.delayed(Duration.zero);

    expect((a, b), (1, 1));
  });

  test('depois do dispose, notifyExpired é ignorado', () async {
    final events = SessionEvents();
    await events.dispose();

    expect(events.notifyExpired, returnsNormally);
  });

  test('o provider descarta os eventos junto com o container', () {
    final container = ProviderContainer.test();
    final events = container.read(sessionEventsProvider);

    container.dispose();

    expect(events.notifyExpired, returnsNormally);
  });
}
