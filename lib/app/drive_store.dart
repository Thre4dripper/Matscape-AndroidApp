/// The user's Google Drive app-data folder, reached through Drive's REST API.
///
/// Files there are private to Matscape: they don't show up in the user's
/// Drive, only under Drive settings → Manage apps, where the user can delete
/// them. Nothing goes through a server of ours.
library;

import 'dart:convert';
import 'dart:io';

/// A file in the cloud folder.
class CloudFile {
  const CloudFile(this.id, this.name, this.modified);
  final String id;
  final String name;

  /// When it was last written, as the cloud reports it.
  final DateTime modified;
}

/// Where sync files are kept. [DriveStore] is the real one; tests use a fake.
abstract interface class CloudStore {
  /// The files whose names start with [prefix].
  Future<List<CloudFile>> list(String prefix);
  Future<String> download(CloudFile file);

  /// Writes [name], replacing [existing] when there is one.
  Future<CloudFile> upload(String name, String content, {CloudFile? existing});
  Future<void> delete(CloudFile file);
}

/// The cloud said no, or couldn't be reached.
class CloudException implements Exception {
  CloudException(this.message, {this.status, this.signedOut = false});
  final String message;
  final int? status;

  /// The user's permission was withdrawn or has run out: sign in again.
  final bool signedOut;

  @override
  String toString() => 'CloudException($status): $message';
}

/// Gives an access token for the `drive.appdata` scope. With [renew] the
/// cached one is thrown away first, after Drive has rejected it.
typedef TokenSource = Future<String> Function({bool renew});

class DriveStore implements CloudStore {
  DriveStore(this._token, {Uri? api, Uri? upload, HttpClient? client})
    : _api = api ?? Uri.parse('https://www.googleapis.com/drive/v3/'),
      _upload =
          upload ?? Uri.parse('https://www.googleapis.com/upload/drive/v3/'),
      _http = client ?? HttpClient();

  final TokenSource _token;
  final Uri _api, _upload;
  final HttpClient _http;

  static const _timeout = Duration(seconds: 30);
  static const _folder = 'appDataFolder';

  @override
  Future<List<CloudFile>> list(String prefix) async {
    final files = <CloudFile>[];
    String? page;
    do {
      final body = await _send(
        'GET',
        _api
            .resolve('files')
            .replace(
              queryParameters: {
                'spaces': _folder,
                'q':
                    "name contains '${prefix.replaceAll("'", r"\'")}' and trashed = false",
                'fields': 'nextPageToken, files(id, name, modifiedTime)',
                'pageSize': '100',
                'pageToken': ?page,
              },
            ),
      );
      final j = jsonDecode(body) as Map<String, dynamic>;
      for (final f in j['files'] as List? ?? const []) {
        final m = f as Map<String, dynamic>;
        final name = m['name'] as String;
        // "contains" also matches the middle of a name.
        if (!name.startsWith(prefix)) continue;
        files.add(_file(m));
      }
      page = j['nextPageToken'] as String?;
    } while (page != null);
    return files;
  }

  @override
  Future<String> download(CloudFile file) => _send(
    'GET',
    _api.resolve('files/${file.id}').replace(queryParameters: {'alt': 'media'}),
  );

  @override
  Future<CloudFile> upload(
    String name,
    String content, {
    CloudFile? existing,
  }) async {
    final String body;
    if (existing != null) {
      body = await _send(
        'PATCH',
        _upload
            .resolve('files/${existing.id}')
            .replace(
              queryParameters: {
                'uploadType': 'media',
                'fields': 'id, name, modifiedTime',
              },
            ),
        body: utf8.encode(content),
        type: 'application/json; charset=utf-8',
      );
    } else {
      // Metadata and content in one request.
      const boundary = 'matscape-sync-boundary';
      final meta = jsonEncode({
        'name': name,
        'parents': [_folder],
        'mimeType': 'application/json',
      });
      final parts =
          '--$boundary\r\n'
          'Content-Type: application/json; charset=UTF-8\r\n\r\n'
          '$meta\r\n'
          '--$boundary\r\n'
          'Content-Type: application/json; charset=UTF-8\r\n\r\n'
          '$content\r\n'
          '--$boundary--\r\n';
      body = await _send(
        'POST',
        _upload
            .resolve('files')
            .replace(
              queryParameters: {
                'uploadType': 'multipart',
                'fields': 'id, name, modifiedTime',
              },
            ),
        body: utf8.encode(parts),
        type: 'multipart/related; boundary=$boundary',
      );
    }
    return _file(jsonDecode(body) as Map<String, dynamic>);
  }

  @override
  Future<void> delete(CloudFile file) async {
    await _send('DELETE', _api.resolve('files/${file.id}'));
  }

  CloudFile _file(Map<String, dynamic> m) => CloudFile(
    m['id'] as String,
    m['name'] as String,
    DateTime.tryParse(m['modifiedTime'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  /// Sends a request with the token, trying once more with a new token if
  /// Drive rejects it. Returns the response body.
  Future<String> _send(
    String method,
    Uri url, {
    List<int>? body,
    String? type,
  }) async {
    for (var attempt = 0; ; attempt++) {
      final token = await _token(renew: attempt > 0);
      final HttpClientResponse res;
      final String text;
      try {
        final req = await _http.openUrl(method, url).timeout(_timeout);
        req.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
        if (type != null) req.headers.contentType = ContentType.parse(type);
        if (body != null) {
          req.contentLength = body.length;
          req.add(body);
        }
        res = await req.close().timeout(_timeout);
        text = await utf8.decodeStream(res).timeout(_timeout);
      } on SocketException catch (e) {
        throw CloudException('No connection: ${e.message}');
      } on HttpException catch (e) {
        throw CloudException('Connection failed: ${e.message}');
      } on Exception catch (e) {
        throw CloudException('Connection failed: $e');
      }
      if (res.statusCode == 401 && attempt == 0) continue;
      if (res.statusCode >= 200 && res.statusCode < 300) return text;
      throw CloudException(
        _reason(text) ?? 'Google Drive answered ${res.statusCode}',
        status: res.statusCode,
        signedOut: res.statusCode == 401,
      );
    }
  }

  String? _reason(String body) {
    try {
      final e = (jsonDecode(body) as Map<String, dynamic>)['error'];
      return (e as Map<String, dynamic>)['message'] as String?;
    } catch (_) {
      return null;
    }
  }
}
