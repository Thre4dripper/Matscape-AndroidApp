/// The app's Google Cloud OAuth client ids (project "Matscape",
/// `hale-function-467207-i8`).
///
/// These identify the app to Google's sign-in; they are public, not secrets.
/// iOS also needs its client id and reversed client id in
/// `ios/Runner/Info.plist` (`GIDClientID`, `CFBundleURLSchemes`).
library;

/// The "Web application" client. Android's sign-in needs it as the server
/// client id even though there is no server.
const googleWebClientId =
    '13296046220-ta91ip9k0rlpupkg6mb65jvpfjlj4pg2.apps.googleusercontent.com';

/// The "iOS" client.
const googleIosClientId =
    '13296046220-ejmvea5vqik1s1konv9qi0cl385bgt61.apps.googleusercontent.com';

/// Whether this build can connect to Google Drive at all.
bool get googleConfigured => googleWebClientId.isNotEmpty;
