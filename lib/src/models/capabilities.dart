import '../util/json.dart';

/// Provider/library capabilities distilled from server traits.
class XtCapabilities {
  final bool supportsShortEpg;
  final bool supportsExtendedEpg;
  final bool supportsM3u;
  final bool supportsXmltv;

  const XtCapabilities({
    this.supportsShortEpg = true,
    this.supportsExtendedEpg = false,
    this.supportsM3u = true,
    this.supportsXmltv = true,
  });

  factory XtCapabilities.fromJson(Map<String, dynamic> json) {
    final short = asBool(json['short_epg']) ?? true;
    final extended = asBool(json['extended_epg']) ?? false;
    final m3u = asBool(json['m3u']) ?? true;
    final xmltv = asBool(json['xmltv']) ?? true;
    return XtCapabilities(
      supportsShortEpg: short,
      supportsExtendedEpg: extended,
      supportsM3u: m3u,
      supportsXmltv: xmltv,
    );
  }
}
