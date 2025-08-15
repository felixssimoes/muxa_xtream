<!--
This README describes the package. If you publish this package to pub.dev,
this README's contents appear on the landing page for your package.

For information about how to write a good package README, see the guide for
[writing package pages](https://dart.dev/tools/pub/writing-package-pages).

For general information about developing packages, see the Dart guide for
[creating packages](https://dart.dev/guides/libraries/create-packages)
and the Flutter guide for
[developing packages and plugins](https://flutter.dev/to/develop-packages).
-->

## Repository Guidelines

See [docs/AGENTS.md](docs/AGENTS.md) for contributor and development guidelines.

TODO: Put a short description of the package here that helps potential users
know whether this package might be useful for them.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

- Install Dart SDK and run `dart pub get` in the repo.
- Try the example app to exercise the public API as it evolves.
  - Mock mode (no external network):
    - `dart run example/main.dart --mock`
  - Real portal:
    - `dart run example/main.dart --portal https://your.portal/ --user USER --pass PASS`
  - The example is updated with every new API addition so you can quickly verify behavior end-to-end.

## Usage

- See `example/main.dart` for live usage of the APIs, including:
  - `XtreamClient.getUserAndServerInfo()`
  - Catalogs: `getLiveCategories`, `getVodCategories`, `getSeriesCategories`, and corresponding list fetchers
  - Details: `getVodInfo`, `getSeriesInfo`
  - EPG: `getShortEpg(streamId, limit)`
    - Note: some portals serve EPG only by `epg_channel_id` (not by `stream_id`).
      The client API also accepts `epgChannelId` and, when both are provided, retries internally if the `stream_id` query returns empty.
  - Diagnostics: `ping()` and `capabilities()`
  - URL builders: `liveUrl`, `vodUrl`, `seriesUrl`
  - Probe helper: `suggestStreamExtension`

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
