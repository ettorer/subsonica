import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/server_config.dart';
import '../state/downloads.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import '../widgets/app_mark.dart';
import 'server_form.dart';

class ConnectionScreen extends StatelessWidget {
  const ConnectionScreen({
    super.key,
    this.initial,
    this.initialError,
    this.canLeave = false,
  });

  final ServerConfig? initial;
  final String? initialError;
  final bool canLeave;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final downloads = context.watch<DownloadController>();
    final profiles = session.profiles;
    return PopScope(
      canPop: !canLeave,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && canLeave) {
          context.read<SessionController>().closeConnection();
        }
      },
      child: Scaffold(
        appBar: canLeave
            ? AppBar(
                leading: IconButton(
                  tooltip: context.l10n.back,
                  onPressed: () =>
                      context.read<SessionController>().closeConnection(),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              )
            : null,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  children: [
                    const AppMark(),
                    const SizedBox(height: 16),
                    Text(
                      'Subsonica',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.l10n.playYourLibrary,
                      style: const TextStyle(color: Color(0xFFA7ADBA)),
                    ),
                    const SizedBox(height: 28),
                    if (profiles.isEmpty)
                      ServerForm(
                        initial: initial,
                        initialError: initialError,
                        submitLabel: context.l10n.connect,
                      )
                    else
                      _ProfilePicker(
                        profiles: profiles,
                        initialId: initial?.id ?? session.activeId,
                        error: initialError ?? session.connectionError,
                      ),
                    if (downloads.hasCompleted) ...[
                      const SizedBox(height: 12),
                      const _OfflineButton(),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OfflineButton extends StatelessWidget {
  const _OfflineButton();

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () async {
        await context.read<DownloadController>().setPreferOffline(true);
        if (!context.mounted) return;
        context.read<SessionController>().closeConnection();
      },
      icon: const Icon(Icons.download_done_rounded),
      label: Text(context.l10n.listenOffline),
    );
  }
}

class _ProfilePicker extends StatefulWidget {
  const _ProfilePicker({
    required this.profiles,
    required this.initialId,
    required this.error,
  });

  final List<ServerConfig> profiles;
  final String? initialId;
  final String? error;

  @override
  State<_ProfilePicker> createState() => _ProfilePickerState();
}

class _ProfilePickerState extends State<_ProfilePicker> {
  late String _selected = _initialSelection();

  String _initialSelection() {
    final requested = widget.initialId;
    for (final profile in widget.profiles) {
      if (profile.id == requested) return profile.id;
    }
    return widget.profiles.first.id;
  }

  @override
  void didUpdateWidget(_ProfilePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final stillThere = widget.profiles.any((profile) => profile.id == _selected);
    if (!stillThere) _selected = _initialSelection();
  }

  Future<void> _connect() async {
    final error = await context.read<SessionController>().useProfile(_selected);
    if (!mounted || error != null) return;
    await context.read<DownloadController>().setPreferOffline(false);
  }

  @override
  Widget build(BuildContext context) {
    final connecting = context.watch<SessionController>().connecting;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey(widget.profiles.map((profile) => profile.id).join(',')),
          initialValue: _selected,
          isExpanded: true,
          items: [
            for (final profile in widget.profiles)
              DropdownMenuItem(
                value: profile.id,
                child: Text(
                  profile.name,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: connecting
              ? null
              : (value) {
                  if (value == null) return;
                  setState(() => _selected = value);
                },
          decoration: InputDecoration(labelText: context.l10n.profileLabel),
        ),
        if (widget.error != null) ...[
          const SizedBox(height: 14),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                localizeMessage(context.l10n, widget.error!),
                style: const TextStyle(color: AppColors.danger, height: 1.35),
              ),
            ),
          ),
        ],
        const SizedBox(height: 18),
        FilledButton(
          onPressed: connecting ? null : _connect,
          child: connecting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.4,
                    color: AppColors.onAccent,
                  ),
                )
              : Text(context.l10n.connect),
        ),
      ],
    );
  }
}
