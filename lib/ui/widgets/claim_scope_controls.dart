import 'package:flutter/material.dart';

import '../endfield.dart';

/// 账号领取范围：PC / 手机 / 翻译。
typedef ClaimScope = ({bool pc, bool mobile, bool translate});

/// Endfield 方形 checkbox 组，用于账号卡片背面和批量配置弹窗。
class ClaimScopeControls extends StatelessWidget {
  const ClaimScopeControls({
    super.key,
    required this.scope,
    required this.onChanged,
  });

  final ClaimScope scope;
  final ValueChanged<ClaimScope> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _row(
          en: 'PC',
          zh: 'PC 领取',
          value: scope.pc,
          onTap: () => onChanged((
            pc: !scope.pc,
            mobile: scope.mobile,
            translate: scope.translate,
          )),
        ),
        _row(
          en: 'MOBILE',
          zh: '手机领取',
          value: scope.mobile,
          onTap: () => onChanged((
            pc: scope.pc,
            mobile: !scope.mobile,
            translate: scope.translate,
          )),
        ),
        _row(
          en: 'TRANS',
          zh: '翻译领取',
          value: scope.translate,
          onTap: () => onChanged((
            pc: scope.pc,
            mobile: scope.mobile,
            translate: !scope.translate,
          )),
        ),
      ],
    );
  }

  Widget _row({
    required String en,
    required String zh,
    required bool value,
    required VoidCallback onTap,
  }) {
    return Semantics(
      button: true,
      toggled: value,
      label: zh,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          height: 40,
          child: Row(
            children: [
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: value ? Ef.signal : Colors.white,
                  border: Border.all(
                    color: value ? Ef.ink : Ef.paperEdge,
                  ),
                ),
                child: value
                    ? const Icon(Icons.check, size: 13, color: Ef.ink)
                    : null,
              ),
              const SizedBox(width: 8),
              Text(
                en,
                style: Ef.micro(
                  size: 9,
                  color: value ? Ef.ink : Ef.muted,
                ),
              ),
              const SizedBox(width: 8),
              Text(zh, style: Ef.body(size: 12, color: Ef.ink)),
            ],
          ),
        ),
      ),
    );
  }
}
