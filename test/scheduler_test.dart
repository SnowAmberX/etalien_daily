import 'package:etalien_daily/platform/scheduler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('schtaskCreateArgs', () {
    test('uses SYSTEM non-interactive with highest run level', () {
      final args = schtaskCreateArgs('08:00');
      expect(args, containsAll(['/ru', 'SYSTEM']));
      expect(args, containsAll(['/rl', 'HIGHEST']));
      expect(args, isNot(contains('/IT')));
    });
  });
}
