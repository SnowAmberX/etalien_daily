/// Windows Service 安装/卸载/状态管理（对照 v1 gui/api.py）。
///
/// 安装/卸载需要管理员权限（sc create/delete）。
library;

import 'dart:io';

import '../core/database.dart';
import '../core/schedule_config.dart';
import 'scheduler.dart';

const String kServiceName = 'EtAlienDaily';
const String kServiceDisplayName = 'ET Alien Daily Claim Service';

/// 定时调度综合状态。
class ScheduleStatus {
  const ScheduleStatus({
    required this.schtasks,
    required this.serviceInstalled,
    required this.serviceRunning,
  });

  final bool schtasks;
  final bool serviceInstalled;
  final bool serviceRunning;
}

/// 综合查询定时任务状态（schtasks + Windows Service）。
Future<ScheduleStatus> queryScheduleStatus() async {
  var schtasksOk = false;
  var installed = false;
  var running = false;

  try {
    final r = await Process.run('schtasks', ['/query', '/tn', kSchtaskName]);
    schtasksOk = r.exitCode == 0;
  } catch (_) {}

  try {
    final r = await Process.run('sc', ['query', kServiceName]);
    if (r.exitCode == 0) {
      installed = true;
      running = (r.stdout as String).contains('RUNNING');
    }
  } catch (_) {}

  return ScheduleStatus(
    schtasks: schtasksOk,
    serviceInstalled: installed,
    serviceRunning: running,
  );
}

String _errOf(ProcessResult r, String fallback) {
  final err = (r.stderr as String).trim();
  if (err.isNotEmpty) return err;
  final out = (r.stdout as String).trim();
  return out.isNotEmpty ? out : fallback;
}

/// 安装并启动 Windows 服务（需要管理员权限）。
///
/// 流程（对照 v1）：清理旧服务 → 创建 → 启动 → 设置切到 service 模式
/// → 同步 schedule.ini → 删除旧 schtasks 避免重复执行。
/// 成功返回 null，失败返回错误信息。
Future<String?> installService() async {
  final exePath = Platform.resolvedExecutable;

  try {
    // 已存在则停止并删除旧服务
    final q = await Process.run('sc', ['query', kServiceName]);
    if (q.exitCode == 0) {
      await Process.run('sc', ['stop', kServiceName]);
      final del = await Process.run('sc', ['delete', kServiceName]);
      if (del.exitCode != 0) {
        return '删除旧服务失败: ${_errOf(del, '未知错误')}';
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }

    // 创建服务
    final create = await Process.run('sc', [
      'create',
      kServiceName,
      'binPath=',
      '"$exePath" --service',
      'start=',
      'auto',
      'DisplayName=',
      kServiceDisplayName,
    ]);
    if (create.exitCode != 0) {
      return '服务创建失败: ${_errOf(create, '未知错误')}（需要以管理员身份运行）';
    }

    // 启动服务
    final start = await Process.run('sc', ['start', kServiceName]);
    if (start.exitCode != 0) {
      return '服务启动失败: ${_errOf(start, '未知错误')}';
    }

    // 同步设置：启用定时 + 服务模式
    final s = await getSettings();
    await updateSettings(
      scheduleEnabled: true,
      scheduleMethod: 'service',
      scheduleTime: s.scheduleTime,
    );
    await syncScheduleIni();

    // 删除旧的 schtasks 避免重复执行
    await schtaskDelete();

    return null;
  } on ProcessException catch (e) {
    return 'sc 不可用: $e';
  }
}

/// 停止并卸载 Windows 服务，设置回退到 schtasks 模式。
/// 成功返回 null，失败返回错误信息。
Future<String?> uninstallService() async {
  try {
    await Process.run('sc', ['stop', kServiceName]);
    final del = await Process.run('sc', ['delete', kServiceName]);
    if (del.exitCode != 0) {
      final err = _errOf(del, '未知错误');
      // 服务本来就不存在也算成功（v1 语义：1060 / not exist）
      if (!err.contains('1060') && !err.toLowerCase().contains('not exist')) {
        return '服务删除失败: $err';
      }
    }

    await updateSettings(scheduleEnabled: false, scheduleMethod: 'schtasks');
    await syncScheduleIni();

    return null;
  } on ProcessException {
    // sc 不可用视为成功（v1 语义）
    return null;
  }
}
