/// Endfield 设计语言 tokens（ark-ui skill：family=endfield, depth=2/moderate）。
///
/// 白/炭黑/信号黄的技术外勤系统：直角矩形、1px 引导线、yellow wedge、
/// 双语微标（中文主标签 + 大写英文 micro-label）、field codes。
library;

import 'package:flutter/material.dart';

class Ef {
  Ef._();

  // ── 颜色 ────────────────────────────────────────────────────
  static const ink = Color(0xFF191919); // 炭黑：主文本 / 深色 dock
  static const paper = Color(0xFFF2F2F0); // 米白：底色
  static const signal = Color(0xFFFFFA00); // 信号黄：激活态 / 进度 / 主操作
  static const stateOk = Color(0xFF00FFA2); // 绿：仅 verified / online
  static const muted = Color(0xFF888888);
  static const panel = Color(0xD8191919); // rgba(25,25,25,.84) 深色面板
  static const error = Color(0xFFE5483F);
  static const paperEdge = Color(0xFFDCDCD6); // paper 上的 1px 分隔线

  static const double radius = 2.0;

  // ── 字体 ────────────────────────────────────────────────────
  static const latinFamily = 'SpaceGrotesk';
  static const cjkFallback = <String>[
    'Microsoft YaHei',
    'PingFang SC',
    'Noto Sans SC',
  ];

  /// 英文 micro-label：大写、宽字距。
  static TextStyle micro({Color? color, double size = 10}) => TextStyle(
        fontFamily: latinFamily,
        fontSize: size,
        letterSpacing: 1.8,
        fontWeight: FontWeight.w500,
        color: color ?? muted,
      );

  /// 中文正文。
  static TextStyle body({
    Color? color,
    double size = 13,
    FontWeight weight = FontWeight.w400,
  }) =>
      TextStyle(
        fontFamilyFallback: cjkFallback,
        fontSize: size,
        fontWeight: weight,
        color: color ?? ink,
        height: 1.4,
      );

  /// 数字/计时（等宽数字）。
  static TextStyle num({
    Color? color,
    double size = 13,
    FontWeight weight = FontWeight.w500,
  }) =>
      TextStyle(
        fontFamily: latinFamily,
        fontFamilyFallback: cjkFallback,
        fontSize: size,
        fontWeight: weight,
        color: color ?? ink,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// 区段标题（超大编号）。
  static TextStyle sectionIndex({Color? color}) => TextStyle(
        fontFamily: latinFamily,
        fontSize: 64,
        height: 1,
        letterSpacing: -2,
        fontWeight: FontWeight.w700,
        color: color ?? ink.withValues(alpha: 0.10),
      );
}
