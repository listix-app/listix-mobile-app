import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';

abstract interface class AppLockService {
  Future<bool> isDeviceSupported();
  Future<bool> canCheckBiometrics();
  Future<bool> authenticate({required String localizedReason});
}

class LocalAuthAppLockService implements AppLockService {
  final LocalAuthentication _auth;

  LocalAuthAppLockService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  @override
  Future<bool> isDeviceSupported() => _auth.isDeviceSupported();

  @override
  Future<bool> canCheckBiometrics() => _auth.canCheckBiometrics;

  @override
  Future<bool> authenticate({required String localizedReason}) async {
    try {
      return await _auth.authenticate(
        localizedReason: localizedReason,
        persistAcrossBackgrounding: true,
        biometricOnly: false,
      );
    } catch (_) {
      return false;
    }
  }
}

final appLockServiceProvider = Provider<AppLockService>((ref) {
  return LocalAuthAppLockService();
});
