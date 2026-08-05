import 'dart:math';

import 'package:etalien_daily/core/claim_service.dart';
import 'package:etalien_daily/core/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('claim scope filtering', () {
    final account = Account(
      phone: '13800138000',
      claimPc: true,
      claimMobile: false,
      claimTranslate: true,
    );

    test('all uses account configured targets', () {
      expect(shouldRunPc(account, 'all'), isTrue);
      expect(shouldRunMobile(account, 'all'), isFalse);
      expect(shouldRunTranslate(account, 'all'), isTrue);
    });

    test('shortcut buttons filter by account scope', () {
      expect(shouldRunPc(account, 'pc'), isTrue);
      expect(shouldRunMobile(account, 'mobile'), isFalse);
      expect(shouldRunTranslate(account, 'translate'), isTrue);
      expect(shouldRunTranslate(account, 'pc'), isFalse);
    });

    test('disabled scope is never selected', () {
      final disabled = Account(
        phone: '13800138001',
        claimPc: false,
        claimMobile: false,
        claimTranslate: false,
      );
      expect(shouldRunPc(disabled, 'all'), isFalse);
      expect(shouldRunMobile(disabled, 'all'), isFalse);
      expect(shouldRunTranslate(disabled, 'translate'), isFalse);
    });
  });

  group('jitteredCallbackDelay', () {
    test('stays within base plus or minus one second', () {
      final random = Random(42);
      const base = Duration(seconds: 10);
      const low = Duration(seconds: 9);
      const high = Duration(seconds: 11);
      for (var i = 0; i < 200; i++) {
        final delay = jitteredCallbackDelay(base, random);
        expect(delay, greaterThanOrEqualTo(low));
        expect(delay, lessThanOrEqualTo(high));
      }
    });

    test('clamps short base delays to zero', () {
      final random = Random(7);
      const base = Duration(milliseconds: 100);
      for (var i = 0; i < 200; i++) {
        final delay = jitteredCallbackDelay(base, random);
        expect(delay.inMilliseconds, greaterThanOrEqualTo(0));
        expect(delay.inMilliseconds, lessThanOrEqualTo(1100));
      }
    });
  });
}
