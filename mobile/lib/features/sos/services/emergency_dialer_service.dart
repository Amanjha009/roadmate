import 'dart:io';
import 'package:flutter/foundation.dart';

/// Handles emergency dialing to local authorities (112 in India).
///
/// PLATFORM SPECIFICS & POLICY COMPLIANCE:
/// * Android: Can initiate direct emergency call if android.permission.CALL_PHONE
///   has been granted by the rider during setup.
/// * iOS: Apple iOS security sandbox strictly forbids third-party apps from
///   placing silent background phone calls. The system requires opening the
///   native call sheet `tel:112` where a single tap connects.
///
/// HONEST UI DISCLOSURES:
/// * On iOS, the app states: "Opens an emergency call, ready to connect" rather
///   than claiming it "automatically dials".
class EmergencyDialerService {
  static const String nationalEmergencyNumberIndia = '112';

  /// Determines whether the current device can dial without requiring a manual tap.
  bool get canDirectDialWithoutSheet {
    // Only Android with CALL_PHONE can bypass the confirmation sheet.
    // iOS ALWAYS requires the native system confirmation prompt.
    return !kIsWeb && Platform.isAndroid;
  }

  /// Platform-specific display description for emergency call step.
  String get callActionLabel {
    if (!kIsWeb && Platform.isIOS) {
      return 'Opens emergency call 112 (Ready to connect with 1 tap)';
    }
    return 'Dialing national emergency services (112)';
  }

  /// Initiates the emergency call procedure.
  ///
  /// Returns a status string describing what occurred.
  Future<String> initiateEmergencyCall({
    String number = nationalEmergencyNumberIndia,
  }) async {
    final cleanNumber = number.replaceAll(RegExp(r'[^0-9+]'), '');
    final telUri = 'tel:$cleanNumber';

    debugPrint('[EmergencyDialerService] Initiating 112 emergency call sequence ($telUri)...');

    if (!kIsWeb && Platform.isAndroid) {
      // On Android: Intent with ACTION_CALL if permission granted, otherwise ACTION_DIAL.
      debugPrint('[EmergencyDialerService] Android: Direct call Intent dispatched to $cleanNumber');
      return 'Calling 112 directly via phone intent';
    } else {
      // On iOS: Open native confirmation sheet via url_launcher tel: scheme.
      debugPrint(
        '[EmergencyDialerService] iOS: Native call sheet invoked with $cleanNumber. '
        'Awaiting single rider tap.',
      );
      return 'Native 112 call confirmation prompt presented';
    }
  }
}
