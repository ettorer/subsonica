import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/server_config.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/app_mark.dart';

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
  void initState() {
    super.initState();
    final session = context.read<SessionController>();
    _username.text = session.webUsername ?? '';
    _password.text = session.webPassword ?? '';
    final message = session.connectionError;
    if (message != null && message.isNotEmpty) {
      _error = localizeMessage(context.l10n, message);
      if (_addressFailed(message)) _askForUrl = true;
    }
  }

  @override
  void dispose() {
    _url.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit(String? savedUrl) async {
    final typed = normalizeServerUrl(_url.text);
    final stored = _usableServer(savedUrl);
    final baseUrl = typed ?? stored ?? _pageServer;
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
      if (error != null && _addressFailed(error)) _askForUrl = true;
    });
  }

  void _showBrowserDiagnostics() {
    final session = context.read<SessionController>();
    showDialog<void>(
      context: context,
      builder: (context) {
        final size = MediaQuery.sizeOf(context);
        return AlertDialog(
          title: const Text('Browser debug info'),
          content: SizedBox(
            width: size.width * 0.72,
            height: size.height * 0.58,
            child: _BrowserDebugContent(
              userAgent: session.browserUserAgent,
              isTeslaBrowser: session.isTeslaBrowser,
              diagnostics: session.browserDiagnostics,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(context.l10n.close),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final savedUrl = _usableServer(
      context.watch<SessionController>().webServerUrl,
    );
    final l10n = context.l10n;
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 50,
        leading: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onDoubleTap: kIsWeb ? _showBrowserDiagnostics : null,
          child: Navigator.canPop(context)
              ? const BackButton()
              : const SizedBox.expand(),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
            child: Transform.translate(
              offset: const Offset(0, -100),
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
                    if (_askForUrl) ...[
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
                              child: CircularProgressIndicator(
                                strokeWidth: 2.4,
                              ),
                            )
                          : Text(l10n.connect),
                    ),
                  ],
                ),
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

class _BrowserDebugContent extends StatefulWidget {
  const _BrowserDebugContent({
    required this.userAgent,
    required this.isTeslaBrowser,
    required this.diagnostics,
  });

  final String userAgent;
  final bool isTeslaBrowser;
  final String diagnostics;

  @override
  State<_BrowserDebugContent> createState() => _BrowserDebugContentState();
}

class _BrowserDebugContentState extends State<_BrowserDebugContent> {
  static const _maxEvents = 50;
  final _events = <String>[];

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_captureKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_captureKeyEvent);
    super.dispose();
  }

  bool _captureKeyEvent(KeyEvent event) {
    final modifiers = [
      if (HardwareKeyboard.instance.isControlPressed) 'Ctrl',
      if (HardwareKeyboard.instance.isAltPressed) 'Alt',
      if (HardwareKeyboard.instance.isShiftPressed) 'Shift',
      if (HardwareKeyboard.instance.isMetaPressed) 'Meta',
    ];
    final lines = [
      '${event.runtimeType} at ${event.timeStamp}',
      'Logical: ${event.logicalKey.debugName ?? "unknown"} '
          '(0x${event.logicalKey.keyId.toRadixString(16)})',
      'Physical: ${event.physicalKey.debugName ?? "unknown"} '
          '(HID 0x${event.physicalKey.usbHidUsage.toRadixString(16)})',
      'Label: ${event.logicalKey.keyLabel.isEmpty ? "(none)" : event.logicalKey.keyLabel}',
      'Modifiers: ${modifiers.isEmpty ? "(none)" : modifiers.join(" + ")}',
      'Synthesized: ${event.synthesized}',
    ].join('\n');
    if (!mounted) return false;
    setState(() {
      _events.insert(0, lines);
      if (_events.length > _maxEvents) _events.removeLast();
    });
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: SelectableText(
              'User agent:\n${widget.userAgent}\n\n'
              'Tesla browser (_teslaBrowser): ${widget.isTeslaBrowser}\n\n'
              '${widget.diagnostics}',
            ),
          ),
        ),
        const Divider(),
        Row(
          children: [
            Expanded(
              child: Text(
                'Keyboard events (${_events.length})',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: _events.isEmpty ? null : () => setState(_events.clear),
              child: const Text('Clear'),
            ),
          ],
        ),
        Expanded(
          flex: 3,
          child: _events.isEmpty
              ? const Center(
                  child: Text(
                    'Press the car buttons to inspect keyboard events.',
                    textAlign: TextAlign.center,
                  ),
                )
              : ListView.separated(
                  itemCount: _events.length,
                  separatorBuilder: (context, index) =>
                      const Divider(height: 1),
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: SelectableText(
                      _events[index],
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
        ),
      ],
    );
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
          'The server did not return a Subsonic response. Check the address.';
}
