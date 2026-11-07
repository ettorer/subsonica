import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/server_config.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import 'server_form.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key, this.profile});

  final ServerConfig? profile;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final current = profile;
    final canDelete = current != null && session.profiles.length > 1;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          current == null ? context.l10n.newConnection : context.l10n.connection,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              children: [
                ServerForm(
                  initial: current,
                  submitLabel: context.l10n.save,
                  confirmSaved: true,
                  onConnected: () => Navigator.of(context).maybePop(),
                ),
              ],
            ),
          ),
          if (canDelete)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
                child: TextButton(
                  onPressed: session.connecting
                      ? null
                      : () => _delete(context, current),
                  child: Text(
                    context.l10n.deleteProfile,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, ServerConfig profile) async {
    final confirmed = await confirmDeleteProfile(context, profile.name);
    if (!confirmed || !context.mounted) return;
    await context.read<SessionController>().deleteProfile(profile.id);
    if (!context.mounted) return;
    Navigator.of(context).maybePop();
  }
}

Future<bool> confirmDeleteProfile(BuildContext context, String name) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(context.l10n.deleteProfileTitle),
        content: Text(context.l10n.deleteProfileBody(name)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.delete),
          ),
        ],
      );
    },
  );
  return confirmed == true;
}
