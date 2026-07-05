import 'package:local_auth/local_auth.dart';
import 'package:flutter/services.dart';

class BiometricService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> canCheckBiometrics() async {
    try {
      return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> authenticate() async {
    final bool canCheck = await canCheckBiometrics();
    if (!canCheck) return false;

    try {
      return await _auth.authenticate(
        localizedReason: 'Please authenticate to access Momentum',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: true,
        ),
      );
    } on PlatformException catch (e) {
      print('Error during authentication: $e');
      return false;
    }
  }
}
