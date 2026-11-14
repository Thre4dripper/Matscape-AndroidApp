import 'dart:io';

import 'package:flutter/services.dart';

/// Where the app's single JSON document lives.
abstract class Storage {
  Future<String?> read();
  Future<void> write(String data);
}

/// A file in one of the app's private folders. The folder comes from a tiny
/// platform channel (see MainActivity.kt / AppDelegate.swift) so the app
/// needs no storage plugins.
///
/// The default is the app's data, which the platform backs up. [FileStorage.local]
/// is for what must stay with this one device, such as its sync id.
class FileStorage implements Storage {
  FileStorage({this.name = 'matscape.json', this.folder = 'dataDir'});

  /// Never backed up, so a phone restored from a backup starts fresh here.
  FileStorage.local(this.name) : folder = 'localDir';

  static const _channel = MethodChannel('matscape/storage');

  final String name;

  /// The platform method that gives the folder: `dataDir` or `localDir`.
  final String folder;
  File? _file;

  Future<File> _resolve() async {
    final dir = await _channel.invokeMethod<String>(folder);
    return _file ??= File('$dir/$name');
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

  /// The device's name ("Pixel 9", "iPad"), used to label conflict copies.
  /// Runs [work] after the app has left the screen, asking iOS for the
  /// time to finish it: iOS suspends an app within seconds otherwise.
  /// Android keeps the app running long enough by itself.
  static Future<void> whileLeaving(Future<void> Function() work) async {
    if (!Platform.isIOS) return work();
    int? task;
    try {
      task = await _channel.invokeMethod<int>('beginBackground');
    } catch (_) {
      // No extra time; try anyway.
    }
    try {
      await work();
    } finally {
      if (task != null) {
        try {
          await _channel.invokeMethod<void>('endBackground', task);
        } catch (_) {}
      }
    }
  }

  static Future<String> deviceName() async {
    try {
      final n = await _channel.invokeMethod<String>('deviceName');
      return n == null || n.trim().isEmpty ? 'another device' : n.trim();
    } catch (_) {
      return 'another device';
    }
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
