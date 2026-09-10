import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../config/app_config.dart';
import '../../config/app_strings.dart';
import '../../config/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../widgets/common.dart';

/// Firebase Phone OTP login. Login hote hi `Navigator.pop(true)` — cart flow
/// isi ka intezaar karta hai.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _phoneCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  bool _popped = false;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    _otpCtrl.dispose();
    super.dispose();
  }

  void _sendOtp() {
    final d = _phoneCtrl.text.trim();
    if (d.length != AppConfig.phoneLength) return;
    context.read<AuthProvider>().sendOtp('${AppConfig.countryCode}$d');
  }

  void _verify() {
    final c = _otpCtrl.text.trim();
    if (c.length != AppConfig.otpLength) return;
    context.read<AuthProvider>().verifyOtp(c);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    // Login success → wapas cart pe (true ke saath).
    if (auth.isLoggedIn && !_popped) {
      _popped = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(true);
      });
    }

    final isOtp = auth.step == AuthStep.otpSent;
    // Button tabhi enable: phone step me 10 digits, OTP step me 6 digits.
    final canSubmit = isOtp
        ? _otpCtrl.text.trim().length == AppConfig.otpLength
        : _phoneCtrl.text.trim().length == AppConfig.phoneLength;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: const BackButton(),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(child: AppLogo(size: 76, radius: AppRadius.lg)),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  AppStrings.loginTitle,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  isOtp
                      ? '${AppStrings.otpSentTo} ${auth.phone}'
                      : AppStrings.loginSubtitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.xl),

                if (!isOtp)
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(AppConfig.phoneLength),
                    ],
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _sendOtp(),
                    decoration: const InputDecoration(
                      labelText: AppStrings.phoneNumber,
                      prefixIcon: Icon(Icons.phone_outlined),
                      prefixText: '${AppConfig.countryCode} ',
                    ),
                  )
                else
                  TextField(
                    controller: _otpCtrl,
                    keyboardType: TextInputType.number,
                    autofocus: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(AppConfig.otpLength),
                    ],
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 8,
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) => _verify(),
                    decoration: const InputDecoration(
                      labelText: AppStrings.otpLabel,
                    ),
                  ),

                if (auth.error != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    auth.error!,
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],

                // Phone step pe cooldown active → note dikhao.
                if (!isOtp && auth.resendSeconds > 0) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    '${AppStrings.otpCooldownNote} ${auth.resendSeconds}s',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.lg),
                ElevatedButton(
                  onPressed: (auth.busy || !canSubmit)
                      ? null
                      : isOtp
                          ? _verify
                          : (auth.canSendOtp ? _sendOtp : null),
                  child: auth.busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(isOtp
                          ? AppStrings.verifyLogin
                          : AppStrings.sendOtp),
                ),

                if (isOtp) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: auth.busy
                            ? null
                            : () {
                                _otpCtrl.clear();
                                context.read<AuthProvider>().backToPhone();
                              },
                        child: const Text(AppStrings.changeNumber),
                      ),
                      TextButton(
                        onPressed: (auth.busy || auth.resendSeconds > 0)
                            ? null
                            : () => context
                                .read<AuthProvider>()
                                .sendOtp(auth.phone),
                        child: Text(auth.resendSeconds > 0
                            ? '${AppStrings.resendOtpIn} ${auth.resendSeconds}s'
                            : AppStrings.resendOtp),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
