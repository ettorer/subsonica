import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/server_config.dart';
import '../state/downloads.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';

class ServerForm extends StatefulWidget {
  const ServerForm({
    super.key,
    this.initial,
    this.initialError,
    required this.submitLabel,
    this.confirmSaved = false,
    this.onConnected,
  });

  final ServerConfig? initial;
  final String? initialError;
  final String submitLabel;
  final bool confirmSaved;
  final VoidCallback? onConnected;

  @override
  State<ServerForm> createState() => _ServerFormState();
}

class _ServerFormState extends State<ServerForm> {
  late final TextEditingController _name;
  late final TextEditingController _url;
  late final TextEditingController _username;
  late final TextEditingController _password;
  late String? _error = widget.initialError;
  var _busy = false;
  var _obscure = true;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _name = TextEditingController(text: initial?.name ?? '');
    _url = TextEditingController(text: initial?.baseUrl ?? '');
    _username = TextEditingController(text: initial?.username ?? '');
    _password = TextEditingController(text: initial?.password ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_error == null) return;
    setState(() => _error = null);
  }

  Future<void> _submit() async {
    final name = _name.text.trim();
    final baseUrl = normalizeServerUrl(_url.text);
    final username = _username.text.trim();
    if (name.isEmpty) {
      setState(() => _error = context.l10n.enterProfileName);
      return;
    }
    if (baseUrl == null) {
      setState(() {
        _error = context.l10n.enterServerAddress;
      });
      return;
    }
    if (username.isEmpty) {
      setState(() => _error = context.l10n.enterUsername);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await context.read<SessionController>().connect(
      ServerConfig(
        id: widget.initial?.id ?? '',
        name: name,
        baseUrl: baseUrl,
        username: username,
        password: _password.text,
      ),
    );
    if (!mounted) return;
    if (error == null) {
      await context.read<DownloadController>().setPreferOffline(false);
    }
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error;
    });
    if (error != null) return;
    if (widget.confirmSaved) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.l10n.connectionSaved)));
    }
    widget.onConnected?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _name,
          textCapitalization: TextCapitalization.sentences,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _clearError(),
          decoration: InputDecoration(
            labelText: context.l10n.profileName,
            hintText: context.l10n.profileNameHint,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _url,
          keyboardType: TextInputType.url,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.next,
          onChanged: (_) => _clearError(),
          decoration: InputDecoration(
            labelText: context.l10n.serverUrl,
            hintText: 'http://192.168.1.20:4533',
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _username,
          autocorrect: false,
          enableSuggestions: false,
          textInputAction: TextInputAction.next,
          autofillHints: const [AutofillHints.username],
          onChanged: (_) => _clearError(),
          decoration: InputDecoration(labelText: context.l10n.username),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _password,
          obscureText: _obscure,
          textInputAction: TextInputAction.done,
          autofillHints: const [AutofillHints.password],
          onChanged: (_) => _clearError(),
          onSubmitted: (_) => _busy ? null : _submit(),
          decoration: InputDecoration(
            labelText: context.l10n.password,
            suffixIcon: IconButton(
              tooltip: _obscure
                  ? context.l10n.showPassword
                  : context.l10n.hidePassword,
              onPressed: () => setState(() => _obscure = !_obscure),
              icon: Icon(
                _obscure
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          context.l10n.serverAddressHelp,
          style: const TextStyle(color: AppColors.muted, fontSize: 13, height: 1.35),
        ),
        if (_error != null) ...[
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                localizeMessage(context.l10n, _error!),
                style: const TextStyle(color: AppColors.danger, height: 1.35),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.onAccent,
                  ),
                )
              : Text(widget.submitLabel),
        ),
      ],
    );
  }
}
