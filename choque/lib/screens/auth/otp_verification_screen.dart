import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../providers/auth_provider.dart';

/// OTP Verification Screen
/// User enters 6-digit OTP code sent to their email
/// Supports types: 'signup', 'email', 'recovery'
class OtpVerificationScreen extends ConsumerStatefulWidget {
  final String email;
  final String? fullName;
  final String type; // 'signup', 'email', 'recovery'

  const OtpVerificationScreen({
    super.key,
    required this.email,
    this.fullName,
    this.type = 'email',
  });

  @override
  ConsumerState<OtpVerificationScreen> createState() =>
      _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends ConsumerState<OtpVerificationScreen> {
  static const int _otpLength = 6;

  final List<TextEditingController> _controllers = List.generate(
    _otpLength,
    (_) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(
    _otpLength,
    (_) => FocusNode(),
  );
  bool _isLoading = false;
  int _resendCountdown = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _startCountdown() {
    _resendCountdown = 60;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
      }
    });
  }

  String get _otpCode {
    return _controllers.map((c) => c.text).join();
  }

  Future<void> _verifyOtp() async {
    final code = _otpCode;
    if (code.length != _otpLength) return;

    setState(() => _isLoading = true);

    try {
      // Determine OTP type based on widget.type
      OtpType otpType;
      switch (widget.type) {
        case 'signup':
          otpType = OtpType.signup;
          break;
        case 'recovery':
          otpType = OtpType.recovery;
          break;
        default:
          otpType = OtpType.email;
      }

      final response = await ref
          .read(authNotifierProvider.notifier)
          .verifyOtp(email: widget.email, token: code, type: otpType);

      if (mounted && response.user != null) {
        // Handle based on type
        if (widget.type == 'recovery') {
          // Recovery flow - go to reset password screen
          context.go('/reset-password', extra: {'email': widget.email});
          return;
        }

        // Signup/email flow - check profile and navigate
        // Essential: wait for provider refresh
        final profile = await ref.refresh(userProfileProvider.future);

        if (!mounted) return;

        if (profile == null) {
          // New user - go to profile setup
          context.go(
            '/register/profile',
            extra: {'full_name': widget.fullName},
          );
        } else {
          // Existing user - go to home
          context.go('/');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Mã xác thực không đúng hoặc đã hết hạn'),
            backgroundColor: Colors.red,
          ),
        );
        // Clear all fields
        for (var controller in _controllers) {
          controller.clear();
        }
        _focusNodes[0].requestFocus();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) return;

    setState(() => _isLoading = true);

    try {
      // Use appropriate method based on type
      if (widget.type == 'recovery') {
        await ref
            .read(authNotifierProvider.notifier)
            .sendRecoveryOtp(email: widget.email);
      } else {
        await ref
            .read(authNotifierProvider.notifier)
            .signInWithOtp(email: widget.email);
      }
      _startCountdown();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã gửi lại mã xác thực mới'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể gửi lại mã: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onOtpDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < _otpLength - 1) {
      _focusNodes[index + 1].requestFocus();
    }

    // Auto-verify when all digits entered
    if (_otpCode.length == _otpLength) {
      _verifyOtp();
    }
  }

  void _handleBackspace(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.type == 'recovery' ? 'Đặt lại mật khẩu' : 'Xác thực email',
          style: const TextStyle(color: Colors.black87),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              // Icon
              Center(
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E7F43).withAlpha(26),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 35,
                    color: Color(0xFF1E7F43),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Instructions
              const Text(
                'Nhập mã xác thực',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Mã $_otpLength số đã được gửi đến\n${widget.email}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              // OTP Input fields - 6 boxes
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(_otpLength, (index) {
                  return SizedBox(
                    width: 38,
                    height: 48,
                    child: KeyboardListener(
                      focusNode: FocusNode(),
                      onKeyEvent: (event) => _handleBackspace(index, event),
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 1,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: InputDecoration(
                          counterText: '',
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(
                              color: Color(0xFF1E7F43),
                              width: 2,
                            ),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        onChanged: (value) => _onOtpDigitChanged(index, value),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              // Resend button
              TextButton(
                onPressed: _resendCountdown == 0 ? _resendOtp : null,
                child: Text(
                  _resendCountdown > 0
                      ? 'Gửi lại mã (${_resendCountdown}s)'
                      : 'Gửi lại mã',
                  style: TextStyle(
                    color: _resendCountdown > 0
                        ? Colors.grey[400]
                        : const Color(0xFF1E7F43),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Verify button
              ElevatedButton(
                onPressed: _isLoading ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E7F43),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        'XÁC THỰC',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
