import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import '../models/xmltv.dart';

/// Parse an XMLTV stream into a stream of [XtXmltvEvent] using an isolate.
///
/// The input stream is forwarded to a parsing isolate which incrementally
/// tokenizes and emits channel/programme events. Cancellation will stop the
/// input subscription and terminate the isolate.
Stream<XtXmltvEvent> parseXmltv(Stream<List<int>> input) {
  final controller = StreamController<XtXmltvEvent>(sync: false);
  Isolate? iso;
  StreamSubscription<List<int>>? sub;
  ReceivePort? events;
  ReceivePort? isoReady;
  SendPort? sinkPort;

  void disposeIso() {
    try {
      iso?.kill(priority: Isolate.immediate);
    } catch (_) {}
    iso = null;
    events?.close();
    isoReady?.close();
  }

  Future<void> start() async {
    events = ReceivePort();
    isoReady = ReceivePort();
    iso = await Isolate.spawn<_IsoInit>(
      _xmltvIsolateMain,
      _IsoInit(events!.sendPort, isoReady!.sendPort),
      debugName: 'xmltv-parser',
    );
    // Wait for sink port from isolate
    sinkPort = await isoReady!.first as SendPort;
    // Forward events from isolate to controller
    sub = input.listen(
      (chunk) => sinkPort!.send(_IsoMsg.data(chunk)),
      onError: (err, st) => sinkPort!.send(_IsoMsg.error(err, st)),
      onDone: () => sinkPort!.send(const _IsoMsg.eof()),
      cancelOnError: true,
    );
    events!.listen((message) {
      if (message is _IsoEvent) {
        final e = message.toEvent();
        if (e != null && !controller.isClosed) controller.add(e);
      } else if (message is _IsoExit) {
        controller.close();
        disposeIso();
      }
    });
  }

  controller.onListen = start;
  controller.onPause = () => sub?.pause();
  controller.onResume = () => sub?.resume();
  controller.onCancel = () async {
    try {
      sinkPort?.send(const _IsoMsg.cancel());
    } catch (_) {}
    await sub?.cancel();
    disposeIso();
  };

  return controller.stream;
}

// ==== Isolate wiring ====

class _IsoInit {
  final SendPort eventsPort;
  final SendPort readyPort;
  const _IsoInit(this.eventsPort, this.readyPort);
}

class _IsoExit {
  const _IsoExit();
}

class _IsoEvent {
  final String kind;
  final Map<String, dynamic> payload;
  const _IsoEvent(this.kind, this.payload);

  XtXmltvEvent? toEvent() {
    switch (kind) {
      case 'channel':
        return XtXmltvChannel(
          id: payload['id'] as String,
          displayName: payload['displayName'] as String?,
          iconUrl: payload['iconUrl'] as String?,
        );
      case 'programme':
        return XtXmltvProgramme(
          channelId: payload['channelId'] as String,
          start: DateTime.parse(payload['start'] as String),
          stop: (payload['stop'] as String?) != null
              ? DateTime.parse(payload['stop'] as String)
              : null,
          title: payload['title'] as String?,
          description: payload['description'] as String?,
          categories:
              (payload['categories'] as List<dynamic>?)
                  ?.whereType<String>()
                  .toList(growable: false) ??
              const [],
        );
    }
    return null;
  }
}

class _IsoMsg {
  final String kind; // data | eof | cancel | error
  final List<int>? bytes;
  final String? error;
  final String? stack;
  const _IsoMsg._(this.kind, {this.bytes, this.error, this.stack});
  const _IsoMsg.eof() : this._('eof');
  const _IsoMsg.cancel() : this._('cancel');
  factory _IsoMsg.data(List<int> b) => _IsoMsg._('data', bytes: b);
  factory _IsoMsg.error(Object err, StackTrace st) =>
      _IsoMsg._('error', error: '$err', stack: '$st');
}

void _xmltvIsolateMain(_IsoInit init) {
  final controller = _XmlSaxEmitter(init.eventsPort);
  final recv = ReceivePort();
  init.readyPort.send(recv.sendPort);
  bool cancelled = false;
  recv.listen((message) {
    if (cancelled) return;
    if (message is _IsoMsg) {
      if (message.kind == 'data' && message.bytes != null) {
        controller.addBytes(message.bytes!);
      } else if (message.kind == 'eof') {
        controller.close();
      } else if (message.kind == 'error') {
        controller.addError(message.error ?? 'input error', message.stack);
      } else if (message.kind == 'cancel') {
        cancelled = true;
        controller.dispose();
      }
    }
  });
}

// ==== Minimal SAX-like tokenizer and state machine for XMLTV ====

class _XmlSaxEmitter {
  final SendPort out;
  final Utf8Decoder _utf8 = const Utf8Decoder();
  final StringBuffer _buf = StringBuffer();
  bool _closed = false;

  _XmlSaxEmitter(this.out);

  void addBytes(List<int> chunk) {
    if (_closed) return;
    _buf.write(_utf8.convert(chunk));
    _drain();
  }

  void addError(String error, String? stack) {
    if (_closed) return;
    // On input error, just terminate.
    out.send(const _IsoExit());
    _closed = true;
  }

  void close() {
    if (_closed) return;
    // Mark closed and drain remaining buffer.
    _closed = true;
    _finalize();
  }

  void dispose() {
    _closed = true;
  }

  // Parser state
  final List<String> _stack = [];
  Map<String, String> _currentAttrs = {};
  // Channel/programme accumulators
  String? _chId;
  String? _chName;
  String? _chIcon;

  String? _prChannel;
  DateTime? _prStart;
  DateTime? _prStop;
  String? _prTitle;
  String? _prDesc;
  final List<String> _prCats = [];
  StringBuffer? _text;

  void _drain() {
    // Process as many complete tags as possible.
    while (true) {
      final s = _buf.toString();
      final lt = s.indexOf('<');
      if (lt < 0) return; // wait for next chunk
      if (lt > 0) {
        // Text between tags
        _appendText(s.substring(0, lt));
        _buf.clear();
        _buf.write(s.substring(lt));
      }
      final s2 = _buf.toString();
      final gt = s2.indexOf('>');
      if (gt < 0) return; // incomplete tag
      final tag = s2.substring(1, gt).trim();
      final rest = s2.substring(gt + 1);
      _buf.clear();
      _buf.write(rest);
      _handleTag(tag);
    }
  }

  void _finalize() {
    // Drain remaining buffered text
    _drain();
    // Emit exit to close the stream on the main isolate.
    out.send(const _IsoExit());
  }

  void _appendText(String t) {
    if (t.isEmpty) return;
    _text ??= StringBuffer();
    _text!.write(t);
  }

  void _handleTag(String raw) {
    if (raw.startsWith('?') || raw.startsWith('!')) {
      // XML declaration or comment/doctype, ignore
      return;
    }
    if (raw.startsWith('/')) {
      final name = raw.substring(1).trim();
      _onCloseTag(name);
      return;
    }
    final selfClosing = raw.endsWith('/');
    final content = selfClosing ? raw.substring(0, raw.length - 1).trim() : raw;
    final parts = _splitNameAttrs(content);
    final name = parts.$1;
    final attrs = parts.$2;
    _onOpenTag(name, attrs, selfClosing);
  }

  (String, Map<String, String>) _splitNameAttrs(String s) {
    // Parse element name and simple key="value" pairs.
    final sp = s.indexOf(RegExp(r'\s'));
    String name;
    String rest;
    if (sp < 0) {
      name = s;
      rest = '';
    } else {
      name = s.substring(0, sp);
      rest = s.substring(sp + 1);
    }
    final attrs = <String, String>{};
    final re = RegExp(r'(\w[\w:-]*)\s*=\s*"([^"]*)"');
    for (final m in re.allMatches(rest)) {
      attrs[m.group(1)!] = m.group(2)!;
    }
    return (name, attrs);
  }

  void _onOpenTag(String name, Map<String, String> attrs, bool selfClosing) {
    _flushText();
    _stack.add(name);
    _currentAttrs = attrs;
    if (name == 'channel') {
      _chId = attrs['id'];
      _chName = null;
      _chIcon = null;
    } else if (name == 'programme') {
      _prChannel = attrs['channel'];
      _prStart = _parseXmltvDate(attrs['start']);
      _prStop = _parseXmltvDate(attrs['stop']);
      _prTitle = null;
      _prDesc = null;
      _prCats.clear();
    }
    if (selfClosing) {
      _onCloseTag(name);
    }
  }

  void _onCloseTag(String name) {
    _flushText();
    // Pop stack until name found to be tolerant
    while (_stack.isNotEmpty) {
      final top = _stack.removeLast();
      if (top == name) break;
    }

    if (name == 'display-name' && _stack.contains('channel')) {
      _chName = _lastText;
    } else if (name == 'icon' && _stack.contains('channel')) {
      _chIcon = _currentAttrs['src'];
    } else if (name == 'channel') {
      if (_chId != null) {
        out.send(
          _IsoEvent('channel', {
            'id': _chId!,
            'displayName': _chName,
            'iconUrl': _chIcon,
          }),
        );
      }
      _chId = null;
      _chName = null;
      _chIcon = null;
    } else if (name == 'title' && _stack.contains('programme')) {
      _prTitle = _lastText;
    } else if (name == 'desc' && _stack.contains('programme')) {
      _prDesc = _lastText;
    } else if (name == 'category' && _stack.contains('programme')) {
      final t = _lastText;
      if (t != null && t.trim().isNotEmpty) _prCats.add(t.trim());
    } else if (name == 'programme') {
      if (_prChannel != null && _prStart != null) {
        out.send(
          _IsoEvent('programme', {
            'channelId': _prChannel!,
            'start': _prStart!.toIso8601String(),
            'stop': _prStop?.toIso8601String(),
            'title': _prTitle,
            'description': _prDesc,
            'categories': List<String>.from(_prCats),
          }),
        );
      }
      _prChannel = null;
      _prStart = null;
      _prStop = null;
      _prTitle = null;
      _prDesc = null;
      _prCats.clear();
    }
    _currentAttrs = {};
  }

  String? _lastText;
  void _flushText() {
    if (_text != null) {
      _lastText = _unescape(_text!.toString());
      _text = null;
    } else {
      _lastText = null;
    }
  }

  // Minimal XML entity unescape
  String _unescape(String s) => s
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&apos;', "'");
}

DateTime? _parseXmltvDate(String? s) {
  if (s == null || s.isEmpty) return null;
  // Examples: 20240101T120000Z, 20240101120000 +0000, 20240101120000 +0200
  try {
    // Normalize common shapes
    final re = RegExp(
      r'^(\d{4})(\d{2})(\d{2})(?:T|\s?)(\d{2})(\d{2})(\d{2})(?:\s*([Zz]|[+\-]\d{4}))?',
    );
    final m = re.firstMatch(s);
    if (m == null) return null;
    final y = int.parse(m.group(1)!);
    final mo = int.parse(m.group(2)!);
    final d = int.parse(m.group(3)!);
    final h = int.parse(m.group(4)!);
    final mi = int.parse(m.group(5)!);
    final se = int.parse(m.group(6)!);
    final tz = m.group(7);
    var dt = DateTime.utc(y, mo, d, h, mi, se);
    if (tz != null && tz.toUpperCase() != 'Z') {
      final sign = tz.startsWith('-') ? -1 : 1;
      final offH = int.parse(tz.substring(1, 3));
      final offM = int.parse(tz.substring(3, 5));
      dt = dt.subtract(Duration(hours: sign * offH, minutes: sign * offM));
    }
    return dt;
  } catch (_) {
    return null;
  }
}
