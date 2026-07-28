/// 签名算法单元测试（对照 v1 tests/test_sign.py）。
library;

import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:etalien_daily/core/sign.dart';
import 'package:flutter_test/flutter_test.dart';

const fixedTs = 1719500000;
const fixedNonce = 'abc123def45678901234567890123456';

void main() {
  group('getSortParameters', () {
    test('empty params', () {
      final (result, _) = getSortParameters(null, ts: fixedTs, nonce: fixedNonce);
      expect(result, contains('ts=1719500000'));
      expect(result, contains('nonce=$fixedNonce'));
      expect(result, contains('ver=2023-08-28'));
      // 验证字母序：nonce < ts < ver
      expect(
        result.indexOf('nonce') < result.indexOf('ts') &&
            result.indexOf('ts') < result.indexOf('ver'),
        isTrue,
      );
    });

    test('with existing params', () {
      final (result, params) = getSortParameters(
        {'key1': 'val1', 'abc': 'xyz'},
        ts: fixedTs,
        nonce: fixedNonce,
      );
      expect(result.startsWith('abc=xyz'), isTrue);
      expect(result, contains('key1=val1'));
      expect(params['key1'], 'val1');
      expect(params['abc'], 'xyz');
    });

    test('none value', () {
      final (result, _) = getSortParameters(
        {'empty': null},
        ts: fixedTs,
        nonce: fixedNonce,
      );
      expect(result, contains('empty='));
      expect(result, isNot(contains('empty=None')));
    });

    test('url encoding', () {
      final (result, _) = getSortParameters(
        {'name': 'hello world'},
        ts: fixedTs,
        nonce: fixedNonce,
      );
      expect(result, contains('hello%20world'));
    });
  });

  group('getSign', () {
    test('known signature', () {
      const data =
          'GETapi.et-api.com/v2/account/pc/ad/config?nonce=abc&ts=123&ver=2023-08-28';
      final sig = getSign(data);
      expect(sig.length, 64);
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(sig), isTrue);
    });

    test('url decoded input', () {
      // getSign 会对输入先做 URL 解码再计算 SHA-256；
      // 与 Python unquote 一致：'+' 不解码。
      const encoded = 'hello+world%21';
      final sig = getSign(encoded);
      final expected = sha256.convert(utf8.encode('hello+world!')).toString();
      expect(sig, expected);
    });

    test('deterministic', () {
      const data = 'POSTapi.et-api.com/path?key=val';
      expect(getSign(data), getSign(data));
    });
  });

  group('signUrl', () {
    test('get request', () {
      final (url, params) = signUrl('GET', '/test/path',
          ts: fixedTs, nonce: fixedNonce);
      expect(url.startsWith('https://api.et-api.com/test/path?'), isTrue);
      expect(url, contains('sig='));
      expect(params.containsKey('sig'), isTrue);
      expect(params['sig']!.length, 64);
    });

    test('post request', () {
      final (url, _) = signUrl('POST', '/v2/account/pc/ad/config',
          ts: fixedTs, nonce: fixedNonce);
      expect(url, contains('https://'));
      expect(url.split('?')[1], contains('sig='));
    });

    test('custom port', () {
      final (url, _) = signUrl('GET', '/path',
          host: 'api.et-api.com', port: 8080, ts: fixedTs, nonce: fixedNonce);
      // 端口不出现在 URL 中，但签名原文包含 host:port
      expect(url, contains('https://api.et-api.com/path?'));
    });

    test('standard port omitted', () {
      final (url, _) =
          signUrl('GET', '/path', port: 443, ts: fixedTs, nonce: fixedNonce);
      expect(url, contains('https://api.et-api.com/path?'));
    });

    test('params dict contains all fields', () {
      final (_, params) =
          signUrl('GET', '/path', ts: fixedTs, nonce: fixedNonce);
      for (final key in ['ts', 'nonce', 'ver', 'sig']) {
        expect(params.containsKey(key), isTrue);
      }
      expect(params['ts'], '1719500000');
      expect(params['nonce'], fixedNonce);
      expect(params['ver'], '2023-08-28');
    });
  });

  group('quote/unquote (Python 语义)', () {
    test('quote 空格为 %20', () {
      expect(quote('hello world'), 'hello%20world');
    });

    test('quote 保留 unreserved 字符', () {
      expect(quote('AZaz09_.-~'), 'AZaz09_.-~');
    });

    test('quote 大写十六进制', () {
      expect(quote('!'), '%21');
      expect(quote('+'), '%2B');
    });

    test('quote 中文按 UTF-8 编码', () {
      expect(quote('中'), '%E4%B8%AD');
    });

    test('unquote 不解码 +', () {
      expect(unquote('hello+world%21'), 'hello+world!');
    });

    test('unquote 还原中文', () {
      expect(unquote('%E4%B8%AD'), '中');
    });
  });
}
