import 'adapter.dart';
import 'default_adapter.dart';

XtHttpAdapter createDefaultHttpAdapterImpl({XtDefaultHttpOptions? options}) {
  return XtDefaultHttpAdapter(options: options);
}
