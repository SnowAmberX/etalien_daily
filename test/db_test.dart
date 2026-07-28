/// SQLite 数据层单元测试（对照 v1 tests/test_db.py）。
library;

import 'dart:io';

import 'package:etalien_daily/core/database.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory tmpdir;

  setUp(() async {
    tmpdir = Directory.systemTemp.createTempSync('etalien_test_');
    await closeDb();
    setConfigDir(tmpdir.path);
    await initDb();
  });

  tearDown(() async {
    await closeDb();
    setConfigDir(null);
    tmpdir.deleteSync(recursive: true);
  });

  group('initDb', () {
    test('db file created', () {
      expect(File(getDbPath()).existsSync(), isTrue);
    });

    test('init idempotent', () async {
      await initDb();
      await initDb();
      final db = await getDb();
      final rows =
          await db.rawQuery('SELECT COUNT(*) AS c FROM settings');
      expect(rows.first['c'], 9); // 9 个默认设置
    });

    test('tables exist', () async {
      final db = await getDb();
      final tables = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' ORDER BY name",
      );
      final names = tables.map((r) => r['name'] as String).toList();
      expect(names, containsAll(['accounts', 'settings', 'claim_history']));
    });

    test('default settings', () async {
      final s = await getSettings();
      expect(s.maxConcurrent, 10);
      expect(s.requestInterval, 1.0);
      expect(s.maxRounds, 21);
      expect(s.scheduleTime, '08:00');
    });
  });

  group('account CRUD', () {
    test('add account', () async {
      final acc = await addAccount('13800138000', name: '测试账号', remark: '备注');
      expect(acc.phone, '13800138000');
      expect(acc.name, '测试账号');
      expect(acc.enabled, isTrue);
      expect(acc.deviceId.length, 25);
      expect(acc.createdAt, greaterThan(0));
      expect(acc.createdAt, acc.updatedAt);
    });

    test('add account duplicate phone', () async {
      await addAccount('13800138000');
      expect(() => addAccount('13800138000'), throwsA(anything));
    });

    test('get account', () async {
      await addAccount('13800138000', name: '测试');
      final acc = await getAccount('13800138000');
      expect(acc, isNotNull);
      expect(acc!.name, '测试');
    });

    test('get account not found', () async {
      expect(await getAccount('99999999999'), isNull);
    });

    test('get accounts enabled only', () async {
      await addAccount('13800000001', name: '启用');
      await addAccount('13800000002', name: '禁用');
      await updateAccount('13800000002', enabled: false);

      final enabled = await getAccounts(enabledOnly: true);
      expect(enabled.length, 1);
      expect(enabled.first.phone, '13800000001');

      final all = await getAccounts(enabledOnly: false);
      expect(all.length, 2);
    });

    test('get account by id', () async {
      final acc = await addAccount('13800138000');
      final found = await getAccountById(acc.id);
      expect(found, isNotNull);
      expect(found!.phone, '13800138000');
    });

    test('update account', () async {
      await addAccount('13800138000', name: '旧名称');
      // 确保 updated_at 变化（精度 1ms）
      await Future<void>.delayed(const Duration(milliseconds: 2));
      final result =
          await updateAccount('13800138000', name: '新名称', remark: '新备注');
      expect(result, isTrue);
      final acc = (await getAccount('13800138000'))!;
      expect(acc.name, '新名称');
      expect(acc.remark, '新备注');
      expect(acc.updatedAt, greaterThan(acc.createdAt));
    });

    test('update account not found', () async {
      expect(await updateAccount('99999999999', name: 'x'), isFalse);
    });

    test('update account token', () async {
      await addAccount('13800138000');
      final result =
          await updateAccountToken('13800138000', 'Bearer xyz', 42);
      expect(result, isTrue);
      final acc = (await getAccount('13800138000'))!;
      expect(acc.authToken, 'Bearer xyz');
      expect(acc.userId, 42);
    });

    test('delete account', () async {
      await addAccount('13800138000');
      expect(await deleteAccount('13800138000'), isTrue);
      expect(await getAccount('13800138000'), isNull);
    });

    test('delete account not found', () async {
      expect(await deleteAccount('99999999999'), isFalse);
    });

    test('toMap excludes token', () async {
      await addAccount('13800138000', name: '测试');
      await updateAccountToken('13800138000', 'Bearer secret', 1);
      final acc = (await getAccount('13800138000'))!;
      final map = acc.toMap();
      expect(map.containsKey('auth_token'), isFalse);
      expect(map.containsKey('phone'), isTrue);
      expect(map.containsKey('name'), isTrue);
    });

    test('custom device id', () async {
      final acc = await addAccount('13800138000',
          deviceId: 'custom_device_12345');
      expect(acc.deviceId, 'custom_device_12345');
    });
  });

  group('settings CRUD', () {
    test('update settings', () async {
      await updateSettings(maxConcurrent: 5, requestInterval: 2.5);
      final s = await getSettings();
      expect(s.maxConcurrent, 5);
      expect(s.requestInterval, 2.5);
    });

    test('update settings clamp', () async {
      await updateSettings(maxConcurrent: 100); // 超过上限 50
      expect((await getSettings()).maxConcurrent, 50);

      await updateSettings(maxConcurrent: 0); // 低于下限 1
      expect((await getSettings()).maxConcurrent, 1);

      await updateSettings(requestInterval: 0.0); // 低于下限 0.1
      expect((await getSettings()).requestInterval, 0.1);
    });

    test('update settings partial', () async {
      final before = await getSettings();
      await updateSettings(maxConcurrent: 8);
      final after = await getSettings();
      expect(after.maxConcurrent, 8);
      expect(after.requestInterval, before.requestInterval);
    });
  });

  group('claim history', () {
    test('add and query', () async {
      final acc = await addAccount('13800138000');
      await addClaimRecord(
        acc.id,
        'ok',
        vipBefore: 3600,
        vipAfter: 7200,
        claimedCount: 3,
        failedCount: 0,
      );
      // 确保 claimed_at 毫秒精度可区分（倒序断言依赖时间序）
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await addClaimRecord(
        acc.id,
        'auth_error',
        vipBefore: 7200,
        vipAfter: 7200,
        claimedCount: 0,
        failedCount: 1,
      );

      final records = await getClaimHistory(accountId: acc.id);
      expect(records.length, 2);
      expect(records[0]['status'], 'auth_error'); // 按时间倒序
      expect(records[1]['status'], 'ok');
      expect(records[1]['claimed_count'], 3);
    });

    test('empty history', () async {
      final acc = await addAccount('13800138000');
      expect(await getClaimHistory(accountId: acc.id), isEmpty);
    });

    test('delete account cascades', () async {
      final acc = await addAccount('13800138000');
      await addClaimRecord(acc.id, 'ok');
      expect((await getClaimHistory(accountId: acc.id)).length, 1);

      await deleteAccount('13800138000');
      expect(await getClaimHistory(accountId: acc.id), isEmpty);
    });
  });

  group('claim events', () {
    test('add and query', () async {
      final acc = await addAccount('13800138000');
      await addClaimEvent(
        'run-1',
        acc.id,
        acc.phone,
        'done',
        step: 'b1_r0',
        detail: '测试事件',
        current: 3,
        total: 21,
      );
      final events = await getClaimEvents();
      expect(events.length, 1);
      expect(events.first['run_id'], 'run-1');
      expect(events.first['step'], 'b1_r0');
      expect(events.first['current'], 3);
      expect(events.first['week_start'], getWeekStartTs());
    });
  });

  group('concurrent access', () {
    test('concurrent reads', () async {
      await addAccount('13800138000', name: '测试');
      final results = await Future.wait(
        List.generate(
          10,
          (_) async => (await getAccount('13800138000'))!.name,
        ),
      );
      expect(results.length, 10);
      expect(results.every((r) => r == '测试'), isTrue);
    });
  });

  group('getWeekStartTs', () {
    test('returns monday 00:00', () {
      // 2026-07-26 是周日；该周周一为 2026-07-20
      final sunday =
          DateTime(2026, 7, 26, 15, 30).millisecondsSinceEpoch / 1000.0;
      final mondayTs = getWeekStartTs(sunday);
      final monday =
          DateTime.fromMillisecondsSinceEpoch((mondayTs * 1000).round());
      expect(monday.year, 2026);
      expect(monday.month, 7);
      expect(monday.day, 20);
      expect(monday.hour, 0);
      expect(monday.minute, 0);
      expect(monday.second, 0);
    });

    test('monday itself stays', () {
      final monday =
          DateTime(2026, 7, 20, 9, 0).millisecondsSinceEpoch / 1000.0;
      final mondayTs = getWeekStartTs(monday);
      final dt =
          DateTime.fromMillisecondsSinceEpoch((mondayTs * 1000).round());
      expect(dt.day, 20);
      expect(dt.hour, 0);
    });
  });
}
