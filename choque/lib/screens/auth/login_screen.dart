import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../ui/design_system.dart';

/// Login Screen - đăng nhập với nhiều options
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      // Wait for profile to load
      // ignore: unused_result
      await ref.refresh(userProfileProvider.future);

      if (mounted) {
        _navigateAfterLogin();
      }
    } catch (e) {
      String message = 'Đăng nhập thất bại. Vui lòng thử lại.';
      if (e.toString().contains('Invalid login credentials')) {
        message = 'Email hoặc mật khẩu không chính xác.';
      } else if (e.toString().contains('network')) {
        message = 'Lỗi kết nối mạng. Vui lòng kiểm tra lại wifi/4G.';
      }

      setState(() {
        _errorMessage = message;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleGuestLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authNotifier = ref.read(authNotifierProvider.notifier);
      await authNotifier.continueAsGuest();

      if (mounted) {
        context.go('/');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Không thể tiếp tục. Vui lòng thử lại.';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _navigateAfterLogin() async {
    // Wait for a tiny bit to ensure providers are updated after profile refresh
    await Future.delayed(const Duration(milliseconds: 100));

    final roles = ref.read(availableRolesProvider);
    final needsRoleSelection = roles.length > 1;

    // Check if there's a redirect parameter
    final router = GoRouter.of(context);
    final location = router.routerDelegate.currentConfiguration.uri.toString();
    final uri = Uri.parse(location);
    final redirectTo = uri.queryParameters['redirect'];

    if (redirectTo != null && redirectTo.isNotEmpty) {
      context.go(redirectTo);
      return;
    }

    if (needsRoleSelection) {
      context.go('/role-switcher');
    } else if (roles.isNotEmpty) {
      final role = roles.first;
      ref.read(activeRoleProvider.notifier).setRole(role);
      context.go(role.route);
    } else {
      // Fallback to home if no roles found (should not happen with default)
      context.go('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 60),
                _buildHeader(),
                const SizedBox(height: 48),
                _buildEmailField(),
                const SizedBox(height: 16),
                _buildPasswordField(),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorMessage(),
                ],
                const SizedBox(height: 12),
                _buildForgotPasswordLink(),
                const SizedBox(height: 24),
                _buildLoginButton(),
                const SizedBox(height: 16),
                _buildGuestButton(),
                const SizedBox(height: 32),
                _buildDivider(),
                const SizedBox(height: 24),
                _buildRegisterLink(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Image.asset(
          'assets/images/logo.png',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 24),
        Text(
          'Chợ Quê',
          style: GoogleFonts.inter(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Đăng nhập để tiếp tục',
          style: GoogleFonts.inter(fontSize: 15, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildEmailField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Email',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.email_outlined),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập email';
            }
            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
            if (!emailRegex.hasMatch(value)) {
              return 'Email không hợp lệ';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildPasswordField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mật khẩu',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          autofillHints: const [AutofillHints.password],
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.lock_outlined),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Vui lòng nhập mật khẩu';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red[700], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red[700], fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordLink() {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: () => context.push('/forgot-password'),
        child: Text(
          'Quên mật khẩu?',
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _isLoading ? null : _handleLogin,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Text(
              'Đăng nhập',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  Widget _buildGuestButton() {
    return OutlinedButton(
      onPressed: _isLoading ? null : _handleGuestLogin,
      style: OutlinedButton.styleFrom(
        foregroundColor: Colors.grey[700],
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: Colors.grey[300]!),
      ),
      child: Text(
        'Tiếp tục với tư cách Khách',
        style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'hoặc',
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Chưa có tài khoản? ',
          style: TextStyle(color: Colors.grey[600], fontSize: 14),
        ),
        GestureDetector(
          onTap: () => context.push('/register'),
          child: Text(
            'Đăng ký ngay',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ],
    );
  }
}
