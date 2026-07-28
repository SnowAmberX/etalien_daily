/// schtasks 定时任务管理（对照 v1 gui/api.py）。
library;

import 'dart:io';

import '../core/database.dart';
import '../core/schedule_config.dart';

/// 与 v1 同名，接管既有任务。
const String kSchtaskName = 'EtAlienAuto_DailyClaim';

/// headless 程序路径（exe 同级 bin\etalien_headless.exe，
/// dart build cli bundle 结构：bin\exe + lib\sqlite3.dll）。
String headlessExePath() {
  final exeDir = File(Platform.resolvedExecutable).parent.path;
  return '$exeDir\\bin\\etalien_headless.exe';
}

/// schtasks 要执行的命令行。
String schtaskCommand() => '"${headlessExePath()}" --scheduled';

/// 查询定时任务是否存在。
Future<bool> schtaskExists() async {
  try {
    final r = await Process.run('schtasks', ['/query', '/tn', kSchtaskName]);
    return r.exitCode == 0;
  } catch (_) {
    return false;
  }
}

/// 创建/覆盖每日定时任务。成功返回 null，失败返回错误信息。
Future<String?> schtaskCreate(String scheduleTime) async {
  try {
    final r = await Process.run('schtasks', [
      '/create',
      '/tn',
      kSchtaskName,
      '/tr',
      schtaskCommand(),
      '/sc',
      'daily',
      '/st',
      scheduleTime,
      '/f',
    ]);
    if (r.exitCode != 0) {
      final err = (r.stderr as String).trim();
      return err.isEmpty ? 'schtasks /create 失败 (${r.exitCode})' : err;
    }
    return null;
  } catch (e) {
    return 'schtasks 不可用: $e';
  }
}

/// 删除定时任务。成功或任务不存在返回 null。
Future<String?> schtaskDelete() async {
  try {
    final r = await Process.run(
        'schtasks', ['/delete', '/tn', kSchtaskName, '/f']);
    if (r.exitCode != 0) {
      final err = (r.stderr as String).trim();
      return err.isEmpty ? 'schtasks /delete 失败 (${r.exitCode})' : err;
    }
    return null;
  } catch (_) {
    return null; // schtasks 不可用视为成功（v1 语义）
  }
}

/// 按当前数据库设置应用 schtasks 调度（创建/删除）并同步 schedule.ini。
///
/// 仅处理 schtasks 模式；service 模式由 service_installer 处理。
/// 成功返回 null，失败返回错误信息。
Future<String?> applySchtasksSchedule({String? dbPath}) async {
  final s = await getSettings(dbPath: dbPath);
  String? err;
  if (s.scheduleMethod == 'schtasks') {
    err = s.scheduleEnabled
        ? await schtaskCreate(s.scheduleTime)
        : await schtaskDelete();
  }
  await syncScheduleIni(dbPath: dbPath);
  return err;
}
