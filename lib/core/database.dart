/// SQLite 数据持久化模块（对照 v1 db.py）。
///
/// 使用 sqflite_common_ffi，schema 与 v1 完全一致（WAL 模式、外键约束），
/// 可与 v1 程序共用同一 etalien.db 文件。
///
/// 数据库位置:
///   优先使用环境变量 ETALIEN_CONFIG_DIR，其次：
///   - Release 模式: EXE 同级目录 config/
///   - 开发模式: 当前工作目录（项目根）config/
library;

import 'dart:io';
import 'dart:math';

import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// AOT/Release 模式为 true（Flutter release 与 dart compile exe 均为 AOT）。
const bool _isRelease = bool.fromEnvironment('dart.vm.product');

// ── 路径解析 ──────────────────────────────────────────────────────

String? _defaultConfigDir;
Database? _db;

/// 设置自定义配置目录（用于测试）。传 null 恢复默认。
void setConfigDir(String? path) {
  _defaultConfigDir = path;
}

/// 获取数据库文件路径，确保目录存在。
String getDbPath() {
  final String configDir;
  final envDir = Platform.environment['ETALIEN_CONFIG_DIR'];
  if (envDir != null && envDir.isNotEmpty) {
    configDir = envDir;
  } else if (_isRelease) {
    // 打包后：使用 EXE 同级目录下的 config/
    configDir = p.join(p.dirname(Platform.resolvedExecutable), 'config');
  } else if (_defaultConfigDir != null) {
    configDir = _defaultConfigDir!;
  } else {
    // 开发环境：使用当前工作目录（项目根）下的 config/
    configDir = p.join(Directory.current.path, 'config');
  }
  Directory(configDir).createSync(recursive: true);
  return p.join(configDir, 'etalien.db');
}

/// 返回指定时间戳所在自然周的周一 00:00 时间戳（秒）。
double getWeekStartTs([double? ts]) {
  final t = ts ?? DateTime.now().millisecondsSinceEpoch / 1000.0;
  final dt = DateTime.fromMillisecondsSinceEpoch((t * 1000).round());
  // DateTime.weekday: Monday=1 .. Sunday=7
  final monday = DateTime(dt.year, dt.month, dt.day)
      .subtract(Duration(days: dt.weekday - 1));
  return monday.millisecondsSinceEpoch / 1000.0;
}

// ── 数据库初始化 ──────────────────────────────────────────────────

const _schemaSql = '''
CREATE TABLE IF NOT EXISTS accounts (
    id         INTEGER PRIMARY KEY AUTOINCREMENT,
    phone      TEXT NOT NULL UNIQUE,
    name       TEXT DEFAULT '',
    remark     TEXT DEFAULT '',
    enabled    INTEGER DEFAULT 1,
    auth_token TEXT DEFAULT NULL,
    user_id    INTEGER DEFAULT 0,
    device_id  TEXT NOT NULL,
    password   TEXT DEFAULT '',
    last_mobile_claim REAL DEFAULT 0,
    last_translate_claim REAL DEFAULT 0,
    created_at REAL NOT NULL,
    updated_at REAL NOT NULL
);

CREATE TABLE IF NOT EXISTS settings (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS claim_history (
    id            INTEGER PRIMARY KEY AUTOINCREMENT,
    account_id    INTEGER NOT NULL REFERENCES accounts(id),
    claimed_at    REAL NOT NULL,
    vip_before    INTEGER DEFAULT 0,
    vip_after     INTEGER DEFAULT 0,
    claimed_count INTEGER DEFAULT 0,
    failed_count  INTEGER DEFAULT 0,
    status        TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS claim_events (
    id          INTEGER PRIMARY KEY AUTOINCREMENT,
    run_id      TEXT NOT NULL,
    account_id  INTEGER NOT NULL REFERENCES accounts(id),
    phone       TEXT NOT NULL,
    event_at    REAL NOT NULL,
    week_start  REAL NOT NULL,
    source      TEXT DEFAULT 'gui',
    status      TEXT NOT NULL,
    step        TEXT DEFAULT '',
    detail      TEXT DEFAULT '',
    current     INTEGER DEFAULT 0,
    total       INTEGER DEFAULT 0,
    vip_before  INTEGER DEFAULT 0,
    vip_after   INTEGER DEFAULT 0,
    error       TEXT DEFAULT ''
);
''';

Future<void> _ensureColumn(Database db, String table, String columnDef) async {
  final colName = columnDef.split(' ').first;
  final cols = await db.rawQuery('PRAGMA table_info($table)');
  final names = cols.map((r) => r['name'] as String).toSet();
  if (!names.contains(colName)) {
    await db.execute('ALTER TABLE $table ADD COLUMN $columnDef');
  }
}

/// 初始化数据库：创建表、PRAGMA 设置、写入默认值（幂等）。
Future<Database> initDb({String? dbPath}) async {
  sqfliteFfiInit();
  final path = dbPath ?? getDbPath();
  final db = await databaseFactoryFfi.openDatabase(
    path,
    options: OpenDatabaseOptions(singleInstance: false),
  );

  await db.execute('PRAGMA journal_mode=WAL');
  await db.execute('PRAGMA foreign_keys=ON');
  await db.execute(_schemaSql);

  // 幂等迁移：为旧 claim_history 表补充新列
  await _ensureColumn(db, 'claim_history', 'week_start REAL DEFAULT 0');
  await _ensureColumn(db, 'claim_history', "source TEXT DEFAULT 'service'");
  await _ensureColumn(db, 'claim_history', "detail TEXT DEFAULT ''");
  // 幂等迁移：为旧 accounts 表补充列
  await _ensureColumn(db, 'accounts', "password TEXT DEFAULT ''");
  await _ensureColumn(db, 'accounts', 'last_mobile_claim REAL DEFAULT 0');
  await _ensureColumn(db, 'accounts', 'last_translate_claim REAL DEFAULT 0');
  // 幂等迁移（2026-08-04 风控更新）：旧版补发间隔键 request_interval 已废弃，
  // 统一迁移为 backup_request_interval=10.0，无论旧值是多少都重置为 10 秒，
  // 避免触发 24h×7 补发接口风控。
  await db.delete('settings', where: 'key = ?', whereArgs: ['request_interval']);
  // 回填旧数据的 week_start（粗略用当前周）
  await db.rawUpdate(
    'UPDATE claim_history SET week_start = ? WHERE week_start IS NULL OR week_start = 0',
    [getWeekStartTs()],
  );

  // 写入默认设置（如果不存在）
  for (final entry in _defaultSettings.entries) {
    await db.rawInsert(
      'INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)',
      [entry.key, entry.value],
    );
  }

  if (dbPath == null) {
    // 缓存为共享实例，替换旧实例
    final old = _db;
    _db = db;
    if (old != null && old.isOpen) {
      await old.close();
    }
  }
  return db;
}

/// 获取共享数据库连接（懒初始化）。
Future<Database> getDb({String? dbPath}) async {
  if (dbPath != null) {
    // 指定路径时总是打开独立连接（用于测试）
    sqfliteFfiInit();
    final db = await databaseFactoryFfi.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(singleInstance: false),
    );
    await db.execute('PRAGMA journal_mode=WAL');
    await db.execute('PRAGMA foreign_keys=ON');
    return db;
  }
  return _db ??= await initDb();
}

/// 关闭共享连接（测试用）。
Future<void> closeDb() async {
  await _db?.close();
  _db = null;
}

// ── 数据模型 ──────────────────────────────────────────────────────

class Account {
  Account({
    this.id = 0,
    this.name = '',
    this.phone = '',
    this.remark = '',
    this.enabled = true,
    this.authToken,
    this.userId = 0,
    this.deviceId = '',
    this.password = '',
    this.lastMobileClaim = 0.0,
    this.lastTranslateClaim = 0.0,
    this.createdAt = 0.0,
    this.updatedAt = 0.0,
  });

  factory Account.fromRow(Map<String, Object?> row) => Account(
        id: row['id'] as int,
        name: (row['name'] as String?) ?? '',
        phone: row['phone'] as String,
        remark: (row['remark'] as String?) ?? '',
        enabled: (row['enabled'] as int? ?? 1) != 0,
        authToken: row['auth_token'] as String?,
        userId: row['user_id'] as int? ?? 0,
        deviceId: row['device_id'] as String,
        password: (row['password'] as String?) ?? '',
        lastMobileClaim: (row['last_mobile_claim'] as num?)?.toDouble() ?? 0.0,
        lastTranslateClaim:
            (row['last_translate_claim'] as num?)?.toDouble() ?? 0.0,
        createdAt: (row['created_at'] as num).toDouble(),
        updatedAt: (row['updated_at'] as num).toDouble(),
      );

  int id;
  String name;
  String phone;
  String remark;
  bool enabled;
  String? authToken;
  int userId;
  String deviceId;
  String password;
  double lastMobileClaim;
  double lastTranslateClaim;
  double createdAt;
  double updatedAt;

  bool get hasPassword => password.isNotEmpty;

  /// 转换为 Map（不含敏感 token 和密码，用于 UI 展示）。
  Map<String, Object?> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'remark': remark,
        'enabled': enabled,
        'user_id': userId,
        'device_id': deviceId,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'has_password': hasPassword,
      };
}

// ── 账号 CRUD ─────────────────────────────────────────────────────

/// 获取所有账号（默认仅启用）。
Future<List<Account>> getAccounts({
  bool enabledOnly = true,
  String? dbPath,
}) async {
  final db = await getDb(dbPath: dbPath);
  final rows = await db.query(
    'accounts',
    where: enabledOnly ? 'enabled = 1' : null,
    orderBy: 'id',
  );
  return rows.map(Account.fromRow).toList();
}

/// 根据手机号获取单个账号。
Future<Account?> getAccount(String phone, {String? dbPath}) async {
  final db = await getDb(dbPath: dbPath);
  final rows = await db.query(
    'accounts',
    where: 'phone = ?',
    whereArgs: [phone],
    limit: 1,
  );
  return rows.isEmpty ? null : Account.fromRow(rows.first);
}

/// 根据 ID 获取单个账号。
Future<Account?> getAccountById(int accountId, {String? dbPath}) async {
  final db = await getDb(dbPath: dbPath);
  final rows = await db.query(
    'accounts',
    where: 'id = ?',
    whereArgs: [accountId],
    limit: 1,
  );
  return rows.isEmpty ? null : Account.fromRow(rows.first);
}

/// 生成 25 位 hex device_id（对照 v1 uuid4().hex[:25]）。
String generateDeviceId() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(13, (_) => rnd.nextInt(256));
  return bytes
      .map((b) => b.toRadixString(16).padLeft(2, '0'))
      .join()
      .substring(0, 25);
}

/// 添加新账号。自动生成 device_id（如果未提供）和时间戳。
Future<Account> addAccount(
  String phone, {
  String name = '',
  String remark = '',
  String? deviceId,
  String password = '',
  String? dbPath,
}) async {
  final did = deviceId ?? generateDeviceId();
  final now = DateTime.now().millisecondsSinceEpoch / 1000.0;
  final db = await getDb(dbPath: dbPath);
  final id = await db.rawInsert(
    '''INSERT INTO accounts (phone, name, remark, device_id, password, created_at, updated_at)
       VALUES (?, ?, ?, ?, ?, ?, ?)''',
    [phone, name, remark, did, password, now, now],
  );
  return Account(
    id: id,
    phone: phone,
    name: name,
    remark: remark,
    deviceId: did,
    password: password,
    createdAt: now,
    updatedAt: now,
  );
}

/// 更新账号字段（白名单），自动更新 updated_at。
Future<bool> updateAccount(
  String phone, {
  String? name,
  String? remark,
  bool? enabled,
  String? authToken,
  int? userId,
  String? deviceId,
  String? password,
  double? lastMobileClaim,
  double? lastTranslateClaim,
  String? dbPath,
}) async {
  final updates = <String, Object?>{};
  if (name != null) updates['name'] = name;
  if (remark != null) updates['remark'] = remark;
  if (enabled != null) updates['enabled'] = enabled ? 1 : 0;
  if (authToken != null) updates['auth_token'] = authToken;
  if (userId != null) updates['user_id'] = userId;
  if (deviceId != null) updates['device_id'] = deviceId;
  if (password != null) updates['password'] = password;
  if (lastMobileClaim != null) updates['last_mobile_claim'] = lastMobileClaim;
  if (lastTranslateClaim != null) {
    updates['last_translate_claim'] = lastTranslateClaim;
  }
  if (updates.isEmpty) return false;

  updates['updated_at'] = DateTime.now().millisecondsSinceEpoch / 1000.0;

  final setClause = updates.keys.map((k) => '$k = ?').join(', ');
  final db = await getDb(dbPath: dbPath);
  final count = await db.rawUpdate(
    'UPDATE accounts SET $setClause WHERE phone = ?',
    [...updates.values, phone],
  );
  return count > 0;
}

/// 登录成功后保存 token 和 user_id。
Future<bool> updateAccountToken(
  String phone,
  String token,
  int userId, {
  String? dbPath,
}) {
  return updateAccount(
    phone,
    authToken: token,
    userId: userId,
    dbPath: dbPath,
  );
}

/// 删除账号及其领取历史、事件。
Future<bool> deleteAccount(String phone, {String? dbPath}) async {
  final db = await getDb(dbPath: dbPath);
  final rows = await db.query(
    'accounts',
    columns: ['id'],
    where: 'phone = ?',
    whereArgs: [phone],
    limit: 1,
  );
  if (rows.isEmpty) return false;
  final accountId = rows.first['id'] as int;
  await db.delete(
    'claim_history',
    where: 'account_id = ?',
    whereArgs: [accountId],
  );
  await db.delete(
    'claim_events',
    where: 'account_id = ?',
    whereArgs: [accountId],
  );
  await db.delete('accounts', where: 'id = ?', whereArgs: [accountId]);
  return true;
}

// ── 设置 CRUD ─────────────────────────────────────────────────────

const _defaultSettings = {
  'max_concurrent': '10',
  'backup_request_interval': '10.0',
  'max_rounds': '21',
  'mobile_max_rounds': '21',
  'translate_retry_limit': '3',
  'translate_max_rounds': '20',
  'schedule_time': '08:00',
  'schedule_enabled': 'false',
  'schedule_method': 'schtasks',
};

int _clampInt(Object? v, int min, int max) {
  final n = v is int ? v : int.tryParse(v.toString()) ?? min;
  return n.clamp(min, max);
}

double _clampDouble(Object? v, double min, double max) {
  final n = v is double ? v : double.tryParse(v.toString()) ?? min;
  return n.clamp(min, max).toDouble();
}

/// 应用设置（带类型转换）。
class Settings {
  Settings({
    this.maxConcurrent = 10,
    this.backupRequestInterval = 10.0,
    this.maxRounds = 21,
    this.mobileMaxRounds = 21,
    this.translateRetryLimit = 3,
    this.translateMaxRounds = 20,
    this.scheduleTime = '08:00',
    this.scheduleEnabled = false,
    this.scheduleMethod = 'schtasks',
  });

  int maxConcurrent;
  double backupRequestInterval;
  int maxRounds;
  int mobileMaxRounds;
  int translateRetryLimit;
  int translateMaxRounds;
  String scheduleTime;
  bool scheduleEnabled;

  /// "schtasks" 或 "service"。
  String scheduleMethod;
}

/// 获取所有设置（带类型转换与默认值）。
Future<Settings> getSettings({String? dbPath}) async {
  final db = await getDb(dbPath: dbPath);
  final rows = await db.query('settings', columns: ['key', 'value']);
  final raw = Map<String, String>.of(_defaultSettings);
  for (final row in rows) {
    raw[row['key'] as String] = row['value'] as String;
  }
  return Settings(
    maxConcurrent: _clampInt(raw['max_concurrent'], 1, 50),
    backupRequestInterval:
        _clampDouble(raw['backup_request_interval'], 0.01, 30.0),
    maxRounds: _clampInt(raw['max_rounds'], 1, 200),
    mobileMaxRounds: _clampInt(raw['mobile_max_rounds'], 1, 200),
    translateRetryLimit: _clampInt(raw['translate_retry_limit'], 1, 100),
    translateMaxRounds: _clampInt(raw['translate_max_rounds'], 1, 200),
    scheduleTime: raw['schedule_time']!,
    scheduleEnabled: raw['schedule_enabled'] == 'true',
    scheduleMethod: raw['schedule_method'] == 'service' ? 'service' : 'schtasks',
  );
}

/// 更新设置（部分更新），自动验证范围。
Future<bool> updateSettings({
  int? maxConcurrent,
  double? backupRequestInterval,
  int? maxRounds,
  int? mobileMaxRounds,
  int? translateRetryLimit,
  int? translateMaxRounds,
  String? scheduleTime,
  bool? scheduleEnabled,
  String? scheduleMethod,
  String? dbPath,
}) async {
  final updates = <String, String>{};
  if (maxConcurrent != null) {
    updates['max_concurrent'] =
        _clampInt(maxConcurrent, 1, 50).toString();
  }
  if (backupRequestInterval != null) {
    updates['backup_request_interval'] =
        _clampDouble(backupRequestInterval, 0.01, 30.0).toString();
  }
  if (maxRounds != null) {
    updates['max_rounds'] = _clampInt(maxRounds, 1, 200).toString();
  }
  if (mobileMaxRounds != null) {
    updates['mobile_max_rounds'] =
        _clampInt(mobileMaxRounds, 1, 200).toString();
  }
  if (translateRetryLimit != null) {
    updates['translate_retry_limit'] =
        _clampInt(translateRetryLimit, 1, 100).toString();
  }
  if (translateMaxRounds != null) {
    updates['translate_max_rounds'] =
        _clampInt(translateMaxRounds, 1, 200).toString();
  }
  if (scheduleTime != null) updates['schedule_time'] = scheduleTime;
  if (scheduleEnabled != null) {
    updates['schedule_enabled'] = scheduleEnabled ? 'true' : 'false';
  }
  if (scheduleMethod != null) {
    updates['schedule_method'] =
        scheduleMethod == 'service' ? 'service' : 'schtasks';
  }
  if (updates.isEmpty) return false;

  final db = await getDb(dbPath: dbPath);
  for (final entry in updates.entries) {
    await db.rawInsert(
      'INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)',
      [entry.key, entry.value],
    );
  }
  return true;
}

// ── 领取历史 ──────────────────────────────────────────────────────

/// 写入一条领取记录。
Future<void> addClaimRecord(
  int accountId,
  String status, {
  int vipBefore = 0,
  int vipAfter = 0,
  int claimedCount = 0,
  int failedCount = 0,
  double? weekStart,
  String source = 'service',
  String detail = '',
  String? dbPath,
}) async {
  final db = await getDb(dbPath: dbPath);
  await db.rawInsert(
    '''INSERT INTO claim_history
       (account_id, claimed_at, vip_before, vip_after,
        claimed_count, failed_count, status,
        week_start, source, detail)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
    [
      accountId,
      DateTime.now().millisecondsSinceEpoch / 1000.0,
      vipBefore,
      vipAfter,
      claimedCount,
      failedCount,
      status,
      weekStart ?? getWeekStartTs(),
      source,
      detail,
    ],
  );
}

/// 查询领取历史。
Future<List<Map<String, Object?>>> getClaimHistory({
  int? accountId,
  int limit = 100,
  double? weekStart,
  String? source,
  String? dbPath,
}) async {
  final db = await getDb(dbPath: dbPath);
  final where = <String>[];
  final args = <Object?>[];

  if (accountId != null) {
    where.add('ch.account_id = ?');
    args.add(accountId);
  }
  if (weekStart != null) {
    where.add('ch.week_start = ?');
    args.add(weekStart);
  }
  if (source != null) {
    where.add('ch.source = ?');
    args.add(source);
  }

  final whereSql = where.isEmpty ? '1=1' : where.join(' AND ');
  args.add(limit);

  return db.rawQuery(
    '''SELECT ch.*, a.phone
       FROM claim_history ch
       JOIN accounts a ON ch.account_id = a.id
       WHERE $whereSql
       ORDER BY ch.claimed_at DESC
       LIMIT ?''',
    args,
  );
}

// ── 领取事件日志 ──────────────────────────────────────────────────

/// 写入一条领取过程事件日志。
Future<void> addClaimEvent(
  String runId,
  int? accountId,
  String phone,
  String status, {
  String step = '',
  String detail = '',
  int current = 0,
  int total = 0,
  int vipBefore = 0,
  int vipAfter = 0,
  String error = '',
  String source = 'gui',
  String? dbPath,
}) async {
  final eventAt = DateTime.now().millisecondsSinceEpoch / 1000.0;
  final db = await getDb(dbPath: dbPath);
  await db.rawInsert(
    '''INSERT INTO claim_events
       (run_id, account_id, phone, event_at, week_start, source,
        status, step, detail, current, total,
        vip_before, vip_after, error)
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)''',
    [
      runId,
      accountId,
      phone,
      eventAt,
      getWeekStartTs(eventAt),
      source,
      status,
      step,
      detail,
      current,
      total,
      vipBefore,
      vipAfter,
      error,
    ],
  );
}

/// 查询领取过程事件。
Future<List<Map<String, Object?>>> getClaimEvents({
  double? weekStart,
  int limit = 200,
  String? dbPath,
}) async {
  final db = await getDb(dbPath: dbPath);
  if (weekStart != null) {
    return db.rawQuery(
      '''SELECT * FROM claim_events
         WHERE week_start = ?
         ORDER BY event_at DESC
         LIMIT ?''',
      [weekStart, limit],
    );
  }
  return db.rawQuery(
    '''SELECT * FROM claim_events
       ORDER BY event_at DESC
       LIMIT ?''',
    [limit],
  );
}

/// 清理超过 [keepWeeks] 周的旧事件日志。
Future<void> cleanupOldClaimEvents({
  int keepWeeks = 8,
  String? dbPath,
}) async {
  final cutoff = getWeekStartTs() - (keepWeeks * 7 * 86400);
  final db = await getDb(dbPath: dbPath);
  await db.rawDelete(
    'DELETE FROM claim_events WHERE week_start < ?',
    [cutoff],
  );
}
