class XtM3uEntry {
  final String url;
  final String name;
  final String? tvgId;
  final String? groupTitle;
  final String? logoUrl;
  final Map<String, String> attrs;

  const XtM3uEntry({
    required this.url,
    required this.name,
    this.tvgId,
    this.groupTitle,
    this.logoUrl,
    this.attrs = const {},
  });
}
