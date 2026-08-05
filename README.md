# etalien-daily

自动领取加速器 VIP 时长，无需观看广告。

> **⚠️ 补发接口风控说明（2026-08-04）**
>
> 经过验证，账号调用补发接口如果间隔低于 **8 秒**，将触发风控，具体表现为 **24h×7 补发接口禁用**。
>
> 本项目处理方式：默认间隔统一为 **10 秒**；升级后无论原间隔是多少都会重置为 10 秒；在设置中把间隔调到 8 秒以下时，会弹窗提示风控风险（仅提示，不阻止保存）。

## 简介

- **v2 已用 Flutter 重构**（Windows 桌面端），核心业务由 Dart 实现，无边框窗口 + Endfield 风格浅色 UI。
- **v1（旧 Python 版本）完整归档在 `v1/` 目录**，仅作存档，不再维护。
- v2 与 v1 **共用 `config/etalien.db`**：账号、token、领取历史、设置互通，升级后直接读取原有数据。

## 功能

- **GUI 桌面窗口** — 无边框窗口，三统计卡片（账号数 / 已启用 / 总进度），账号卡片展示 VIP 时长与领取进度，实时更新
- **多账号并发** — Dart async 并发领取，可配置并发数和补发接口请求间隔
- **三种领取目标** — PC 时长 / 手机时长 / 翻译次数
- **登录** — 短信验证码 / 账号密码双方式，token 过期可用密码自动重登
- **SQLite 存储** — 账号、设置、领取历史、过程事件，WAL 模式并发读写，与 v1 共用同一数据库
- **定时领取** — schtasks（默认，以 SYSTEM 非交互运行，需要管理员创建）与 Windows Service 两种模式
- **无头模式** — 独立无头程序供定时任务 / 服务调用，退出码对齐 v1
- **防死循环** — 连续 3 轮无进展自动停止

## 环境要求

- Windows 10/11
- Flutter SDK（stable，含 Windows desktop）— 仅开发 / 打包需要
- Visual Studio（勾选“使用 C++ 的桌面开发”工作负载）— 仅打包需要

## 开发运行

```bash
flutter pub get
flutter run -d windows
```

## 打包

```bash
# GUI 程序（产物在 build/windows/x64/runner/Release/）
flutter build windows

# 无头领取程序（sqlite3 含原生库，须使用 dart build cli）
dart build cli -o build/headless -t bin/headless.dart
# 产物在 build/headless/bundle/（bin/headless.exe + lib/sqlite3.dll）
# 发布时与 GUI 程序放在同一目录：
#   bin/headless.exe → <程序目录>/bin/etalien_headless.exe
#   lib/sqlite3.dll  → <程序目录>/lib/sqlite3.dll
```

## 无头模式

供定时任务 / Windows Service / 命令行调用：

```bash
etalien_headless.exe [--scheduled] [--account <phone>] [--target all|pc|mobile|translate]
```

退出码：`0` 全部成功 / `1` 部分成功 / `2` 全部失败 / `3` 需要登录 / `4` 无启用账号 / `5` 网络错误。

## 定时任务

在 GUI 设置中切换两种模式：

- **Schtasks（默认）** — Windows 计划任务，以 SYSTEM 非交互运行，用户未登录也会领取；创建/覆盖任务需要管理员权限
- **Windows Service** — 以后台服务方式运行，更稳定，重启后自动恢复；安装 / 卸载需要以管理员身份运行程序

## 设置

GUI 设置弹窗支持：并发数、补发接口请求间隔（默认 10s，低于 8s 失焦时弹窗提示风控风险）、各领取目标最大轮数、定时时间与实现方式。设置保存在 `config/etalien.db` 中。

## 项目结构

```
etalien_daily/
├── lib/
│   ├── main.dart               # GUI 入口
│   ├── core/                   # 核心业务（纯 Dart）
│   │   ├── sign.dart           # SHA-256 签名
│   │   ├── api_client.dart     # HTTP 客户端 + 重试 + token 管理
│   │   ├── database.dart       # SQLite 数据层（与 v1 共用库）
│   │   ├── claim_service.dart  # 领取业务（PC/手机/翻译 + 防死循环 + 并发）
│   │   └── proto/              # protobuf 编译产物
│   ├── platform/               # schtasks / Windows Service / 调度
│   └── ui/                     # 无边框窗口、页面、弹窗、状态管理
├── bin/headless.dart           # 无头领取程序
├── test/                       # Dart 单元测试
├── windows/                    # Windows runner（含 Windows Service 宿主）
├── v1/                         # 旧 Python 版归档（存档，不再维护）
└── config/                     # 数据目录（etalien.db）
```
