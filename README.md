# etalien-daily

自动领取加速器 VIP 时长，无需观看广告。

基于 [etalien-auto](https://github.com/JiangXu26710/etalien-auto) 重写，SQLite 替代 JSON 存储，protoc 编译替代手写 protobuf，新增 CLI 子命令系统和单元测试。

## 功能

- **CLI 命令行** — 完整的账号管理、登录、领取、设置
- **GUI 桌面窗口** — 无边框窗口，暗色暖琥珀主题，三卡片统计栏（账号数 / 已启用 / 总进度），账号卡片展示 VIP 时长和广告进度条，实时进度更新
- **多账号并发** — ThreadPoolExecutor，可配置并发数和请求间隔
- **登录后自动获取昵称** — 调用 my_profile 接口，自动设为备注名
- **SQLite 存储** — 账号、设置、领取历史（按自然周分组），WAL 模式并发读写
- **定时任务** — 支持 Windows Task Scheduler（schtasks）和 Windows Service 两种模式
- **防死循环** — 连续 3 轮无进展自动停止
- **领取记录持久化** — 最终结果和 GUI 过程事件均写入 SQLite，按周存储和查询，不依赖浏览器 localStorage

## 快速开始

```bash
# 安装依赖
uv sync

# CLI 模式
uv run etalien --help

# GUI 模式
uv run python -m gui.app
```

## CLI 使用

```bash
# 添加账号并登录
uv run etalien account add 13800138000 --name "主号"
uv run etalien account login 13800138000

# 管理账号
uv run etalien account list
uv run etalien account info 13800138000
uv run etalien account toggle 13800138000

# 领取
uv run etalien                           # 所有启用账号
uv run etalien --account 13800138000     # 指定账号
uv run etalien --auto-close              # 定时任务模式

# 设置
uv run etalien settings show
uv run etalien settings set max_concurrent 5
```

## 定时任务

支持两种定时执行模式，在 GUI 设置中切换：

### Schtasks（默认）

使用 Windows 计划任务，无需管理员权限。

### Windows Service

以后台服务方式运行，更稳定可靠，重启后自动恢复。

> ⚠️ **重要提示：安装或卸载 Windows Service 需要以管理员身份运行程序。** 右键 `python.exe` 或打包后的 EXE 选择"以管理员身份运行"，或在管理员终端中启动。schtasks 模式不需要管理员权限。

## 项目结构

```
etalien_daily/
├── src/etalien/
│   ├── sign.py              # SHA-256 签名算法
│   ├── client.py            # HTTP 客户端 + 重试
│   ├── service.py           # 业务逻辑 + 并发领取
│   ├── db.py                # SQLite 数据层
│   ├── main.py              # CLI 入口
│   ├── service_wrapper.py   # Windows Service 包装
│   └── proto_compiled/      # protoc 编译的 protobuf
├── gui/
│   ├── app.py               # pywebview 桌面窗口
│   ├── api.py               # Flask REST API
│   ├── __init__.py           # ClaimManager 进度追踪器
│   └── static/              # 前端 (HTML/CSS/JS)
├── tests/                   # 单元测试
└── docs/IMPLEMENTATION.md   # 协议逆向文档
```

## 参考

本项目重写自 [JiangXu26710/etalien-auto](https://github.com/JiangXu26710/etalien-auto)，主要变更：

- JSON 文件存储 → SQLite + 按周分组的领取历史
- 手写 protobuf → protoc 编译
- 单文件 CLI → argparse 子命令系统
- 新增单元测试（52 个）
- GUI 布局重设计（三卡片统计栏、VIP 时长显示、广告进度条）
- 新增 GUI 领取过程事件持久化
- 新增 Windows Service 定时模式
- 修复 pywebview 6.x 兼容性
