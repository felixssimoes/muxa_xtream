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
}
