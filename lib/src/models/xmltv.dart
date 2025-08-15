/// Base type for XMLTV events.
sealed class XtXmltvEvent {}

/// Channel metadata from the `channel` element.
class XtXmltvChannel implements XtXmltvEvent {
  final String id;
  final String? displayName;
  final String? iconUrl;

  const XtXmltvChannel({required this.id, this.displayName, this.iconUrl});
}

/// Programme entry from the `programme` element.
class XtXmltvProgramme implements XtXmltvEvent {
  final String channelId;
  final DateTime start;
  final DateTime? stop;
  final String? title;
  final String? description;
  final List<String> categories;

  const XtXmltvProgramme({
    required this.channelId,
    required this.start,
    this.stop,
    this.title,
    this.description,
    this.categories = const [],
  });
}
