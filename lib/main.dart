/// GUI 入口。
///
/// 模式分派：
/// - 无参数 → GUI 窗口（本文件）
/// - --service → runner C++ 层已拦截为 Windows 服务（不会到达这里）
/// - 无头领取由独立程序 bin/headless.dart（etalien_headless.exe）承担
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:window_manager/window_manager.dart';

import 'core/database.dart';
import 'ui/app.dart';
import 'ui/endfield.dart';
import 'ui/store/stores.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    const options = WindowOptions(
      size: Size(960, 720),
      minimumSize: Size(720, 540),
      center: true,
      backgroundColor: Ef.paper,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      title: '免广告领时长',
    );
    await windowManager.waitUntilReadyToShow(options, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  await initDb();
  await accountsStore.load();
  // 启动后自动刷新远程状态（不阻塞首帧）
  unawaited(accountsStore.refreshStatus());

  runApp(const EtalienApp());
}
