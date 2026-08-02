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

  Future<void> sendOtp(String phoneE164) async {
    if (_auth == null) return;
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

  String _friendly(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-verification-code':
        return 'Galat OTP — dobara try karo';
      case 'invalid-phone-number':
        return 'Phone number sahi nahi hai';
      case 'too-many-requests':
        return 'Bahut zyada attempts — thodi der baad try karo';
      case 'session-expired':
        return 'OTP expire ho gaya — dobara bhejo';
      default:
        return e.message ?? 'Verification failed';
    }
  }
}
