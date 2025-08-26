/// muxa_xtream — Xtream Codes IPTV client for Dart/Flutter.
///
/// This package provides:
/// - Typed models for Xtream endpoints
/// - A resilient HTTP layer with timeouts, retries, and cancellation
/// - URL builders for live, VOD, and series streams
/// - Helpers for EPG (short) plus M3U and XMLTV utilities
///
/// Getting started:
/// ```dart
/// import 'package:muxa_xtream/muxa_xtream.dart';
///
/// void main() async {
///   final portal = XtreamPortal(Uri.parse('http://host:port'));
///   final creds = XtreamCredentials(user: 'user', pass: 'pass');
///   final client = XtreamClient(portal: portal, credentials: creds);
///   await client.ping();
/// }
/// ```
///
/// See `example/main.dart` for a runnable end-to-end sample.
library;

// Public API surface (bootstrap)
export 'src/api.dart';
