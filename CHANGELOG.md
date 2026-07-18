# Changelog

All notable changes to etalien-daily will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.3.1] - 2026-07-18

### Changed
- UI 全面升级为液态玻璃风格浅色主题：
  - 背景改为浅色底 + 四色 ambient 光斑固定背景（液态玻璃折射基底）
  - 统一玻璃材质：渐变半透明 + `backdrop-filter: blur + saturate` + 边缘高光内阴影（顶部亮边 / 底部暗边）
  - 所有按钮改为透明液态玻璃胶囊：hover 变亮浮起、按压 `scale(0.97)` 下沉
  - 窗口控制按钮改为圆形玻璃按钮；卡片、模态框、Toast、进度条、登录分段控件、滚动条统一玻璃语言
- Toggle 滑块改为扁平圆形透明玻璃板：半透明 + 玻璃边缘亮线 + 扁平投影，透出轨道颜色；保留点击/拖拽放大（`scale(1.18)`）交互
- 窗口启动底色 `#0b0b0d` → `#e9ebf1`，匹配浅色主题

### Fixed
- 修复 Toggle 滑块点击/拖拽放大时垂直偏下：定位改为上下等距结构性居中，并移除滑块 `backdrop-filter`（Chromium 中 `backdrop-filter` 与 `transform: scale` 叠加存在合成层位置偏移 bug）
- 修复历史记录弹窗引用失效的 CSS 变量（`--sage`/`--ember`/`--amber` → `--green`/`--red`/`--accent`）
- 修复 `#app` 未声明 flex 布局导致主区域高度异常

## [1.3.0] - 2026-07-22

### Added
- 翻译次数领取完整功能：
  - `fetch_translate_product()`（POST /v2/account/translate/product/list，Member proto）
  - `fetch_translate_ad_config()`（POST /v2/account/translate/ad/config，PcAdConfigResponse，4 阶段共 15 广告）
  - `_claim_translate_phase()`：配置驱动循环，基于 ad/config 的 watched/total 进度，`translate_max_rounds`（默认 20）、`translate_retry_limit`（默认 3）
  - `_safe_parse_translate_count()`：安全解析 MessageToDict 返回的字符串 expire_time（兼容缺失/空/非法值）
  - 翻译次数显示在账号卡片 VIP 行（「翻译: N次」，失败时「翻译: 查询失败」，0 次也显示）
- 翻译常量：`TRANSLATE_AD_ID = "103579416"`、`TRANSLATE_BUSINESS = 3`
- 新增「翻译」领取按钮，独立进度条 `data-progress-phase="translate"`
- 进度条 phase 标识：PC/手机/翻译三种进度条均添加 `data-progress-phase` 和 `data-progress-label` 属性
- `proto_decode.py`：命令行 Protobuf 反序列化工具，支持 hex/base64 输入
- DB 设置项：`translate_max_rounds`（默认 20）、`translate_retry_limit`（默认 3）
- 翻译领取每 3 天执行一次（`last_translate_claim` 字段）

### Changed
- `updateCardProgress(phone, phase, current, total)`：使用属性选择器精确定位对应 phase 的进度条，保留前缀（PC / 手机 / 翻译）
- 后端 `_progress_callback` 根据 step 前缀自动检测 phase：`b`/`config` → pc，`m_`/`mobile` → mobile，`t_`/`translate` → translate
- 顶部统计 `recalcStatsFromCards()` 仅按 `data-progress-phase="pc"` 聚合，不再混入手机/翻译数据
- 最终结果更新根据领取 `target` 设置正确的 phase
- 移动端 `_report` 调用新增 `current`/`total` 参数

### Removed
- 废弃 `TranslateProductResponse` proto（已被 Member 替代，proto 定义保留）

### Fixed
- 修复领取时进度条更新到错误 phase（`querySelector` 始终命中第一个 PC 进度条，手机领取也受影响）
- 修复 `_claim_business_phase` 中误放的 `translate_retry_limit` 常量和日志

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
