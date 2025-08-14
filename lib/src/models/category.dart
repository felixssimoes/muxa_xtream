// No JSON helpers needed here currently.

/// Category for live/VOD/series catalogs.
class XtCategory {
  final String id;
  final String name;
  final String kind; // 'live' | 'vod' | 'series'

  const XtCategory({required this.id, required this.name, required this.kind});

  factory XtCategory.fromJson(
    Map<String, dynamic> json, {
    required String kind,
  }) {
    final id = (json['category_id'] ?? json['id'] ?? '') as String;
    final name = (json['category_name'] ?? json['name'] ?? '') as String;
    return XtCategory(id: id, name: name, kind: kind);
  }
}
