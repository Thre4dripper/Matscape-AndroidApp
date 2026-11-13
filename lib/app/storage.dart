import 'dart:io';

import 'package:flutter/services.dart';

/// Where the app's single JSON document lives.
abstract class Storage {
  Future<String?> read();
  Future<void> write(String data);
}

/// A file in the app's private data directory. The directory comes from a
/// tiny platform channel (see MainActivity.kt / AppDelegate.swift) so the
/// app needs no storage plugins.
class FileStorage implements Storage {
  static const _channel = MethodChannel('matscape/storage');
  File? _file;

  Future<File> _resolve() async {
    final dir = await _channel.invokeMethod<String>('dataDir');
    return _file ??= File('$dir/matscape.json');
  }

  @override
  Future<String?> read() async {
    final f = await _resolve();
    return await f.exists() ? f.readAsString() : null;
  }

  @override
  Future<void> write(String data) async {
    final f = await _resolve();
    // Write beside the target, then rename, so a crash can't leave half a file.
    final tmp = File('${f.path}.tmp');
    await tmp.writeAsString(data, flush: true);
    await tmp.rename(f.path);
  }
}

class MemoryStorage implements Storage {
  MemoryStorage([this.data]);
  String? data;

  @override
  Future<String?> read() async => data;

  @override
  Future<void> write(String data) async => this.data = data;
}
