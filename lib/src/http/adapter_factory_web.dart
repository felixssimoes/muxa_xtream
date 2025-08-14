// Only compiled on web via conditional import.
import '../core/errors.dart';
import 'adapter.dart';
import 'default_adapter.dart';

class XtUnsupportedWebAdapter implements XtHttpAdapter {
  const XtUnsupportedWebAdapter();

  @override
  Future<XtResponse> get(XtRequest request) => _unsupported();

  @override
  Future<XtResponse> head(XtRequest request) => _unsupported();

  Future<XtResponse> _unsupported() async {
    throw const XtUnsupportedError(
      'No default web HTTP adapter. Please inject a custom web adapter.',
    );
  }
}

XtHttpAdapter createDefaultHttpAdapterImpl({XtDefaultHttpOptions? options}) {
  return const XtUnsupportedWebAdapter();
}
