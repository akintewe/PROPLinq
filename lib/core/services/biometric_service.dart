import 'package:local_auth/local_auth.dart';
import 'package:local_auth_android/local_auth_android.dart';
import 'package:local_auth_darwin/local_auth_darwin.dart';

class BiometricService {
  static final BiometricService _instance = BiometricService._internal();
  factory BiometricService() => _instance;
  BiometricService._internal();

  final LocalAuthentication _localAuth = LocalAuthentication();

  // Check if biometric authentication is available
  Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      return false;
    }
  }

  // Get available biometric types
  Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      return [];
    }
  }

  // Authenticate using biometric
  Future<bool> authenticate({
    required String reason,
    String? cancelButton,
    String? goToSettingsButton,
    String? goToSettingsDescription,
  }) async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) {
        return false;
      }

      final bool didAuthenticate = await _localAuth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
          sensitiveTransaction: true,
        ),
        authMessages: [
          AndroidAuthMessages(
            cancelButton: cancelButton ?? 'Cancel',
            goToSettingsButton: goToSettingsButton ?? 'Settings',
            goToSettingsDescription: goToSettingsDescription ?? 
                'Please enable biometric authentication in your device settings.',
            deviceCredentialsRequiredTitle: 'Device Credentials Required',
            signInTitle: 'Biometric Authentication',
          ),
          IOSAuthMessages(
            cancelButton: cancelButton ?? 'Cancel',
            goToSettingsButton: goToSettingsButton ?? 'Settings',
            goToSettingsDescription: goToSettingsDescription ?? 
                'Please enable biometric authentication in your device settings.',
            lockOut: 'Biometric authentication is locked out. Please use your device passcode.',
          ),
        ],
      );

      if (didAuthenticate) {
      } else {
      }

      return didAuthenticate;
    } catch (e) {
      return false;
    }
  }

  // Check if biometric is enrolled
  Future<bool> isBiometricEnrolled() async {
    try {
      final bool isAvailable = await isBiometricAvailable();
      if (!isAvailable) return false;

      final List<BiometricType> availableBiometrics = await getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  // Get biometric type display name
  String getBiometricTypeDisplayName(List<BiometricType> biometricTypes) {
    if (biometricTypes.contains(BiometricType.face)) {
      return 'Face ID';
    } else if (biometricTypes.contains(BiometricType.fingerprint)) {
      return 'Fingerprint';
    } else if (biometricTypes.contains(BiometricType.iris)) {
      return 'Iris';
    } else {
      return 'Biometric';
    }
  }
}
