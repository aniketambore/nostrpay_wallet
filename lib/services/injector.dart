import 'keychain.dart';

class ServiceInjector {
  static final _singleton = ServiceInjector._internal();
  static ServiceInjector? _injector;

  KeyChain? _keychain;

  factory ServiceInjector() {
    return _injector ?? _singleton;
  }

  ServiceInjector._internal();

  KeyChain get keychain {
    return _keychain ??= KeyChain();
  }
}
