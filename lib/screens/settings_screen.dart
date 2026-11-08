import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/context_l10n.dart';
import '../models/server_config.dart';
import '../state/downloads.dart';
import '../state/karaoke.dart';
import '../state/locale_controller.dart';
import '../state/session_controller.dart';
import '../theme/app_colors.dart';
import '../util/format.dart';
import '../widgets/mini_player.dart';
import 'downloads_screen.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const _WebSettings();
    final l10n = context.l10n;
    final session = context.watch<SessionController>();
    final downloads = context.watch<DownloadController>();
    final locale = context.watch<LocaleController>();
    final canDelete = session.profiles.length > 1;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey(locale.preference),
                  initialValue: locale.preference,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.language),
                  items: [
                    DropdownMenuItem(
                      value: 'auto',
                      child: Text(l10n.localeAutomatic),
                    ),
                    const DropdownMenuItem(value: 'en', child: Text('English')),
                    const DropdownMenuItem(
                      value: 'it',
                      child: Text('Italiano'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    context.read<LocaleController>().setPreference(value);
                  },
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.offlineMode),
                  subtitle: Text(
                    l10n.offlineModeDetail,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  value: downloads.preferOffline,
                  onChanged: session.connecting
                      ? null
                      : (value) => downloads.setPreferOffline(value),
                ),
                const _KaraokeTile(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.downloadsTitle),
                  subtitle: Text(
                    l10n.onThisPhone(formatByteSize(downloads.byteCount)),
                    style: const TextStyle(color: AppColors.muted),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const DownloadsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                Text(
                  l10n.connectionsTitle,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 4),
                for (final profile in session.profiles)
                  _ProfileTile(
                    profile: profile,
                    inUse:
                        profile.id == session.activeId && session.isConnected,
                    canDelete: canDelete,
                  ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: session.connecting
                      ? null
                      : () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const ProfileScreen(),
                            ),
                          );
                        },
                  icon: const Icon(Icons.add_rounded),
                  label: Text(l10n.addConnection),
                ),
              ],
            ),
          ),
          const MiniPlayerSlot(),
        ],
      ),
    );
  }
}

class _KaraokeTile extends StatelessWidget {
  const _KaraokeTile();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final karaoke = context.watch<KaraokeController>();
    final url = karaoke.url;
    final secureUrl = karaoke.secureUrl;
    const addressStyle = TextStyle(
      color: AppColors.remote,
      fontSize: 16,
      fontWeight: FontWeight.w700,
    );
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(l10n.karaoke),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            karaoke.failed
                ? l10n.karaokeFailed
                : karaoke.enabled && url == null
                ? l10n.karaokeNoAddress
                : karaoke.enabled
                ? l10n.karaokeOpen
                : l10n.karaokeDetail,
            style: TextStyle(
              color: karaoke.failed ? AppColors.danger : AppColors.muted,
            ),
          ),
          if (secureUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SelectableText(secureUrl, style: addressStyle),
            ),
          if (url != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: SelectableText(url, style: addressStyle),
            ),
        ],
      ),
      value: karaoke.enabled,
      onChanged: karaoke.busy
          ? null
          : (value) => context.read<KaraokeController>().setEnabled(value),
    );
  }
}

class _ProfileTile extends StatelessWidget {
  const _ProfileTile({
    required this.profile,
    required this.inUse,
    required this.canDelete,
  });

  final ServerConfig profile;
  final bool inUse;
  final bool canDelete;

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        tileColor: inUse ? const Color(0x33F0B429) : AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: inUse ? AppColors.accent : AppColors.outline),
        ),
        contentPadding: const EdgeInsets.only(left: 16),
        title: Text(profile.name, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          inUse
              ? context.l10n.connectedProfile(profile.baseUrl)
              : profile.baseUrl,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: inUse ? AppColors.text : AppColors.muted),
        ),
        onTap: session.connecting ? null : () => _switchTo(context),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: context.l10n.edit,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => ProfileScreen(profile: profile),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined),
            ),
            if (canDelete)
              IconButton(
                tooltip: context.l10n.delete,
                onPressed: session.connecting ? null : () => _delete(context),
                icon: const Icon(Icons.delete_outline_rounded),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _switchTo(BuildContext context) async {
    final session = context.read<SessionController>();
    if (profile.id == session.activeId && session.isConnected) return;
    final error = await session.useProfile(profile.id);
    if (!context.mounted || error != null) {
      if (context.mounted && error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(localizeMessage(context.l10n, error))),
        );
      }
      return;
    }
    await context.read<DownloadController>().setPreferOffline(false);
  }

  Future<void> _delete(BuildContext context) async {
    final confirmed = await confirmDeleteProfile(context, profile.name);
    if (!confirmed || !context.mounted) return;
    await context.read<SessionController>().deleteProfile(profile.id);
  }
}

class _WebSettings extends StatefulWidget {
  const _WebSettings();

  @override
  State<_WebSettings> createState() => _WebSettingsState();
}

class _WebSettingsState extends State<_WebSettings> {
  late final TextEditingController _url;
  String? _error;
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(
      text: context.read<SessionController>().webServerUrl ?? '',
    );
  }

  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final session = context.read<SessionController>();
    final wasConnected = session.isConnected;
    final error = await session.updateWebServerUrl(_url.text);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _busy = false;
        _error = localizeMessage(context.l10n, error);
      });
      return;
    }
    if (wasConnected && !session.isConnected) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final locale = context.watch<LocaleController>();
    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                DropdownButtonFormField<String>(
                  key: ValueKey(locale.preference),
                  initialValue: locale.preference,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l10n.language),
                  items: [
                    DropdownMenuItem(
                      value: 'auto',
                      child: Text(l10n.localeAutomatic),
                    ),
                    const DropdownMenuItem(value: 'en', child: Text('English')),
                    const DropdownMenuItem(
                      value: 'it',
                      child: Text('Italiano'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    context.read<LocaleController>().setPreference(value);
                  },
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _url,
                  keyboardType: TextInputType.url,
                  autocorrect: false,
                  enableSuggestions: false,
                  autofillHints: const [AutofillHints.url],
                  onChanged: (_) {
                    if (_error == null) return;
                    setState(() => _error = null);
                  },
                  decoration: InputDecoration(
                    labelText: l10n.serverUrl,
                    hintText: 'https://music.example.com',
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
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
                  onPressed: _busy ? null : _save,
                  child: Text(l10n.save),
                ),
              ],
            ),
          ),
          const MiniPlayerSlot(),
        ],
      ),
    );
  }
}
