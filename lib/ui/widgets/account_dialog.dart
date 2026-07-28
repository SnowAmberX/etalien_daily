import 'package:flutter/material.dart';

import '../store/stores.dart';
import 'ef_button.dart';
import 'ef_dialog.dart';
import 'ef_toast.dart';

/// 添加/编辑账号弹窗。
Future<void> showAccountDialog(BuildContext context, {String? phone}) {
  return showEfDialog<void>(
    context,
    title: phone == null ? '添加账号' : '编辑账号',
    en: phone == null ? 'ADD ACCOUNT' : 'EDIT ACCOUNT',
    width: 360,
    child: _AccountForm(phone: phone),
  );
}

class _AccountForm extends StatefulWidget {
  const _AccountForm({this.phone});

  final String? phone;

  @override
  State<_AccountForm> createState() => _AccountFormState();
}

class _AccountFormState extends State<_AccountForm> {
  late final TextEditingController _phone;
  late final TextEditingController _name;
  late final TextEditingController _remark;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _phone = TextEditingController(text: widget.phone ?? '');
    _name = TextEditingController();
    _remark = TextEditingController();
    if (widget.phone != null) {
      final existing = accountsStore.accounts
          .where((a) => a.phone == widget.phone)
          .firstOrNull;
      if (existing != null) {
        _name.text = existing.account.name;
        _remark.text = existing.account.remark;
      }
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _name.dispose();
    _remark.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        EfTextField(
          label: '手机号 PHONE',
          controller: _phone,
          hint: '13800138000',
          keyboardType: TextInputType.phone,
          maxLength: 11,
        ),
        EfTextField(label: '备注名 NAME', controller: _name, hint: '可选'),
        EfTextField(label: '备注 REMARK', controller: _remark, hint: '可选'),
        EfDialogActions(
          children: [
            EfButton(
              label: _busy ? '保存中…' : '保存',
              primary: true,
              onPressed: _busy ? null : _save,
            ),
            EfButton(
              label: '取消',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _save() async {
    final phone = _phone.text.trim();
    if (phone.isEmpty) {
      EfToast.show(context, '手机号不能为空', type: EfToastType.warn);
      return;
    }
    setState(() => _busy = true);
    try {
      if (widget.phone == null) {
        await accountsStore.add(
            phone, _name.text.trim(), _remark.text.trim());
      } else {
        await accountsStore.edit(
            widget.phone!, phone, _name.text.trim(), _remark.text.trim());
      }
      if (!mounted) return;
      Navigator.of(context).pop();
      EfToast.show(context, '已保存', type: EfToastType.ok);
    } on StateError catch (e) {
      EfToast.show(context, e.message, type: EfToastType.warn);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
