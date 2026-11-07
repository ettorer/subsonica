import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/download_controller.dart';
import '../state/session_controller.dart';
import '../widgets/app_mark.dart';
import 'connection_screen.dart';
import 'home_shell.dart';

class Gate extends StatelessWidget {
  const Gate({super.key});

  @override
  Widget build(BuildContext context) {
    final session = context.watch<SessionController>();
    final downloads = context.watch<DownloadController>();
    if (session.booting || !downloads.ready) return const _BootScreen();
    if (session.holdAtConnection ||
        (!session.isConnected && !downloads.preferOffline)) {
      return ConnectionScreen(
        initial: session.draft,
        initialError: session.connectionError,
        canLeave: session.holdAtConnection,
      );
    }
    return const HomeShell();
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppMark(),
            SizedBox(height: 20),
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
          ],
        ),
      ),
    );
  }
}
