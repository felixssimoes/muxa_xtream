// Lightweight JSON helpers to tolerate variant types from Xtream-style portals.
import 'dart:convert';

int? asInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) {
    final str = value.trim();
    if (str.isEmpty) return null;
    return int.tryParse(str);
  }
  return null;
}

double? asDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) {
    final str = value.trim();
    if (str.isEmpty) return null;
    return double.tryParse(str);
  }
  return null;
}

bool? asBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    switch (value.trim().toLowerCase()) {
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

String? asString(dynamic value) {
  if (value == null) return null;
  return value.toString();
}

/// Heuristically decode Base64-encoded UTF-8 strings.
/// Returns the original string if decoding fails or looks non-textual.
String maybeDecodeBase64Utf8(String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return text;
  // Quick filter: base64 alphabet and length multiple of 4
  final base64Re = RegExp(r'^[A-Za-z0-9+/]+={0,2}$');
  if (!base64Re.hasMatch(trimmed) || (trimmed.length % 4) != 0) {
    return text;
  }
  try {
    final decodedBytes = base64Decode(trimmed);
    final decodedText = utf8.decode(decodedBytes, allowMalformed: true);
    if (decodedText.isNotEmpty && _isMostlyTextual(decodedText)) {
      return decodedText;
    }
  } catch (_) {
    // fall through
  }
  return text;
}

bool _isMostlyTextual(String text) {
  if (text.isEmpty) return false;
  var printable = 0;
  var total = 0;
  for (final rune in text.runes) {
    total++;
    if (rune == 0x09 || rune == 0x0A || rune == 0x0D) {
      printable++;
      continue;
    }
    if (rune >= 0x20) printable++;
  }
  if (total == 0) return false;
  return printable / total >= 0.9;
}

DateTime? parseDateUtc(dynamic value) {
  if (value == null) return null;
  // Support epoch seconds/milliseconds or ISO strings.
  if (value is int) {
    return _fromEpoch(value);
  }
  if (value is String) {
    final str = value.trim();
    if (str.isEmpty) return null;
    final numValue = int.tryParse(str);
    if (numValue != null) return _fromEpoch(numValue);
    final dt = DateTime.tryParse(str);
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
  for (final key in keys) {
    if (map.containsKey(key)) return map[key] as T?;
  }
  return null;
}
