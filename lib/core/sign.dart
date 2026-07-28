/// 请求签名算法模块。
///
/// ET App 内置 SignInterceptor 对所有 HTTP 请求进行签名校验。
/// 本模块实现参数排序、SHA-256 签名计算和签名 URL 构建。
/// 与 v1 (Python) 的 sign.py 语义完全一致。
library;

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

const String kSignHost = 'api.et-api.com';
const String kSignVer = '2023-08-28';

/// Python urllib.parse.quote(s, safe='') 的等价实现。
///
/// 仅保留 RFC 3986 unreserved 字符（A-Z a-z 0-9 _ . - ~），
/// 其余 UTF-8 字节一律 %XX（大写十六进制），空格编码为 %20。
String quote(String value) {
  final bytes = utf8.encode(value);
  final sb = StringBuffer();
  for (final b in bytes) {
    final isUnreserved =
        (b >= 0x41 && b <= 0x5A) || // A-Z
        (b >= 0x61 && b <= 0x7A) || // a-z
        (b >= 0x30 && b <= 0x39) || // 0-9
        b == 0x5F || // _
        b == 0x2E || // .
        b == 0x2D || // -
        b == 0x7E; // ~
    if (isUnreserved) {
      sb.writeCharCode(b);
    } else {
      sb.write('%');
      sb.write(b.toRadixString(16).toUpperCase().padLeft(2, '0'));
    }
  }
  return sb.toString();
}

/// Python urllib.parse.unquote 的等价实现。
///
/// 解码 %XX 序列并按 UTF-8 还原；`+` 保持不变（不解码为空格）。
String unquote(String value) {
  final bytes = <int>[];
  var i = 0;
  while (i < value.length) {
    final ch = value[i];
    if (ch == '%' && i + 2 < value.length) {
      final hex = value.substring(i + 1, i + 3);
      final code = int.tryParse(hex, radix: 16);
      if (code != null) {
        bytes.add(code);
        i += 3;
        continue;
      }
    }
    bytes.addAll(utf8.encode(ch));
    i++;
  }
  return utf8.decode(bytes);
}

/// 生成 32 位十六进制随机串（等价 uuid4().hex，服务端仅作随机数使用）。
String _randomNonce() {
  final rnd = Random.secure();
  final bytes = List<int>.generate(16, (_) => rnd.nextInt(256));
  return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}

/// 对请求参数排序并追加签名必需的 ts/nonce/ver 参数。
///
/// 返回 (排序后的查询字符串, 包含所有参数的字典)。
/// [ts]/[nonce] 可注入固定值用于测试。
(String, Map<String, String?>) getSortParameters(
  Map<String, String?>? queryParams, {
  int? ts,
  String? nonce,
}) {
  final params = <String, String?>{
    ...?queryParams,
    'ts': (ts ?? DateTime.now().millisecondsSinceEpoch ~/ 1000).toString(),
    'nonce': nonce ?? _randomNonce(),
    'ver': kSignVer,
  };

  final sortedKeys = params.keys.toList()..sort();
  final parts = <String>[];
  for (final key in sortedKeys) {
    final val = params[key];
    if (val != null) {
      parts.add('$key=${quote(val)}');
    } else {
      parts.add('$key=');
    }
  }

  return (parts.join('&'), params);
}

/// 计算 SHA-256 签名。
///
/// [data] 为签名原文（URL 编码格式），内部先 unquote 再计算。
/// 返回十六进制签名字符串。
String getSign(String data) {
  final decoded = unquote(data);
  return sha256.convert(utf8.encode(decoded)).toString();
}

/// 构建带签名的完整请求 URL。
///
/// 返回 (完整签名 URL, 参数字典)，参数字典包含 ts/nonce/ver/sig 用于日志。
(String, Map<String, String?>) signUrl(
  String method,
  String path, {
  Map<String, String?>? queryParams,
  String host = kSignHost,
  int? port,
  int? ts,
  String? nonce,
}) {
  final (sortedQuery, params) = getSortParameters(
    queryParams,
    ts: ts,
    nonce: nonce,
  );

  // 构建签名原文
  final String base;
  if (port != null && port != 80 && port != 443) {
    base = '$host:$port$path?$sortedQuery';
  } else {
    base = '$host$path?$sortedQuery';
  }

  final signStr = getSign('${method.toUpperCase()}$base');

  final url = 'https://$host$path?$sortedQuery&sig=$signStr';
  params['sig'] = signStr;

  return (url, params);
}
