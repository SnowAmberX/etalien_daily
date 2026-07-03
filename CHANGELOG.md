# Changelog

All notable changes to etalien-daily will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.2] - 2026-07-22

### Added
- 翻译次数领取功能：`fetch_translate_product()` / `fetch_translate_ad_config()` 接口
- 翻译次数显示在账号卡片（VIP 行追加「翻译: N次」）
- 新增「翻译」领取按钮
- `TranslateProductResponse` proto 消息
- `proto_decode.py`：命令行 Protobuf 反序列化工具

### Changed
- 翻译领取同样每 3 天执行一次（`last_translate_claim` 字段）

## [1.2.1] - 2026-07-22

### Changed
- 手机端领取改为每 3 天执行一次（`last_mobile_claim` 时间戳记录）

## [1.2.0]

### Added
- 密码登录支持：LoginV2 proto、`login_by_password()` API、token 过期自动密码重登
- 手机端时长领取：`fetch_mobile_ad_activity()` + 手机端领取循环（`_claim_mobile_phase`）
- `mobile_duration`、`mobile_current`、`mobile_total` 加入 `/api/status` 响应
- 账号卡片显示手机端进度条和时长
- 领取按钮支持「全部 / 仅 PC / 仅手机」三种模式
- `TimedRotatingFileHandler` 日志按天轮转（CLI + Windows 服务）
- `EXIT_NETWORK_ERROR = 5` 退出码
- 液态玻璃 Apple 亮色主题全套重设计
- Toggle 开关拖拽交互（带液态玻璃缩放效果）
- 标题栏图标重设计（精简齿轮 + 时钟回环箭头）

### Changed
- 色彩体系：暗色琥珀 → Apple 亮色（#f0f0f2 背景 + #0071e3 蓝色 accent）
- 卡片、模态框、Toast、标题栏全面采用 `backdrop-filter: blur()` 玻璃效果
- 圆角 8px → 14px，阴影从无到 4 级体系
- 按钮改为 tinted 风格（半透蓝底 + 蓝字）
- 进度条静态化（去掉 shimmer 动画）
- 全局动画曲线升级为 `cubic-bezier(0.22, 1, 0.36, 1)`
- 模态框滚动条裁切至圆角内
- 设置弹窗禁止点击外部关闭

### Fixed
- 标题栏图标放大到 22px（原 18px 过小）
- 手机端 emoji 改为文字「手机」

## [1.1.1] - 2026-07-01

### Added
- 运行跟踪与事件日志功能（`claim_events` 表、领取过程实时记录）
- `/api/status` 改进：并发查询所有账号、返回广告进度和 VIP 时长

### Changed
- 更新 README.md：补充 Windows Service 定时模式、按周分组领取历史、GUI 增强说明

### Fixed
- 修复观看数量统计问题（已观看广告计数不准确）

## [1.1.0] - 2026-06-28

### Added
- Windows 服务模式（`--service`）：纯 ctypes 实现，零外部依赖，通过 `sc create` 安装
- 定时任务功能：支持 `schtasks` 计划任务和 Windows 服务两种方式
- 静默运行模式（`--scheduled`）：定时任务触发时不弹出窗口
- GUI 设置页：定时领取开关、时间设置、实现方式选择（schtasks / 服务）
- 服务安装/卸载 API（`/api/schedule/install-service`、`/api/schedule/uninstall-service`）

### Fixed
- 修复 Windows 服务创建失败问题
- 修复 64 位 Windows 服务兼容性（ctypes 指针类型）
- 改进服务状态报告逻辑

## [1.0.0] - 2026-06-20

### Added
- 初始版本：CLI + GUI 桌面应用
- SQLite 数据持久化（`db.py`）：账号管理、设置、领取历史
- HTTP 客户端（`client.py`）：Protobuf 序列化、请求签名、自动重试
- 业务编排（`service.py`）：单账号领取、多账号并发（ThreadPoolExecutor）
- 图形界面（`pywebview + Flask`）：无边框窗口、账号管理、实时进度
- GUI 功能：登录（短信验证码）、账号 CRUD、领取进度、历史记录
- GitHub Actions 自动构建和发布（PyInstaller 打包）
- 项目 Logo 和 `.spec` 打包配置
