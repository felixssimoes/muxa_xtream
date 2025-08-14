// Lightweight JSON helpers to tolerate variant types from Xtream-style portals.

int? asInt(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is double) return v.toInt();
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return null;
    return int.tryParse(s);
  }
  return null;
}

double? asDouble(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return null;
    return double.tryParse(s);
  }
  return null;
}

bool? asBool(dynamic v) {
  if (v == null) return null;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    switch (v.trim().toLowerCase()) {
      case '1':
      case 'true':
      case 'yes':
      case 'y':
      case 'active':
        return true;
      case '0':
      case 'false':
      case 'no':
      case 'n':
      case 'inactive':
        return false;
    }
  }
  return null;
}

String? asString(dynamic v) {
  if (v == null) return null;
  return v.toString();
}

DateTime? parseDateUtc(dynamic v) {
  if (v == null) return null;
  // Support epoch seconds/milliseconds or ISO strings.
  if (v is int) {
    return _fromEpoch(v);
  }
  if (v is String) {
    final s = v.trim();
    if (s.isEmpty) return null;
    final n = int.tryParse(s);
    if (n != null) return _fromEpoch(n);
    final dt = DateTime.tryParse(s);
    return dt?.toUtc();
  }
  return null;
}

DateTime _fromEpoch(int value) {
  // Heuristic: treat large numbers as milliseconds.
  final isMillis = value > 1e12; // ~ Sat Nov 20 33658
  final ms = isMillis ? value : value * 1000;
  return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toUtc();
}

T? pick<T>(Map map, List<String> keys) {
  for (final k in keys) {
    if (map.containsKey(k)) return map[k] as T?;
  }
  return null;
}
