import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/database.dart';
import '../endfield.dart';
import '../store/stores.dart';
import 'ef_button.dart';
import 'ef_dialog.dart';
import 'ef_toast.dart';

/// 登录弹窗：短信验证码 / 密码 双 Tab。
Future<void> showLoginDialog(BuildContext context, String phone) {
  return showEfDialog<void>(
    context,
    title: '登录 $phone',
    en: 'AUTH',
    width: 380,
    child: _LoginForm(phone: phone),
  );
}

class _LoginForm extends StatefulWidget {
  const _LoginForm({required this.phone});

  final String phone;

  @override
  State<_LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends State<_LoginForm> {
  var _tab = 0; // 0=短信 1=密码
  var _codeSent = false;
  var _busy = false;
  String _msg = '';

  final _code = TextEditingController();
  final _password = TextEditingController();

  ApiClient? _client;

  @override
  void initState() {
    super.initState();
    _initClient();
  }

  Future<void> _initClient() async {
    final acc = await getAccount(widget.phone);
    if (acc != null && mounted) {
      setState(() => _client = ApiClient(deviceId: acc.deviceId));
    }
  }

  @override
  void dispose() {
    _code.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab 切换
        Row(
          children: [
            _tabChip(0, '短信登录'),
            const SizedBox(width: 6),
            _tabChip(1, '密码登录'),
          ],
        ),
        const SizedBox(height: 14),
        if (_tab == 0) ...[
          if (!_codeSent)
            Text('点击发送验证码到 ${widget.phone}',
                style: Ef.body(size: 12, color: Ef.muted))
          else
            EfTextField(
              label: '验证码 CODE',
              controller: _code,
              hint: '6 位短信验证码',
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
        ] else ...[
          EfTextField(
            label: '密码 PASSWORD',
            controller: _password,
            hint: '输入密码',
            obscure: true,
          ),
        ],
        if (_msg.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(_msg, style: Ef.body(size: 11, color: Ef.muted)),
          ),
        EfDialogActions(
          children: [
            if (_tab == 0 && !_codeSent)
              EfButton(
                label: _busy ? '发送中…' : '发送验证码',
                primary: true,
                onPressed: _busy ? null : _sendCode,
              )
            else
              EfButton(
                label: _busy ? '登录中…' : '登录',
                primary: true,
                onPressed: _busy
                    ? null
                    : (_tab == 0 ? _verifyCode : _passwordLogin),
              ),
            if (_tab == 0 && _codeSent)
              EfButton(
                label: '重发',
                onPressed: _busy ? null : _sendCode,
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

  Widget _tabChip(int index, String label) {
    final active = _tab == index;
    return GestureDetector(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: active ? Ef.ink : Colors.transparent,
          border: Border.all(color: Ef.ink.withValues(alpha: 0.75)),
        ),
        child: Text(
          label,
          style: Ef.body(
            size: 12,
            weight: FontWeight.w600,
            color: active ? Colors.white : Ef.ink,
          ),
        ),
      ),
    );
  }

  Future<void> _sendCode() async {
    final client = _client;
    if (client == null) return;
    setState(() {
      _busy = true;
      _msg = '';
    });
    try {
      final r = await client.getVerificationCode(widget.phone);
      if (!mounted) return;
      // v1 语义：冷却期 code 60/1000 视为已发送
      if (!r.isError || r.code == 60 || r.code == 1000) {
        setState(() {
          _codeSent = true;
          _msg = '验证码已发送';
        });
      } else {
        setState(() => _msg = '发送失败: ${r.msg ?? r.code}');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _verifyCode() async {
    final client = _client;
    if (client == null) return;
    final code = _code.text.trim();
    if (code.isEmpty) {
      setState(() => _msg = '请输入验证码');
      return;
    }
    setState(() {
      _busy = true;
      _msg = '';
    });
    try {
      final r = await client.login(widget.phone, code);
      if (!mounted) return;
      if (r.isError || r.data == null) {
        setState(() => _msg = '登录失败: ${r.msg ?? r.code}');
        return;
      }
      await _onLoginSuccess(
          client, r.data!.authorization, r.data!.userId.toInt());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _passwordLogin() async {
    final client = _client;
    if (client == null) return;
    final pwd = _password.text;
    if (pwd.isEmpty) {
      setState(() => _msg = '请输入密码');
      return;
    }
    setState(() {
      _busy = true;
      _msg = '';
    });
    try {
      final r = await client.loginByPassword(widget.phone, pwd);
      if (!mounted) return;
      if (r.isError || r.data == null) {
        setState(() => _msg = '登录失败: ${r.msg ?? r.code}');
        return;
      }
      // 密码登录成功后保存密码，便于 token 过期自动重登（v1 行为）
      await updateAccount(widget.phone, password: pwd);
      await _onLoginSuccess(
          client, r.data!.authorization, r.data!.userId.toInt());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// 登录成功：保存 token，并自动获取昵称设为备注名（v1 _fetch_and_set_nickname）。
  Future<void> _onLoginSuccess(
      ApiClient client, String token, int userId) async {
    await updateAccountToken(widget.phone, token, userId);

    // 自动获取昵称
    try {
      final profile = await client.fetchMyProfile();
      final nickname =
          (!profile.isError && profile.data != null && profile.data!.hasNickname())
              ? profile.data!.nickname
              : '';
      if (nickname.isNotEmpty) {
        final acc = await getAccount(widget.phone);
        if (acc != null && acc.name.isEmpty) {
          await updateAccount(widget.phone, name: nickname);
        }
      }
    } catch (_) {}

    await accountsStore.load();
    if (!mounted) return;
    Navigator.of(context).pop();
    EfToast.show(context, '登录成功', type: EfToastType.ok);
    accountsStore.refreshStatus();
  }
}
