// Public API barrel for the muxa_xtream package.
// Exports client, models, errors, URL builders, and optional M3U/XMLTV helpers.

export 'core/models.dart';
export 'core/errors.dart';
export 'core/redaction.dart';
export 'core/logger.dart';
export 'http/adapter.dart';
export 'http/default_adapter.dart';
export 'http/adapter_factory.dart';
export 'client.dart';
export 'core/cancellation.dart';
// Models (Phase 3)
export 'models/user.dart';
export 'models/server.dart';
export 'models/category.dart';
export 'models/live.dart';
export 'models/vod.dart';
export 'models/series.dart';
export 'models/epg.dart';
export 'models/capabilities.dart';
export 'models/health.dart';
export 'models/account.dart';
// URL builders (Phase 4)
export 'url/builders.dart';
export 'url/probe.dart';
// Optional M3U (Phase 6)
export 'models/m3u.dart';
export 'm3u/parser.dart';
// Optional XMLTV (Phase 7)
export 'models/xmltv.dart';
export 'xmltv/parser.dart';

/// Package version string.
const String muxaXtreamVersion = '0.1.0';
