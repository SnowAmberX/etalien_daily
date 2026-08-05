/// 定时设置同步模块。
///
/// 将数据库中的定时设置导出为 config/schedule.ini，
/// 供 runner 内嵌的 C++ 服务循环读取（服务进程无 Dart/sqlite 环境）。
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'database.dart';

/// 把当前定时设置写入 config/schedule.ini。
Future<void> syncScheduleIni({String? dbPath}) async {
  final s = await getSettings(dbPath: dbPath);
  final iniPath = p.join(p.dirname(getDbPath()), 'schedule.ini');
  final content = '[schedule]\r\n'
      'enabled=${s.scheduleEnabled}\r\n'
      'method=${s.scheduleMethod}\r\n'
      'time=${s.scheduleTime}\r\n';
  await File(iniPath).writeAsString(content, flush: true);
}
