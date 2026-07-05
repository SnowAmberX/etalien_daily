"""翻译次数领取功能测试。

覆盖：
- expire_time 安全解析（字符串/int/缺失/非法值）
- Member protobuf 往返（translate/product/list 响应）
- pc_ad_callback_backup 使用正确的 ad_id 和 business
- _claim_translate_phase 领取逻辑（模拟）
"""

import unittest
from unittest.mock import MagicMock

from etalien.proto_compiled.account_pb2 import Member
from etalien.proto_compiled.apiv2_pb2 import (
    PcAdCallbackBackupRequest,
    PcAdCallbackBackupResponse,
    AdActivityItem,
)
from etalien.service import _safe_parse_translate_count
from google.protobuf.json_format import MessageToDict


class TestSafeParseTranslateCount(unittest.TestCase):
    """_safe_parse_translate_count 测试。"""

    def test_expire_time_string(self):
        """expire_time 为字符串 "7" → 返回 7。"""
        product = {"expire_time": "7"}
        self.assertEqual(_safe_parse_translate_count(product), 7)

    def test_expire_time_int(self):
        """expire_time 为 int 7 → 返回 7。"""
        product = {"expire_time": 7}
        self.assertEqual(_safe_parse_translate_count(product), 7)

    def test_expire_time_missing(self):
        """expire_time 缺失 → 返回 0，不崩溃。"""
        product = {}
        self.assertEqual(_safe_parse_translate_count(product), 0)

    def test_expire_time_empty_string(self):
        """expire_time 为空字符串 → 返回 0，不崩溃。"""
        product = {"expire_time": ""}
        self.assertEqual(_safe_parse_translate_count(product), 0)

    def test_expire_time_invalid_string(self):
        """expire_time 为非法字符串 "abc" → 返回 0，不崩溃。"""
        product = {"expire_time": "not_a_number"}
        self.assertEqual(_safe_parse_translate_count(product), 0)

    def test_expire_time_zero(self):
        """expire_time 为 0 → 返回 0。"""
        product = {"expire_time": 0}
        self.assertEqual(_safe_parse_translate_count(product), 0)

    def test_expire_time_negative(self):
        """expire_time 为负数 → 返回 0（max(0, count)）。"""
        product = {"expire_time": -5}
        self.assertEqual(_safe_parse_translate_count(product), 0)

    def test_expire_time_zero_string(self):
        """expire_time 为字符串 "0" → 返回 0。"""
        product = {"expire_time": "0"}
        self.assertEqual(_safe_parse_translate_count(product), 0)

    def test_product_none(self):
        """product 为 None → 返回 0。"""
        self.assertEqual(_safe_parse_translate_count(None), 0)

    def test_product_not_dict(self):
        """product 为非 dict 类型 → 返回 0。"""
        self.assertEqual(_safe_parse_translate_count([]), 0)
        self.assertEqual(_safe_parse_translate_count("invalid"), 0)

    def test_product_ok_with_no_expire_time(self):
        """product 有 _ok 但无 expire_time → 返回 0。"""
        product = {"_ok": True}
        self.assertEqual(_safe_parse_translate_count(product), 0)


class TestMemberTranslate(unittest.TestCase):
    """Member（translate/product/list 响应）protobuf 往返测试。"""

    def test_roundtrip_expire_time_int(self):
        """Member(type=0, expire_time=16) → 往返正确。"""
        msg = Member(type=0, expire_time=16)
        data = msg.SerializeToString()
        parsed = Member()
        parsed.ParseFromString(data)
        self.assertEqual(parsed.type, 0)
        self.assertEqual(parsed.expire_time, 16)

    def test_roundtrip_expire_time_zero(self):
        """expire_time 为 0 → 往返正确。"""
        msg = Member(type=0, expire_time=0)
        parsed = Member()
        parsed.ParseFromString(msg.SerializeToString())
        self.assertEqual(parsed.expire_time, 0)

    def test_message_to_dict_string_conversion(self):
        """验证 MessageToDict 将 int64 转为字符串：expire_time=16 → "16"。"""
        msg = Member(type=0, expire_time=16)
        result = MessageToDict(msg, preserving_proto_field_name=True)
        # MessageToDict 将 int64 转为字符串
        self.assertEqual(result["expire_time"], "16")
        self.assertEqual(result["type"], "0")

    def test_message_to_dict_zero(self):
        """验证 MessageToDict 将 0 转为字符串 "0"。"""
        msg = Member(type=0, expire_time=0)
        result = MessageToDict(msg, preserving_proto_field_name=True)
        self.assertEqual(result["expire_time"], "0")


class TestTranslateCallbackRequest(unittest.TestCase):
    """验证翻译 callback 使用正确的 ad_id 和 business。"""

    def test_callback_uses_translate_ad_id_and_business(self):
        """pc_ad_callback_backup 使用 ad_id="103579416", business=3。"""
        req = PcAdCallbackBackupRequest(ad_id="103579416", business=3)
        parsed = PcAdCallbackBackupRequest()
        parsed.ParseFromString(req.SerializeToString())
        self.assertEqual(parsed.ad_id, "103579416")
        self.assertEqual(parsed.business, 3)

    def test_callback_response_roundtrip(self):
        """PcAdCallbackBackupResponse is_verify 往返。"""
        resp = PcAdCallbackBackupResponse(is_verify=True)
        parsed = PcAdCallbackBackupResponse()
        parsed.ParseFromString(resp.SerializeToString())
        self.assertTrue(parsed.is_verify)

        resp2 = PcAdCallbackBackupResponse(is_verify=False)
        parsed2 = PcAdCallbackBackupResponse()
        parsed2.ParseFromString(resp2.SerializeToString())
        self.assertFalse(parsed2.is_verify)


class TestAdActivityItem(unittest.TestCase):
    """AdActivityItem（翻译广告任务）protobuf 测试。"""

    def test_has_award_true(self):
        """has_award = True → 往返正确。"""
        item = AdActivityItem(has_award=True, award=1)
        parsed = AdActivityItem()
        parsed.ParseFromString(item.SerializeToString())
        self.assertTrue(parsed.has_award)
        self.assertEqual(parsed.award, 1)

    def test_has_award_false(self):
        """has_award = False → 往返正确。"""
        item = AdActivityItem(has_award=False, award=0)
        parsed = AdActivityItem()
        parsed.ParseFromString(item.SerializeToString())
        self.assertFalse(parsed.has_award)

    def test_is_get_field(self):
        """is_get 字段往返正确。"""
        item = AdActivityItem(has_award=True, award=1, is_get=True)
        parsed = AdActivityItem()
        parsed.ParseFromString(item.SerializeToString())
        self.assertTrue(parsed.is_get)


class TestClaimTranslatePhase(unittest.TestCase):
    """_claim_translate_phase 模拟测试（配置驱动循环）。"""

    def _make_mock_client(self, config_responses, callback_response, product_response=None):
        """创建模拟的 ApiClient。

        Args:
            config_responses: fetch_translate_ad_config 的返回 dict 列表（循环使用）
            callback_response: pc_ad_callback_backup 的单次返回
            product_response: fetch_translate_product 的单次返回（可选，用于最终校验）
        """
        client = MagicMock()
        client.get_auth_token.return_value = "fake-token"
        client.fetch_translate_ad_config.side_effect = config_responses
        client.pc_ad_callback_backup.return_value = callback_response
        if product_response is not None:
            client.fetch_translate_product.return_value = product_response
        else:
            client.fetch_translate_product.return_value = {"_ok": True, "expire_time": "0"}
        return client

    def _make_config(self, watched_items=0, total_items=15):
        """构建模拟 PcAdConfigResponse：4 个阶段，合计 total_items 个广告。

        每个 item 有 is_watch 字段，前 watched_items 个为 True。
        """
        # 简化：所有 item 放在一个 level 里
        items = []
        for i in range(total_items):
            items.append({"id": str(i + 1), "is_watch": i < watched_items})
        return {"_ok": True, "list": [{"level": 1, "list": items, "watch_cnt": watched_items}]}

    def _make_settings(self, **overrides):
        """创建默认设置 dict。"""
        s = {
            "request_interval": 0.01,
            "translate_max_rounds": 20,
            "translate_retry_limit": 3,
        }
        s.update(overrides)
        return s

    def test_all_watched_exits_early(self):
        """所有广告已观看 → 立即退出，claimed=0。"""
        from etalien.service import _claim_translate_phase

        config = self._make_config(watched_items=15, total_items=15)
        client = self._make_mock_client(
            config_responses=[config],
            callback_response={"_ok": True, "is_verify": True},
        )
        settings = self._make_settings()

        claimed, failed = _claim_translate_phase(client, settings, "13800138000")

        self.assertEqual(claimed, 0)
        self.assertEqual(failed, 0)
        client.pc_ad_callback_backup.assert_not_called()

    def test_single_round_progress(self):
        """1 轮：watched 0→1, is_verify=True → claimed=1。"""
        from etalien.service import _claim_translate_phase

        config_before = self._make_config(watched_items=0, total_items=15)
        config_after = self._make_config(watched_items=1, total_items=15)
        # 第二轮：全部完成，退出
        config_done = self._make_config(watched_items=15, total_items=15)

        client = self._make_mock_client(
            config_responses=[config_before, config_after, config_done],
            callback_response={"_ok": True, "is_verify": True},
        )
        settings = self._make_settings()

        claimed, failed = _claim_translate_phase(client, settings, "13800138000")

        self.assertEqual(claimed, 1)
        self.assertEqual(failed, 0)
        client.pc_ad_callback_backup.assert_called_with("103579416", 3)

    def test_multi_round_cumulative(self):
        """3 轮逐步推进：0→3→7→15，claimed 累加。"""
        from etalien.service import _claim_translate_phase

        client = self._make_mock_client(
            config_responses=[
                self._make_config(watched_items=0, total_items=15),   # before round 1
                self._make_config(watched_items=3, total_items=15),   # after round 1 (+3)
                self._make_config(watched_items=3, total_items=15),   # before round 2
                self._make_config(watched_items=7, total_items=15),   # after round 2 (+4)
                self._make_config(watched_items=7, total_items=15),   # before round 3
                self._make_config(watched_items=15, total_items=15),  # after round 3 (+8)
                self._make_config(watched_items=15, total_items=15),  # done check → exit
            ],
            callback_response={"_ok": True, "is_verify": True},
        )
        settings = self._make_settings()

        claimed, failed = _claim_translate_phase(client, settings, "13800138000")

        self.assertEqual(claimed, 15)  # 3 + 4 + 8
        self.assertEqual(failed, 0)

    def test_stalled_exits_after_limit(self):
        """连续无进展达到 translate_retry_limit=3 → 退出。"""
        from etalien.service import _claim_translate_phase

        # 始终返回 watched=3/15，无进展
        config = self._make_config(watched_items=3, total_items=15)
        client = self._make_mock_client(
            config_responses=[config] * 20,  # 足够多
            callback_response={"_ok": True, "is_verify": True},
        )
        settings = self._make_settings(translate_retry_limit=3)

        claimed, failed = _claim_translate_phase(client, settings, "13800138000")

        self.assertEqual(claimed, 0)
        # 应只执行了 translate_retry_limit 轮后退出

    def test_is_verify_false_not_counted(self):
        """is_verify=False → failed 增加，watched 无进展。"""
        from etalien.service import _claim_translate_phase

        config = self._make_config(watched_items=3, total_items=15)
        client = self._make_mock_client(
            config_responses=[config] * 20,
            callback_response={"_ok": True, "is_verify": False},
        )
        settings = self._make_settings(translate_retry_limit=3)

        claimed, failed = _claim_translate_phase(client, settings, "13800138000")

        self.assertEqual(claimed, 0)
        self.assertGreaterEqual(failed, 1)

    def test_auth_error_clears_token(self):
        """认证错误 → 清除 token 并退出。"""
        from etalien.service import _claim_translate_phase

        client = self._make_mock_client(
            config_responses=[
                {"_error": True, "code": 16, "msg": "token expired"},
            ],
            callback_response={"_ok": True, "is_verify": True},
        )
        settings = self._make_settings()

        claimed, failed = _claim_translate_phase(client, settings, "13800138000")

        self.assertEqual(claimed, 0)
        client.clear_auth_token.assert_called()

    def test_no_token_exits(self):
        """无 auth_token → 立即退出。"""
        from etalien.service import _claim_translate_phase

        client = MagicMock()
        client.get_auth_token.return_value = None
        settings = self._make_settings()

        claimed, failed = _claim_translate_phase(client, settings, "13800138000")

        self.assertEqual(claimed, 0)
        self.assertEqual(failed, 0)

    def test_max_rounds_limit(self):
        """达到 translate_max_rounds 上限 → 退出，不无限循环。"""
        from etalien.service import _claim_translate_phase

        # 始终返回 3/15，永不完成
        config = self._make_config(watched_items=3, total_items=15)
        client = self._make_mock_client(
            config_responses=[config] * 10,  # 仅够 5 轮（每轮 2 个 config）
            callback_response={"_ok": True, "is_verify": True},
        )
        settings = self._make_settings(translate_max_rounds=2, translate_retry_limit=10)

        claimed, failed = _claim_translate_phase(client, settings, "13800138000")

        # 最多 2 轮后退出
        self.assertEqual(claimed, 0)


if __name__ == "__main__":
    unittest.main()
