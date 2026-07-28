"""测试 fetch_my_profile 中 remaining_seconds 计算逻辑。

覆盖 MessageToDict 将 protobuf int64 转为字符串的场景。
"""

import time
import unittest

# 与 src/etalien/client.py fetch_my_profile() 中相同的计算逻辑
def _compute_remaining(member, now_ts):
    """从 member dict 计算 remaining_seconds。

    模拟 fetch_my_profile() 中的逻辑：
    - member 为 None / 空 / 非 dict → 返回 0
    - expire_time 可能是字符串（MessageToDict 行为）或整数
    - 回退尝试 expireTime（camelCase）
    - 非法值不崩溃，返回 0
    """
    if not member or not isinstance(member, dict):
        return 0
    # expire_time 优先，expireTime 作为回退
    raw = member.get("expire_time") or member.get("expireTime") or 0
    try:
        expire = int(raw)
    except (TypeError, ValueError):
        expire = 0
    return max(0, expire - now_ts)


class TestRemainingSeconds(unittest.TestCase):
    """remaining_seconds 计算测试。"""

    NOW = 1780000000  # 固定时间戳

    def test_string_expire_time(self):
        """expire_time 为字符串（MessageToDict 默认行为）→ 正确计算。"""
        member = {"type": 1, "expire_time": "1780003600"}
        remain = _compute_remaining(member, self.NOW)
        self.assertEqual(remain, 3600)  # 一小时

    def test_int_expire_time(self):
        """expire_time 为整数 → 正确计算。"""
        member = {"type": 1, "expire_time": 1780007200}
        remain = _compute_remaining(member, self.NOW)
        self.assertEqual(remain, 7200)

    def test_camelcase_fallback(self):
        """expire_time 缺失但有 expireTime → 使用 expireTime。"""
        member = {"type": 1, "expireTime": "1780003600"}
        remain = _compute_remaining(member, self.NOW)
        self.assertEqual(remain, 3600)

    def test_expired_returns_zero(self):
        """expire_time 已过期 → 返回 0。"""
        member = {"type": 1, "expire_time": 1770000000}  # 远在过去
        remain = _compute_remaining(member, self.NOW)
        self.assertEqual(remain, 0)

    def test_member_none(self):
        """member 为 None → 返回 0。"""
        self.assertEqual(_compute_remaining(None, self.NOW), 0)

    def test_member_empty_dict(self):
        """member 为空 dict → 返回 0。"""
        self.assertEqual(_compute_remaining({}, self.NOW), 0)

    def test_member_missing_expire(self):
        """member 中没有 expire_time 也没有 expireTime → 返回 0。"""
        member = {"type": 1}
        remain = _compute_remaining(member, self.NOW)
        self.assertEqual(remain, 0)

    def test_expire_time_zero(self):
        """expire_time 为 0 → 返回 0。"""
        member = {"type": 1, "expire_time": 0}
        remain = _compute_remaining(member, self.NOW)
        self.assertEqual(remain, 0)

    def test_expire_time_empty_string(self):
        """expire_time 为空字符串 → 不崩溃，返回 0。"""
        member = {"type": 1, "expire_time": ""}
        remain = _compute_remaining(member, self.NOW)
        self.assertEqual(remain, 0)

    def test_expire_time_invalid_string(self):
        """expire_time 为非法字符串 → 不崩溃，返回 0。"""
        member = {"type": 1, "expire_time": "not_a_number"}
        remain = _compute_remaining(member, self.NOW)
        self.assertEqual(remain, 0)

    def test_expire_time_negative(self):
        """expire_time 为负数 → 返回 0（已过期）。"""
        member = {"type": 1, "expire_time": -1}
        remain = _compute_remaining(member, self.NOW)
        self.assertEqual(remain, 0)

    def test_member_is_list(self):
        """member 为 list（异常数据）→ 返回 0，不崩溃。"""
        self.assertEqual(_compute_remaining([], self.NOW), 0)


if __name__ == "__main__":
    unittest.main()
