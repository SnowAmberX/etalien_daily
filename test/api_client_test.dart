import 'package:etalien_daily/core/api_client.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normalizePhone', () {
    test('11 位国内号码自动加 +86 前缀', () {
      expect(normalizePhone('13800138000'), '+8613800138000');
    });

    test('已带 +86 前缀保持不变', () {
      expect(normalizePhone('+8613800138000'), '+8613800138000');
    });

    test('非 11 位号码原样返回', () {
      expect(normalizePhone('123'), '123');
      expect(normalizePhone('138001380001'), '138001380001');
    });

    test('首尾空白会被去除', () {
      expect(normalizePhone(' 13800138000 '), '+8613800138000');
    });

    test('含非数字字符不自动加前缀', () {
      expect(normalizePhone('1380013800a'), '1380013800a');
    });
  });

  group('parseTranslateCount', () {
    // 2026-08-04 实测响应：产品目录（field 1）+ 顶层 field 2 varint = 346
    const hex =
        '0a 1a 08 01 12 0b e7 bf bb e8 af 91 31 30 e6 ac a1 18 0a 21 00 00 00 00 00 00 e0 3f '
        '0a 1a 08 02 12 0b e7 bf bb e8 af 91 35 30 e6 ac a1 18 32 21 00 00 00 00 00 00 00 40 '
        '0a 1b 08 03 12 0c e7 bf bb e8 af 91 31 30 30 e6 ac a1 18 64 21 00 00 00 00 00 00 10 40 '
        '0a 1c 08 04 12 0c e7 bf bb e8 af 91 35 30 30 e6 ac a1 18 f4 03 21 00 00 00 00 00 00 32 40 '
        '0a 1d 08 05 12 0d e7 bf bb e8 af 91 31 30 30 30 e6 ac a1 18 e8 07 21 00 00 00 00 00 80 41 40 '
        '10 da 02';
    final bytes =
        hex.split(' ').map((s) => int.parse(s, radix: 16)).toList();

    test('解析实测响应，返回顶层 field 2 的翻译次数', () {
      expect(bytes.length, 149);
      expect(parseTranslateCount(bytes), 346);
    });

    test('空响应返回 null', () {
      expect(parseTranslateCount(const <int>[]), isNull);
    });

    test('截断数据返回 null', () {
      expect(parseTranslateCount(const [0x80]), isNull);
      expect(parseTranslateCount(const [0x0a, 0x1a, 0x08]), isNull);
    });

    test('无 field 2 返回 null', () {
      expect(parseTranslateCount(const [0x0a, 0x00]), isNull);
    });
  });
}
