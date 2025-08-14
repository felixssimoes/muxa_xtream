/// Category for live/VOD/series catalogs.
class XtCategory {
  final String id;
  final String name;
  final String kind; // 'live' | 'vod' | 'series'

  const XtCategory({required this.id, required this.name, required this.kind});
}
