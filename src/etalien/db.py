"""SQLite 数据持久化模块。

零外部依赖（仅 stdlib sqlite3）。替代文档中的明文 JSON 方案。
使用 WAL 模式支持并发读写，外键约束保证引用完整性。

数据库位置:
    优先使用环境变量 ETALIEN_CONFIG_DIR，其次为项目根目录下的 config/。
    数据库文件: <config_dir>/etalien.db
"""

import datetime
import os
import sqlite3
import sys
import time
import uuid
from dataclasses import dataclass, field
from typing import Any

# ── 路径解析 ──────────────────────────────────────────────────────

_DEFAULT_CONFIG_DIR: str | None = None


def set_config_dir(path: str) -> None:
    """设置自定义配置目录（用于测试）。"""
    global _DEFAULT_CONFIG_DIR
    _DEFAULT_CONFIG_DIR = path


def get_db_path() -> str:
    """获取数据库文件路径，确保目录存在。"""
    if "ETALIEN_CONFIG_DIR" in os.environ:
        config_dir = os.environ["ETALIEN_CONFIG_DIR"]
    elif getattr(sys, "frozen", False):
        # PyInstaller 打包后：使用 EXE 同级目录下的 config/
        config_dir = os.path.join(os.path.dirname(sys.executable), "config")
    elif _DEFAULT_CONFIG_DIR:
        config_dir = _DEFAULT_CONFIG_DIR
    else:
        # 开发环境：使用项目根目录下的 config/
        config_dir = os.path.join(
            os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))),
            "config",
        )
    os.makedirs(config_dir, exist_ok=True)
    return os.path.join(config_dir, "etalien.db")


# ── 数据库初始化 ──────────────────────────────────────────────────

def get_week_start_ts(ts: float | None = None) -> float:
    """返回指定时间戳所在自然周的周一 00:00 时间戳。

    Args:
        ts: Unix 时间戳，为 None 时使用当前时间。

    Returns:
        该周周一零点的 Unix 时间戳。
    """
    if ts is None:
        ts = time.time()
    dt = datetime.datetime.fromtimestamp(ts)
    monday = dt - datetime.timedelta(days=dt.weekday())
    monday = monday.replace(hour=0, minute=0, second=0, microsecond=0)
    return monday.timestamp()


def _ensure_column(conn: sqlite3.Connection, table: str, column_def: str) -> None:
    """幂等添加列——如果列不存在则在表中添加。

    Args:
        conn: 数据库连接。
        table: 表名。
        column_def: 列定义，例如 "week_start REAL DEFAULT 0"。
    """
    col_name = column_def.split()[0]
    cols = [row[1] for row in conn.execute(f"PRAGMA table_info({table})").fetchall()]
    if col_name not in cols:
        conn.execute(f"ALTER TABLE {table} ADD COLUMN {column_def}")


def init_db(db_path: str | None = None) -> None:
    """初始化数据库：创建表、PRAGMA 设置、写入默认值（幂等）。"""
    if db_path is None:
        db_path = get_db_path()

    with sqlite3.connect(db_path) as conn:
        conn.execute("PRAGMA journal_mode=WAL")
        conn.execute("PRAGMA foreign_keys=ON")

        conn.executescript(_SCHEMA_SQL)

        # 幂等迁移：为旧 claim_history 表补充新列
        _ensure_column(conn, "claim_history", "week_start REAL DEFAULT 0")
        _ensure_column(conn, "claim_history", "source TEXT DEFAULT 'service'")
        _ensure_column(conn, "claim_history", "detail TEXT DEFAULT ''")
        # 幂等迁移：为旧 accounts 表补充 password 列
        _ensure_column(conn, "accounts", "password TEXT DEFAULT ''")
        _ensure_column(conn, "accounts", "last_mobile_claim REAL DEFAULT 0")
        # 回填旧数据的 week_start（粗略用当前周）
        conn.execute(
            "UPDATE claim_history SET week_start = ? WHERE week_start IS NULL OR week_start = 0",
            (get_week_start_ts(),),
        )

        # 写入默认设置（如果不存在）
        now = time.time()
        defaults = [
            ("max_concurrent", "10"),
            ("request_interval", "1.0"),
            ("max_rounds", "21"),
            ("mobile_max_rounds", "21"),
            ("schedule_time", "08:00"),
            ("schedule_enabled", "false"),
            ("schedule_method", "schtasks"),
        ]
        for key, value in defaults:
            conn.execute(
                "INSERT OR IGNORE INTO settings (key, value) VALUES (?, ?)",
                (key, value),
            )


_SCHEMA_SQL = """
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
"""


# ── 连接工厂 ─────────────────────────────────────────────────────

def get_connection(db_path: str | None = None) -> sqlite3.Connection:
    """获取数据库连接（WAL 模式，支持并发读）。"""
    if db_path is None:
        db_path = get_db_path()
    conn = sqlite3.connect(db_path)
    conn.execute("PRAGMA journal_mode=WAL")
    conn.execute("PRAGMA foreign_keys=ON")
    conn.row_factory = sqlite3.Row
    return conn


# ── 数据模型 ──────────────────────────────────────────────────────

@dataclass
class Account:
    name: str = ""
    phone: str = ""
    remark: str = ""
    enabled: bool = True
    auth_token: str | None = None
    user_id: int = 0
    device_id: str = ""
    password: str = ""
    last_mobile_claim: float = 0.0
    id: int = 0
    created_at: float = 0.0
    updated_at: float = 0.0

    def to_dict(self) -> dict[str, Any]:
        """转换为 dict（不含敏感 token 和密码，用于 API 返回）。"""
        return {
            "name": self.name,
            "phone": self.phone,
            "remark": self.remark,
            "enabled": self.enabled,
            "user_id": self.user_id,
            "device_id": self.device_id,
            "id": self.id,
            "created_at": self.created_at,
            "updated_at": self.updated_at,
            "has_password": bool(self.password),
        }


def _account_from_row(row: sqlite3.Row) -> Account:
    """从数据库行转换为 Account 对象。"""
    return Account(
        id=row["id"],
        name=row["name"],
        phone=row["phone"],
        remark=row["remark"],
        enabled=bool(row["enabled"]),
        auth_token=row["auth_token"],
        user_id=row["user_id"],
        device_id=row["device_id"],
        password=row["password"] if "password" in row.keys() else "",
        last_mobile_claim=row["last_mobile_claim"] if "last_mobile_claim" in row.keys() else 0.0,
        created_at=row["created_at"],
        updated_at=row["updated_at"],
    )


# ── 账号 CRUD ─────────────────────────────────────────────────────

def get_accounts(enabled_only: bool = True, db_path: str | None = None) -> list[Account]:
    """获取所有账号。"""
    conn = get_connection(db_path)
    try:
        if enabled_only:
            rows = conn.execute(
                "SELECT * FROM accounts WHERE enabled = 1 ORDER BY id"
            ).fetchall()
        else:
            rows = conn.execute(
                "SELECT * FROM accounts ORDER BY id"
            ).fetchall()
        return [_account_from_row(r) for r in rows]
    finally:
        conn.close()


def get_account(phone: str, db_path: str | None = None) -> Account | None:
    """根据手机号获取单个账号。"""
    conn = get_connection(db_path)
    try:
        row = conn.execute(
            "SELECT * FROM accounts WHERE phone = ?", (phone,)
        ).fetchone()
        return _account_from_row(row) if row else None
    finally:
        conn.close()


def get_account_by_id(account_id: int, db_path: str | None = None) -> Account | None:
    """根据 ID 获取单个账号。"""
    conn = get_connection(db_path)
    try:
        row = conn.execute(
            "SELECT * FROM accounts WHERE id = ?", (account_id,)
        ).fetchone()
        return _account_from_row(row) if row else None
    finally:
        conn.close()


def add_account(
    phone: str,
    name: str = "",
    remark: str = "",
    device_id: str | None = None,
    password: str = "",
    db_path: str | None = None,
) -> Account:
    """添加新账号。

    自动生成 device_id（如果未提供）和时间戳。
    """
    if device_id is None:
        device_id = uuid.uuid4().hex[:25]

    now = time.time()
    conn = get_connection(db_path)
    try:
        conn.execute(
            """INSERT INTO accounts (phone, name, remark, device_id, password, created_at, updated_at)
               VALUES (?, ?, ?, ?, ?, ?, ?)""",
            (phone, name, remark, device_id, password, now, now),
        )
        conn.commit()
        return Account(
            phone=phone,
            name=name,
            remark=remark,
            device_id=device_id,
            password=password,
            created_at=now,
            updated_at=now,
            id=conn.execute("SELECT last_insert_rowid()").fetchone()[0],
        )
    finally:
        conn.close()


def update_account(phone: str, db_path: str | None = None, **fields) -> bool:
    """更新账号字段。

    支持的字段: name, remark, enabled, auth_token, user_id, device_id
    自动更新 updated_at。
    """
    allowed = {"name", "remark", "enabled", "auth_token", "user_id", "device_id", "password", "last_mobile_claim"}
    updates = {k: v for k, v in fields.items() if k in allowed}
    if not updates:
        return False

    updates["updated_at"] = time.time()

    set_clause = ", ".join(f"{k} = ?" for k in updates)
    values = list(updates.values()) + [phone]

    conn = get_connection(db_path)
    try:
        cursor = conn.execute(
            f"UPDATE accounts SET {set_clause} WHERE phone = ?",
            values,
        )
        conn.commit()
        return cursor.rowcount > 0
    finally:
        conn.close()


def update_account_token(
    phone: str,
    token: str,
    user_id: int,
    db_path: str | None = None,
) -> bool:
    """登录成功后保存 token 和 user_id。"""
    return update_account(phone, auth_token=token, user_id=user_id, db_path=db_path)


def delete_account(phone: str, db_path: str | None = None) -> bool:
    """删除账号及其领取历史。"""
    conn = get_connection(db_path)
    try:
        # 先查 id
        row = conn.execute(
            "SELECT id FROM accounts WHERE phone = ?", (phone,)
        ).fetchone()
        if not row:
            return False
        account_id = row["id"]
        # 删除关联的领取历史
        conn.execute("DELETE FROM claim_history WHERE account_id = ?", (account_id,))
        # 删除账号
        conn.execute("DELETE FROM accounts WHERE id = ?", (account_id,))
        conn.commit()
        return True
    finally:
        conn.close()


# ── 设置 CRUD ─────────────────────────────────────────────────────

_DEFAULT_SETTINGS = {
    "max_concurrent": "10",
    "request_interval": "1.0",
    "max_rounds": "21",
    "mobile_max_rounds": "21",
    "schedule_time": "08:00",
    "schedule_enabled": "false",
    "schedule_method": "schtasks",
}

_SETTINGS_VALIDATORS = {
    "max_concurrent": lambda v: max(1, min(50, int(v))),
    "request_interval": lambda v: max(0.1, min(30.0, float(v))),
    "max_rounds": lambda v: max(1, min(200, int(v))),
    "mobile_max_rounds": lambda v: max(1, min(200, int(v))),
    "schedule_time": lambda v: str(v),
    "schedule_enabled": lambda v: "true" if str(v).lower() in ("true", "1", "yes") else "false",
    "schedule_method": lambda v: v if str(v) in ("schtasks", "service") else "schtasks",
}


def get_settings(db_path: str | None = None) -> dict[str, Any]:
    """获取所有设置，返回带类型转换的 dict。"""
    conn = get_connection(db_path)
    try:
        rows = conn.execute("SELECT key, value FROM settings").fetchall()
        result = dict(_DEFAULT_SETTINGS)
        for row in rows:
            result[row["key"]] = row["value"]

        # 类型转换
        if "max_concurrent" in result:
            result["max_concurrent"] = int(result["max_concurrent"])
        if "request_interval" in result:
            result["request_interval"] = float(result["request_interval"])
        if "max_rounds" in result:
            result["max_rounds"] = int(result["max_rounds"])
        if "mobile_max_rounds" in result:
            result["mobile_max_rounds"] = int(result["mobile_max_rounds"])
        if "schedule_enabled" in result:
            result["schedule_enabled"] = result["schedule_enabled"] == "true"

        return result
    finally:
        conn.close()


def update_settings(db_path: str | None = None, **kwargs) -> bool:
    """更新设置（部分更新），自动验证范围。"""
    allowed = {"max_concurrent", "request_interval", "max_rounds", "mobile_max_rounds", "schedule_time", "schedule_enabled", "schedule_method"}
    updates = {k: v for k, v in kwargs.items() if k in allowed}
    if not updates:
        return False

    # 验证并钳位
    for key, validator in _SETTINGS_VALIDATORS.items():
        if key in updates:
            updates[key] = str(validator(updates[key]))

    conn = get_connection(db_path)
    try:
        for key, value in updates.items():
            conn.execute(
                "INSERT OR REPLACE INTO settings (key, value) VALUES (?, ?)",
                (key, value),
            )
        conn.commit()
        return True
    finally:
        conn.close()


# ── 领取历史 ──────────────────────────────────────────────────────

def add_claim_record(
    account_id: int,
    status: str,
    vip_before: int = 0,
    vip_after: int = 0,
    claimed_count: int = 0,
    failed_count: int = 0,
    week_start: float | None = None,
    source: str = "service",
    detail: str = "",
    db_path: str | None = None,
) -> None:
    """写入一条领取记录。"""
    if week_start is None:
        week_start = get_week_start_ts()
    conn = get_connection(db_path)
    try:
        conn.execute(
            """INSERT INTO claim_history
               (account_id, claimed_at, vip_before, vip_after,
                claimed_count, failed_count, status,
                week_start, source, detail)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (account_id, time.time(), vip_before, vip_after,
             claimed_count, failed_count, status,
             week_start, source, detail),
        )
        conn.commit()
    finally:
        conn.close()


def get_claim_history(
    account_id: int | None = None,
    limit: int = 100,
    week_start: float | None = None,
    source: str | None = None,
    db_path: str | None = None,
) -> list[dict]:
    """查询领取历史。

    Args:
        account_id: 按账号 id 筛选，None 为全部。
        limit: 最大返回条数。
        week_start: 按周起始时间戳筛选，None 为不限制。
        source: 按来源筛选（"service"/"gui"），None 为不限制。
    """
    conn = get_connection(db_path)
    try:
        where_clauses = []
        params = []

        if account_id is not None:
            where_clauses.append("ch.account_id = ?")
            params.append(account_id)
        if week_start is not None:
            where_clauses.append("ch.week_start = ?")
            params.append(week_start)
        if source is not None:
            where_clauses.append("ch.source = ?")
            params.append(source)

        where_sql = " AND ".join(where_clauses) if where_clauses else "1=1"
        params.append(limit)

        rows = conn.execute(
            f"""SELECT ch.*, a.phone
               FROM claim_history ch
               JOIN accounts a ON ch.account_id = a.id
               WHERE {where_sql}
               ORDER BY ch.claimed_at DESC
               LIMIT ?""",
            params,
        ).fetchall()
        return [dict(row) for row in rows]
    finally:
        conn.close()


# ── 领取事件日志 ──────────────────────────────────────────────────

def add_claim_event(
    run_id: str,
    account_id: int | None,
    phone: str,
    status: str,
    step: str = "",
    detail: str = "",
    current: int = 0,
    total: int = 0,
    vip_before: int = 0,
    vip_after: int = 0,
    error: str = "",
    source: str = "gui",
    db_path: str | None = None,
) -> None:
    """写入一条领取过程事件日志。

    Args:
        run_id: 本次领取运行的唯一 ID。
        account_id: 关联账号 id。
        phone: 手机号。
        status: 状态标签。
        step: 步骤名（如 "config", "b1_r0", "done"）。
        detail: 步骤描述。
        current: 当前已完成数。
        total: 总任务数。
        vip_before: 领取前 VIP 时长（秒）。
        vip_after: 领取后 VIP 时长（秒）。
        error: 错误信息。
        source: 来源，默认 "gui"。
    """
    event_at = time.time()
    week_start = get_week_start_ts(event_at)
    conn = get_connection(db_path)
    try:
        conn.execute(
            """INSERT INTO claim_events
               (run_id, account_id, phone, event_at, week_start, source,
                status, step, detail, current, total,
                vip_before, vip_after, error)
               VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)""",
            (run_id, account_id, phone, event_at, week_start, source,
             status, step, detail, current, total,
             vip_before, vip_after, error),
        )
        conn.commit()
    finally:
        conn.close()


def get_claim_events(
    week_start: float | None = None,
    limit: int = 200,
    db_path: str | None = None,
) -> list[dict]:
    """查询领取过程事件。

    Args:
        week_start: 按周筛选，None 为不限制。
        limit: 最大返回条数。
    """
    conn = get_connection(db_path)
    try:
        if week_start is not None:
            rows = conn.execute(
                """SELECT * FROM claim_events
                   WHERE week_start = ?
                   ORDER BY event_at DESC
                   LIMIT ?""",
                (week_start, limit),
            ).fetchall()
        else:
            rows = conn.execute(
                """SELECT * FROM claim_events
                   ORDER BY event_at DESC
                   LIMIT ?""",
                (limit,),
            ).fetchall()
        return [dict(row) for row in rows]
    finally:
        conn.close()


def cleanup_old_claim_events(keep_weeks: int = 8, db_path: str | None = None) -> None:
    """清理超过 keep_weeks 周的旧事件日志。

    Args:
        keep_weeks: 保留最近几周的数据，默认 8 周。
    """
    cutoff = get_week_start_ts() - (keep_weeks * 7 * 86400)
    conn = get_connection(db_path)
    try:
        conn.execute(
            "DELETE FROM claim_events WHERE week_start < ?",
            (cutoff,),
        )
        conn.commit()
    finally:
        conn.close()
