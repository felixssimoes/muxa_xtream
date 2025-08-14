import 'adapter.dart';
import 'adapter_factory_stub.dart'
    if (dart.library.html) 'adapter_factory_web.dart'
    if (dart.library.io) 'adapter_factory_io.dart';

import 'default_adapter.dart';

/// Create a platform-appropriate default HTTP adapter.
/// - VM/IO: returns [XtDefaultHttpAdapter]
/// - Web: returns a browser-compatible adapter
XtHttpAdapter createDefaultHttpAdapter({XtDefaultHttpOptions? options}) =>
    createDefaultHttpAdapterImpl(options: options);
