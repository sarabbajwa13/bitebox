import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

enum AuthStep { enterPhone, otpSent }

/// Firebase Phone OTP authentication (client). Web pe reCAPTCHA se hota hai.
class AuthProvider extends ChangeNotifier {
  FirebaseAuth? _auth;

  AuthStep step = AuthStep.enterPhone;
  String phone = '';
  bool busy = false;
  String? error;

  String? _verificationId;
  int? _resendToken;

  /// Resend/Send cooldown — OTP billing abuse rokta hai. Jab tak > 0 hai,
  /// koi naya OTP send nahi ho sakta (Resend + wapas jaa ke Send dono blocked).
  static const int cooldownDuration = 60;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  int get resendSeconds => _cooldownSeconds;
  bool get canSendOtp => _cooldownSeconds == 0 && !busy;

  AuthProvider() {
    try {
      _auth = FirebaseAuth.instance;
      _auth!.authStateChanges().listen((_) => notifyListeners());
    } catch (_) {
      _auth = null;
    }
  }

  bool get isLoggedIn => _auth?.currentUser != null;
  String? get uid => _auth?.currentUser?.uid;
  String? get userPhone => _auth?.currentUser?.phoneNumber;

  void _startCooldown() {
    _cooldownTimer?.cancel();
    _cooldownSeconds = cooldownDuration;
    notifyListeners();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      _cooldownSeconds--;
      if (_cooldownSeconds <= 0) {
        _cooldownSeconds = 0;
        t.cancel();
      }
      notifyListeners();
    });
  }

  Future<void> sendOtp(String phoneE164) async {
    if (_auth == null) return;
    // Cooldown active → naya OTP send mat karo (billing protection).
    if (_cooldownSeconds > 0) return;
    busy = true;
    error = null;
    phone = phoneE164;
    notifyListeners();

    await _auth!.verifyPhoneNumber(
      phoneNumber: phoneE164,
      timeout: const Duration(seconds: 60),
      forceResendingToken: _resendToken,
      verificationCompleted: (PhoneAuthCredential credential) async {
        try {
          await _auth!.signInWithCredential(credential);
        } catch (_) {}
        busy = false;
        notifyListeners();
      },
      verificationFailed: (FirebaseAuthException e) {
        busy = false;
        error = _friendly(e);
        notifyListeners();
      },
      codeSent: (String verificationId, int? resendToken) {
        _verificationId = verificationId;
        _resendToken = resendToken;
        step = AuthStep.otpSent;
        busy = false;
        // OTP actually gaya (billing) → resend cooldown shuru.
        _startCooldown();
        notifyListeners();
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        _verificationId = verificationId;
      },
    );
  }

  Future<void> verifyOtp(String smsCode) async {
    if (_auth == null || _verificationId == null) return;
    busy = true;
    error = null;
    notifyListeners();
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await _auth!.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      error = _friendly(e);
    } catch (e) {
      error = e.toString();
    }
    busy = false;
    notifyListeners();
  }

  void backToPhone() {
    step = AuthStep.enterPhone;
    error = null;
    _verificationId = null;
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth?.signOut();
    step = AuthStep.enterPhone;
    _verificationId = null;
    error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-verification-code':
        return 'Incorrect OTP — please try again';
      case 'invalid-phone-number':
        return 'That phone number is not valid';
      case 'too-many-requests':
        return 'Too many attempts — please try again later';
      case 'session-expired':
        return 'The OTP has expired — please resend';
      default:
        return e.message ?? 'Verification failed';
    }
  }
}
