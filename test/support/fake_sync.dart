// Stand-ins for Google Drive and the Google account, shared by the tests.
import 'package:matscape/app/drive_store.dart';
import 'package:matscape/app/google_account.dart';

/// A Drive app-data folder in memory.
class FakeCloud implements CloudStore {
  final files = <String, (String name, String content, DateTime modified)>{};
  var uploads = 0, lists = 0, next = 0;
  var tick = DateTime.utc(2026, 11, 15);

  /// When set, every call fails like a dropped connection.
  bool offline = false;

  /// When set, every call fails like a withdrawn permission.
  bool revoked = false;

  void _check() {
    if (revoked) throw CloudException('Invalid Credentials', signedOut: true);
    if (offline) throw CloudException('No connection');
  }

  @override
  Future<List<CloudFile>> list(String prefix) async {
    lists++;
    _check();
    return [
      for (final e in files.entries)
        if (e.value.$1.startsWith(prefix))
          CloudFile(e.key, e.value.$1, e.value.$3),
    ];
  }

  @override
  Future<String> download(CloudFile file) async {
    _check();
    return files[file.id]!.$2;
  }

  @override
  Future<CloudFile> upload(
    String name,
    String content, {
    CloudFile? existing,
  }) async {
    _check();
    uploads++;
    tick = tick.add(const Duration(seconds: 1));
    final id = existing?.id ?? 'f${next++}';
    files[id] = (name, content, tick);
    return CloudFile(id, name, tick);
  }

  @override
  Future<void> delete(CloudFile file) async {
    _check();
    files.remove(file.id);
  }
}

class FakeAccount implements DriveAccount {
  var connected = false, cancel = false;

  @override
  Future<String> connect() async {
    if (cancel) throw AccountException('closed', canceled: true);
    connected = true;
    return 'user@example.com';
  }

  @override
  Future<String?> restore() async => connected ? 'user@example.com' : null;

  @override
  Future<String> token({bool renew = false}) async => 'token';

  @override
  Future<void> disconnect() async => connected = false;
}
