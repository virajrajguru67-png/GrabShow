import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../controllers/auth_controller.dart';
import '../design_system/design_system.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import '../widgets/auth/auth_text_field.dart';
import '../widgets/auth/social_auth_button.dart';
import 'forgot_password_screen.dart';
import 'navigation_shell.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  static const route = '/auth';

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _signInFormKey = GlobalKey<FormState>();
  final _signUpFormKey = GlobalKey<FormState>();
  
  // Sign In controllers
  final _signInEmailController = TextEditingController();
  final _signInPasswordController = TextEditingController();
  
  // Sign Up controllers
  final _signUpNameController = TextEditingController();
  final _signUpEmailController = TextEditingController();
  final _signUpPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _signInEmailController.dispose();
    _signInPasswordController.dispose();
    _signUpNameController.dispose();
    _signUpEmailController.dispose();
    _signUpPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_signInFormKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    await auth.signInWithEmail(
      _signInEmailController.text.trim(),
      _signInPasswordController.text,
    );
    if (!mounted) return;
    _handleAuthResult(auth);
  }

  Future<void> _handleSignUp() async {
    if (!_signUpFormKey.currentState!.validate()) return;
    final auth = context.read<AuthController>();
    await auth.signUpWithEmail(
      email: _signUpEmailController.text.trim(),
      password: _signUpPasswordController.text,
      displayName: _signUpNameController.text.trim(),
    );
    if (!mounted) return;
    _handleAuthResult(auth, isSignUp: true);
  }

  Future<void> _handleGoogle() async {
    final auth = context.read<AuthController>();
    await auth.signInWithGoogle();
    if (!mounted) return;
    _handleAuthResult(auth);
  }

  Future<void> _handleFacebook() async {
    // Facebook sign in implementation
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Facebook sign in coming soon')),
    );
  }

  Future<void> _handleApple() async {
    final auth = context.read<AuthController>();
    await auth.signInWithApple();
    if (!mounted) return;
    _handleAuthResult(auth);
  }

  void _handleAuthResult(AuthController controller, {bool isSignUp = false}) {
    if (controller.status == AuthStatus.authenticated) {
      if (isSignUp) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registered successfully')),
        );
      }
      Navigator.of(context).pushNamedAndRemoveUntil(
        NavigationShell.route,
        (route) => route.isFirst,
      );
    } else if (controller.status == AuthStatus.error &&
        controller.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(controller.errorMessage!)),
      );
      controller.clearError();
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final isValid = RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value);
    if (!isValid) return 'Enter a valid email';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 6) return 'Password must be at least 6 characters';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final isLoading = auth.status == AuthStatus.authenticating;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // GrabShow with icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.local_movies_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'GrabShow',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 32,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 40),
              // Card container with tabs
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: AppColors.surfaceHighlight),
                  boxShadow: const [DSShadows.md],
                ),
                child: Column(
                  children: [
                    // Tab bar with toggle pattern
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: AnimatedBuilder(
                          animation: _tabController,
                          builder: (context, child) {
                            return Row(
                              children: [
                                Expanded(
                                  child: _ToggleTab(
                                    label: 'Sign In',
                                    icon: Icons.login_rounded,
                                    isSelected: _tabController.index == 0,
                                    onTap: () {
                                      _tabController.animateTo(0);
                                    },
                                  ),
                                ),
                                Expanded(
                                  child: _ToggleTab(
                                    label: 'Sign Up',
                                    icon: Icons.person_add_rounded,
                                    isSelected: _tabController.index == 1,
                                    onTap: () {
                                      _tabController.animateTo(1);
                                    },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                    // Tab views
                    AnimatedBuilder(
                      animation: _tabController,
                      builder: (context, child) {
                        // Sign-in is shorter, sign-up is taller
                        final height = _tabController.index == 0 ? 480 : 600;
                        return SizedBox(
                          height: height.toDouble(),
                          child: TabBarView(
                            controller: _tabController,
                            children: [
                          _SignInTab(
                            formKey: _signInFormKey,
                            emailController: _signInEmailController,
                            passwordController: _signInPasswordController,
                            isLoading: isLoading,
                            onSignIn: _handleSignIn,
                            onGoogle: _handleGoogle,
                            onFacebook: _handleFacebook,
                            onApple: _handleApple,
                            validateEmail: _validateEmail,
                            validatePassword: _validatePassword,
                          ),
                          _SignUpTab(
                            formKey: _signUpFormKey,
                            nameController: _signUpNameController,
                            emailController: _signUpEmailController,
                            passwordController: _signUpPasswordController,
                            isLoading: isLoading,
                            onSignUp: _handleSignUp,
                            onGoogle: _handleGoogle,
                            onFacebook: _handleFacebook,
                            onApple: _handleApple,
                            validateEmail: _validateEmail,
                            validatePassword: _validatePassword,
                          ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SignInTab extends StatelessWidget {
  const _SignInTab({
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onSignIn,
    required this.onGoogle,
    required this.onFacebook,
    required this.onApple,
    required this.validateEmail,
    required this.validatePassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSignIn;
  final VoidCallback onGoogle;
  final VoidCallback onFacebook;
  final VoidCallback onApple;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePassword;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AuthTextField(
              controller: emailController,
              label: 'Email address',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: validateEmail,
            ),
            const SizedBox(height: 18),
            AuthTextField(
              controller: passwordController,
              label: 'Password',
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: validatePassword,
              onEditingComplete: onSignIn,
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(ForgotPasswordScreen.route);
                },
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Sign in',
              onPressed: isLoading ? null : onSignIn,
              fullWidth: true,
              icon: Icons.login_rounded,
            ),
            const SizedBox(height: 28),
            const Row(
              children: [
                Expanded(child: Divider(color: AppColors.surfaceHighlight)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or continue with',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.surfaceHighlight)),
              ],
            ),
            const SizedBox(height: 24),
            // Social auth buttons in a row
            Row(
              children: [
                Expanded(
                  child: _GoogleSignInButton(
                    onPressed: isLoading ? null : onGoogle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SocialAuthButton(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    onPressed: isLoading ? null : onFacebook,
                    color: Colors.white,
                    backgroundColor: const Color(0xFF1877F2),
                    iconColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SocialAuthButton(
              icon: Icons.apple,
              label: 'Continue with Apple',
              onPressed: isLoading ? null : onApple,
            ),
          ],
        ),
      ),
    );
  }
}

class _SignUpTab extends StatelessWidget {
  const _SignUpTab({
    required this.formKey,
    required this.nameController,
    required this.emailController,
    required this.passwordController,
    required this.isLoading,
    required this.onSignUp,
    required this.onGoogle,
    required this.onFacebook,
    required this.onApple,
    required this.validateEmail,
    required this.validatePassword,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool isLoading;
  final VoidCallback onSignUp;
  final VoidCallback onGoogle;
  final VoidCallback onFacebook;
  final VoidCallback onApple;
  final String? Function(String?) validateEmail;
  final String? Function(String?) validatePassword;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Join StreamFlix',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your account to get started',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 32),
            AuthTextField(
              controller: nameController,
              label: 'Full name',
              textInputAction: TextInputAction.next,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Name is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 18),
            AuthTextField(
              controller: emailController,
              label: 'Email address',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: validateEmail,
            ),
            const SizedBox(height: 18),
            AuthTextField(
              controller: passwordController,
              label: 'Password',
              obscureText: true,
              textInputAction: TextInputAction.done,
              validator: validatePassword,
              onEditingComplete: onSignUp,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Create account',
              icon: Icons.rocket_launch_rounded,
              onPressed: isLoading ? null : onSignUp,
              fullWidth: true,
            ),
            const SizedBox(height: 28),
            const Row(
              children: [
                Expanded(child: Divider(color: AppColors.surfaceHighlight)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or continue with',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
                Expanded(child: Divider(color: AppColors.surfaceHighlight)),
              ],
            ),
            const SizedBox(height: 24),
            // Social auth buttons in a row
            Row(
              children: [
                Expanded(
                  child: _GoogleSignInButton(
                    onPressed: isLoading ? null : onGoogle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SocialAuthButton(
                    icon: Icons.facebook,
                    label: 'Facebook',
                    onPressed: isLoading ? null : onFacebook,
                    color: Colors.white,
                    backgroundColor: const Color(0xFF1877F2),
                    iconColor: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SocialAuthButton(
              icon: Icons.apple,
              label: 'Continue with Apple',
              onPressed: isLoading ? null : onApple,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  const _GoogleSignInButton({
    required this.onPressed,
  });

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: const Color(0xFF2C2C2C), // Dark charcoal/gray
        foregroundColor: Colors.white,
        side: BorderSide.none,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          _GoogleLogo(size: 20),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              'Sign in with Google',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleLogo extends StatelessWidget {
  const _GoogleLogo({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _GoogleLogoPainter(),
      ),
    );
  }
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;
    final strokeWidth = size.width * 0.24;

    // Google colors
    final blue = const Color(0xFF4285F4);
    final red = const Color(0xFFEA4335);
    final yellow = const Color(0xFFFBBC05);
    final green = const Color(0xFF34A853);

    final rect = Rect.fromCircle(center: center, radius: radius);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Draw arcs in the correct order to form the "G"
    // Starting from top (12 o'clock) going clockwise
    
    // Blue arc: top-right (from -90° to 0°)
    paint.color = blue;
    canvas.drawArc(rect, -1.5708, 1.5708, false, paint);

    // Red arc: top-left (from 0° to 90°)
    paint.color = red;
    canvas.drawArc(rect, 0, 1.5708, false, paint);

    // Yellow arc: bottom-left (from 90° to 180°)
    paint.color = yellow;
    canvas.drawArc(rect, 1.5708, 1.5708, false, paint);

    // Green arc: bottom-right, longer arc (from -90° to ~45°, about 135° total)
    paint.color = green;
    canvas.drawArc(rect, -1.5708, 2.3562, false, paint);

    // Draw the horizontal crossbar of the "G" (from center to right)
    paint.color = blue;
    paint.strokeWidth = strokeWidth * 0.7;
    final crossbarLength = radius * 0.52;
    final crossbarStart = Offset(center.dx, center.dy);
    final crossbarEnd = Offset(center.dx + crossbarLength, center.dy);
    canvas.drawLine(crossbarStart, crossbarEnd, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ToggleTab extends StatelessWidget {
  const _ToggleTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: AppColors.surfaceHighlight,
                  width: 1,
                )
              : null,
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? AppColors.textPrimary
                  : AppColors.textMuted,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                fontSize: 14,
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialAuthButton extends StatelessWidget {
  const _SocialAuthButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.color,
    required this.backgroundColor,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final Color backgroundColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        backgroundColor: backgroundColor,
        foregroundColor: color,
        side: BorderSide(
          color: backgroundColor == Colors.white
              ? AppColors.border
              : Colors.transparent,
        ),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ?? color,
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

