import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/server_config.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/app_mark.dart';
import 'settings_screen.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _url = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  var _busy = false;
  var _obscure = true;
  var _askForUrl = false;

  String get _pageServer {
    if (kIsWeb) {
      final origin = Uri.base.origin;
      if (origin.isNotEmpty && origin != 'null') return origin;
    }
    return 'http://127.0.0.1:4533';
  }

  @override
  void dispose() {
    _url.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(String? savedUrl) async {
    final stored = _usableServer(savedUrl);
    final typed = normalizeServerUrl(_url.text);
    final baseUrl = stored ?? typed ?? _pageServer;
    final username = _username.text.trim();
    if (username.isEmpty) {
      setState(() => _error = context.l10n.enterUsername);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await context.read<SessionController>().signIn(
      baseUrl: baseUrl,
      username: username,
      password: _password.text,
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = error == null ? null : localizeMessage(context.l10n, error);
      if (error != null &&
          stored == null &&
          typed == null &&
          _addressFailed(error)) {
        _askForUrl = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final savedUrl = _usableServer(
      context.watch<SessionController>().webServerUrl,
    );
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            tooltip: l10n.settingsTitle,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SettingsScreen()),
              );
            },
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(child: AppMark()),
                  const SizedBox(height: 28),
                  Text(
                    l10n.signIn,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  if (savedUrl == null && _askForUrl) ...[
                    TextField(
                      controller: _url,
                      keyboardType: TextInputType.url,
                      autocorrect: false,
                      enableSuggestions: false,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.url],
                      onChanged: (_) => _clearError(),
                      decoration: InputDecoration(
                        labelText: l10n.serverUrl,
                        hintText: _pageServer,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _username,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.username],
                    onChanged: (_) => _clearError(),
                    decoration: InputDecoration(labelText: l10n.username),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: _obscure,
                    autocorrect: false,
                    enableSuggestions: false,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onChanged: (_) => _clearError(),
                    onSubmitted: (_) {
                      if (!_busy) _submit(savedUrl);
                    },
                    decoration: InputDecoration(
                      labelText: l10n.password,
                      suffixIcon: IconButton(
                        tooltip: _obscure
                            ? l10n.showPassword
                            : l10n.hidePassword,
                        onPressed: () => setState(() => _obscure = !_obscure),
                        icon: Icon(
                          _obscure
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      style: const TextStyle(
                        color: AppColors.danger,
                        height: 1.35,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : () => _submit(savedUrl),
                    child: _busy
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.4),
                          )
                        : Text(l10n.connect),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _clearError() {
    if (_error == null) return;
    setState(() => _error = null);
  }
}

String? _usableServer(String? url) {
  if (url == null || url.isEmpty) return null;
  final uri = Uri.tryParse(url);
  if (uri == null) return url;
  final host = uri.host.toLowerCase();
  final loopback = host == 'localhost' || host == '127.0.0.1';
  if (loopback && uri.port == 4533) return null;
  return url;
}

bool _addressFailed(String error) {
  return error == 'Cannot reach the server. Check the address.' ||
      error == 'The server took too long to respond.' ||
      error == 'The secure connection failed.' ||
      error ==
          'The server did not return a Subsonic response. Check the address.' ||
      error == 'Something went wrong. Try again.' ||
      error.startsWith('The server returned HTTP ');
}
