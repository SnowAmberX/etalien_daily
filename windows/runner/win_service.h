#ifndef RUNNER_WIN_SERVICE_H_
#define RUNNER_WIN_SERVICE_H_

// 若命令行包含 --service，则作为 Windows 服务运行（不启动 Flutter engine），
// 返回进程退出码；否则返回 -1，表示继续正常 GUI 启动流程。
//
// 服务行为（对照 v1 service_wrapper.py）：
// - 注册为 EtAlienDaily 服务，接收 STOP/SHUTDOWN 控制
// - 每 60 秒读取 exe 同级 config\schedule.ini
// - enabled=true 且 method=service 且当前时间在 time(HH:MM) ±60s 内且今日未执行
//   → CreateProcess 派生同目录 etalien_headless.exe --scheduled 并等待退出
// - 日志写入 config\service.log
int RunServiceIfRequested();

#endif  // RUNNER_WIN_SERVICE_H_
