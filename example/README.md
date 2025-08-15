Example console app for muxa_xtream

Run a quick demo that fetches account/server info and prints sample stream URLs.

Prerequisites
- Flutter SDK installed (for `flutter pub get`).

Setup
- From repository root, install dependencies:
  - `flutter pub get`

Usage
- Real portal:
  - `dart run example/main.dart --portal https://your.portal/ --user USER --pass PASS`
  - Optional: `--self-signed` to allow self-signed TLS when using the default HTTP adapter.
  - Optional: `--probe URL` to test the probe helper against a specific stream URL.
- Local mock server (no external network):
  - `dart run example/main.dart --mock`

Notes
- The example uses the package public API: `XtreamClient.getUserAndServerInfo`, URL builders (`liveUrl`, `vodUrl`, `seriesUrl`), and `suggestStreamExtension`.
- Credentials are never printed in clear; URLs are redacted in logs.

