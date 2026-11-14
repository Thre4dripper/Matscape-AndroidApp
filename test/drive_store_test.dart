// The Drive client against a small stand-in for Drive's REST API: the
// requests it sends, and what it does with Drive's answers.
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:matscape/app/drive_store.dart';

/// Just enough of Drive v3 for the client: an app-data folder of files.
class _FakeDrive {
  final files = <String, ({String name, String content, String parent})>{};
  final requests = <String>[];
  var next = 0;

  /// Tokens Drive accepts.
  final valid = <String>{'good'};

  late final HttpServer server;
  Uri get api => Uri.parse('http://127.0.0.1:${server.port}/drive/v3/');
  Uri get upload =>
      Uri.parse('http://127.0.0.1:${server.port}/upload/drive/v3/');

  Future<void> start() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen(_handle);
  }

  Map<String, String> _meta(String id) => {
    'id': id,
    'name': files[id]!.name,
    'modifiedTime': '2026-11-15T10:00:00.000Z',
  };

  Future<void> _handle(HttpRequest req) async {
    final path = req.uri.path, q = req.uri.queryParameters;
    final body = await utf8.decodeStream(req);
    requests.add('${req.method} $path ${req.uri.query}');
    final res = req.response..headers.contentType = ContentType.json;
    final auth = req.headers.value(HttpHeaders.authorizationHeader) ?? '';
    if (!valid.contains(auth.replaceFirst('Bearer ', ''))) {
      res.statusCode = 401;
      res.write(
        jsonEncode({
          'error': {'message': 'Invalid Credentials'},
        }),
      );
      return res.close();
    }
    if (req.method == 'GET' && path == '/drive/v3/files') {
      expect(q['spaces'], 'appDataFolder');
      final want = RegExp(r"name contains '([^']*)'").firstMatch(q['q']!)![1]!;
      res.write(
        jsonEncode({
          'files': [
            for (final id in files.keys)
              if (files[id]!.name.contains(want)) _meta(id),
          ],
        }),
      );
    } else if (req.method == 'GET' && q['alt'] == 'media') {
      final f = files[path.split('/').last];
      if (f == null) {
        res.statusCode = 404;
      } else {
        res.write(f.content);
      }
    } else if (req.method == 'POST' && q['uploadType'] == 'multipart') {
      // Metadata, then content, between boundaries.
      final type = req.headers.contentType!;
      final boundary = type.parameters['boundary']!;
      final parts = body.split('--$boundary');
      final meta = jsonDecode(parts[1].split('\r\n\r\n')[1].trim()) as Map;
      final content = parts[2].split('\r\n\r\n')[1];
      final id = 'f${next++}';
      files[id] = (
        name: meta['name'] as String,
        content: content.substring(0, content.length - 2),
        parent: (meta['parents'] as List).single as String,
      );
      res.write(jsonEncode(_meta(id)));
    } else if (req.method == 'PATCH' && q['uploadType'] == 'media') {
      final id = path.split('/').last;
      files[id] = (
        name: files[id]!.name,
        content: body,
        parent: files[id]!.parent,
      );
      res.write(jsonEncode(_meta(id)));
    } else if (req.method == 'DELETE') {
      files.remove(path.split('/').last);
      res.statusCode = 204;
    } else {
      res.statusCode = 400;
    }
    await res.close();
  }
}

void main() {
  late _FakeDrive drive;
  late DriveStore store;
  var token = 'good', renewals = 0;

  setUp(() async {
    drive = _FakeDrive();
    await drive.start();
    token = 'good';
    renewals = 0;
    store = DriveStore(
      ({bool renew = false}) async {
        if (renew) {
          renewals++;
          token = 'good';
        }
        return token;
      },
      api: drive.api,
      upload: drive.upload,
    );
  });
  tearDown(() => drive.server.close(force: true));

  test(
    'writes a new file into the app-data folder, then replaces it',
    () async {
      final f = await store.upload('sync-a.json', '{"v":1}');
      expect(drive.files[f.id]!.parent, 'appDataFolder');
      expect(drive.files[f.id]!.content, '{"v":1}');

      final g = await store.upload('sync-a.json', '{"v":2}', existing: f);
      expect(g.id, f.id);
      expect(drive.files, hasLength(1));
      expect(await store.download(g), '{"v":2}');
    },
  );

  test('lists only files whose names start with the prefix', () async {
    await store.upload('sync-a.json', '{}');
    await store.upload('sync-b.json', '{}');
    await store.upload('not-sync-c.json', '{}');
    final names = (await store.list('sync-')).map((f) => f.name).toList()
      ..sort();
    expect(names, ['sync-a.json', 'sync-b.json']);
  });

  test('content survives in full, including non-ASCII maths', () async {
    const text = '{"line":"det(A·Aᵀ − 2I) = λ₁ · √3"}';
    final f = await store.upload('sync-a.json', text);
    expect(await store.download(f), text);
  });

  test('deletes a file', () async {
    final f = await store.upload('sync-a.json', '{}');
    await store.delete(f);
    expect(drive.files, isEmpty);
  });

  test('a rejected token is renewed once, then the request succeeds', () async {
    token = 'expired';
    await store.upload('sync-a.json', '{}');
    expect(renewals, 1);
    expect(drive.files, hasLength(1));
  });

  test(
    'if the renewed token is rejected too, the user is signed out',
    () async {
      drive.valid.clear();
      await expectLater(
        store.list('sync-'),
        throwsA(
          isA<CloudException>()
              .having((e) => e.signedOut, 'signedOut', isTrue)
              .having((e) => e.message, 'message', 'Invalid Credentials'),
        ),
      );
      expect(renewals, 1);
    },
  );

  test('no connection is reported, not thrown as a crash', () async {
    await drive.server.close(force: true);
    await expectLater(store.list('sync-'), throwsA(isA<CloudException>()));
  });
}
