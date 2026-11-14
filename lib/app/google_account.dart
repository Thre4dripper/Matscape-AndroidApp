/// Access to the user's Google Drive app-data folder through Google Sign-In.
///
/// Only one permission is asked for, `drive.appdata`: the app's own hidden
/// folder in the user's Drive. Google is not used as an account for the app.
library;

import 'dart:io';

import 'package:google_sign_in/google_sign_in.dart';

import 'drive_store.dart';
import 'google_config.dart';

const driveAppDataScope = 'https://www.googleapis.com/auth/drive.appdata';

/// Why connecting didn't work.
class AccountException implements Exception {
  AccountException(this.message, {this.canceled = false});
  final String message;

  /// The user closed the sign-in themselves; nothing to report.
  final bool canceled;

  @override
  String toString() => 'AccountException: $message';
}

/// The Google account that holds the sync files. Tests use a fake.
abstract interface class DriveAccount {
  /// Whether Drive access granted earlier still holds, checked without
  /// showing anything to the user. Returns the account's email, an empty
  /// string when it is connected but the email isn't known here, or null
  /// when the user must connect again.
  Future<String?> restore();

  /// Asks the user to pick an account and allow Drive access. Returns the
  /// account's email.
  Future<String> connect();

  /// An access token for the Drive folder. With [renew], a token Drive
  /// rejected is dropped first.
  Future<String> token({bool renew = false});

  /// Signs out and withdraws Drive access.
  Future<void> disconnect();
}

class GoogleDriveAccount implements DriveAccount {
  GoogleDriveAccount();

  final _signIn = GoogleSignIn.instance;
  Future<void>? _ready;
  GoogleSignInAccount? _user;
  String? _token;

  Future<void> _init() => _ready ??= _signIn.initialize(
    clientId: Platform.isIOS && googleIosClientId.isNotEmpty
        ? googleIosClientId
        : null,
    serverClientId: Platform.isAndroid ? googleWebClientId : null,
  );

  GoogleSignInAuthorizationClient get _client =>
      _user?.authorizationClient ?? _signIn.authorizationClient;

  @override
  Future<String?> restore() async {
    await _init();
    try {
      if (Platform.isAndroid) {
        // Android's "lightweight" sign-in falls back to a sheet listing every
        // account on the device when it can't pick one by itself. At start-up
        // nothing may appear unasked, so only ask, silently, whether the
        // Drive access granted before still holds.
        final authz = await _signIn.authorizationClient.authorizationForScopes([
          driveAppDataScope,
        ]);
        if (authz == null) return null;
        _token = authz.accessToken;
        return '';
      }
      // iOS restores the previous sign-in silently.
      _user = await _signIn.attemptLightweightAuthentication();
      if (_user == null) return null;
      final authz = await _client.authorizationForScopes([driveAppDataScope]);
      if (authz == null) return null;
      _token = authz.accessToken;
      return _user!.email;
    } on GoogleSignInException {
      return null;
    }
  }

  @override
  Future<String> connect() async {
    await _init();
    try {
      _user = await _signIn.authenticate(scopeHint: [driveAppDataScope]);
      final authz = await _user!.authorizationClient.authorizeScopes([
        driveAppDataScope,
      ]);
      _token = authz.accessToken;
      return _user!.email;
    } on GoogleSignInException catch (e) {
      throw AccountException(
        e.description ?? 'Google sign-in failed (${e.code.name})',
        canceled: e.code == GoogleSignInExceptionCode.canceled,
      );
    }
  }

  @override
  Future<String> token({bool renew = false}) async {
    await _init();
    final old = _token;
    if (renew && old != null) {
      await _client.clearAuthorizationToken(accessToken: old);
      _token = null;
    }
    if (_token != null) return _token!;
    final authz = await _client.authorizationForScopes([driveAppDataScope]);
    if (authz == null) {
      throw CloudException(
        'Google Drive access needs to be allowed again',
        signedOut: true,
      );
    }
    return _token = authz.accessToken;
  }

  @override
  Future<void> disconnect() async {
    await _init();
    _token = null;
    _user = null;
    try {
      await _signIn.disconnect();
    } on GoogleSignInException {
      // Already disconnected.
    }
  }
}
