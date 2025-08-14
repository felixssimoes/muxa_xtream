import 'adapter.dart';
import '../core/errors.dart';
import 'default_adapter.dart';

XtHttpAdapter createDefaultHttpAdapterImpl({XtDefaultHttpOptions? options}) {
  throw const XtUnsupportedError('No default HTTP adapter for this platform');
}
