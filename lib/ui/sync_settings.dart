import 'package:material_ui/material_ui.dart';

import '../app/sync.dart';
import 'icons.dart';
import 'theme.dart';
import 'widgets.dart';

/// The "Backup & sync" card at the top of Settings: connect Google Drive,
/// see when the last sync was, sync now, disconnect, and choose when other
/// devices' changes come in.
class SyncSettings extends StatelessWidget {
  const SyncSettings({super.key, required this.sync});
  final SyncController sync;

  @override
  Widget build(BuildContext context) {
    final pal = context.pal;
    final s = sync.status;
    final on = sync.connected && s != SyncStatus.connecting;
    final title = on ? (sync.email ?? 'Google Drive') : 'Back up and sync';
    final String line;
    Color tone = pal.ink3;
    switch (s) {
      case SyncStatus.off:
        line = sync.available
            ? 'Keep your workspaces in your own Google Drive, in step on all your devices. They are stored privately in Drive\'s app data. Matscape has no servers, so nothing goes anywhere else.'
            : 'Not available in this build.';
      case SyncStatus.connecting:
        line = 'Waiting for Google…';
      case SyncStatus.syncing:
        line = 'Syncing…';
      case SyncStatus.ready:
        line = sync.error ?? 'Synced ${_ago(sync.lastSynced)}';
        if (sync.error != null) tone = pal.note;
      case SyncStatus.failed:
        line =
            'Couldn\'t sync: ${sync.error ?? 'unknown error'}. Your work is safe on this device, and it will try again.';
        tone = pal.danger;
      case SyncStatus.reconnect:
        line =
            sync.error ??
            'Google Drive access has run out. Connect again to keep syncing.';
        tone = pal.danger;
    }

    final busy = s == SyncStatus.connecting || s == SyncStatus.syncing;
    final connectLabel = s == SyncStatus.reconnect
        ? 'Connect again'
        : 'Connect Google Drive';
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: Ico(
                  MIcon.cloud,
                  size: 22,
                  color: on ? pal.accentInk : pal.ink3,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: Fs.body,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                        color: pal.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        line,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.45,
                          color: tone,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (busy) ...[
                const SizedBox(width: 12),
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: pal.accent,
                  ),
                ),
              ],
            ],
          ),
          if (sync.available) ...[
            const SizedBox(height: 14),
            // Btn fills the space it is given along a Row.
            if (!on || s == SyncStatus.reconnect)
              Row(
                children: [
                  Btn(
                    connectLabel,
                    icon: MIcon.cloud,
                    kind: BtnKind.primary,
                    onTap: busy ? null : () => _connect(context),
                  ),
                ],
              )
            else
              Row(
                children: [
                  Btn(
                    'Sync now',
                    icon: MIcon.sync,
                    onTap: busy ? null : sync.sync,
                  ),
                  const SizedBox(width: 8),
                  Btn(
                    'Disconnect',
                    onTap: busy ? null : () => _disconnect(context),
                  ),
                ],
              ),
            if (on && s != SyncStatus.reconnect) ...[
              const SizedBox(height: 18),
              Text(
                'Changes from your other devices',
                style: TextStyle(
                  fontSize: Fs.body,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                  color: pal.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sync.live
                    ? 'Shown while you work: Matscape looks for them every 30 seconds while it\'s open.'
                    : 'Brought in when you open Matscape or come back to it, so nothing changes while you work.',
                style: TextStyle(fontSize: 13, height: 1.45, color: pal.ink3),
              ),
              const SizedBox(height: 10),
              Seg<bool>(
                options: const [(false, 'On opening'), (true, 'Live')],
                value: sync.live,
                onChanged: sync.setLive,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Future<void> _connect(BuildContext context) async {
    final report = await sync.connect();
    if (!context.mounted || report == null) return;
    final n = report.added + report.updated;
    showToast(
      context,
      n == 0
          ? 'Backed up to Google Drive'
          : 'Merged with your Drive: $n workspace${n == 1 ? '' : 's'} brought in',
    );
  }

  Future<void> _disconnect(BuildContext context) async {
    final ok = await confirmDialog(
      context,
      title: 'Disconnect Google Drive?',
      body: 'Your workspaces stay on this device and stop syncing. The copy in your Drive stays too, so you can connect again later.',
      ok: 'Disconnect',
      danger: false,
    );
    if (!ok) return;
    await sync.disconnect();
    if (context.mounted) showToast(context, 'Google Drive disconnected');
  }
}

/// "just now", "5 minutes ago", "yesterday"…
String _ago(int? ms) {
  if (ms == null) return 'just now';
  final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
  if (d.inSeconds < 60) return 'just now';
  if (d.inMinutes < 60) {
    return '${d.inMinutes} minute${d.inMinutes == 1 ? '' : 's'} ago';
  }
  if (d.inHours < 24) {
    return '${d.inHours} hour${d.inHours == 1 ? '' : 's'} ago';
  }
  if (d.inDays == 1) return 'yesterday';
  return '${d.inDays} days ago';
}
