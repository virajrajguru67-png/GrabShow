import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'config/api_config.dart';
import 'controllers/auth_controller.dart';
import 'repositories/auth_repository.dart';
import 'repositories/admin_repository.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/admin/admin_login_screen.dart';
import 'screens/bookings_screen.dart';
import 'screens/booking_confirmation_screen.dart';
import 'screens/checkout_screen.dart';
import 'screens/edit_profile_screen.dart';
import 'screens/help_support_screen.dart';
import 'screens/home_screen.dart';
import 'screens/movie_detail_screen.dart';
import 'screens/navigation_shell.dart';
import 'screens/notifications_settings_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/payment_methods_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/saved_theatres_screen.dart';
import 'screens/search_screen.dart';
import 'screens/seat_selection_screen.dart';
import 'screens/auth_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/sign_in_screen.dart';
import 'screens/sign_up_screen.dart';
import 'screens/terms_privacy_screen.dart';
import 'services/api_client.dart';
import 'theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final apiClient = ApiClient(baseUrl: ApiConfig.baseUrl);
  // Google OAuth Web Client ID (use this as serverClientId for Android/iOS)
  const googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue: '851473230830-pluq3delcr6gdo5ifm0ik9tb343hafpf.apps.googleusercontent.com',
  );
  final authRepository = AuthRepository(
    apiClient: apiClient,
    webClientId: googleClientId.isNotEmpty ? googleClientId : null,
    serverClientId: googleClientId.isNotEmpty ? googleClientId : null,
  );

  runApp(
    MultiProvider(
      providers: [
        Provider<ApiClient>.value(value: apiClient),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<AdminRepository>.value(value: AdminRepository(apiClient: apiClient)),
        ChangeNotifierProvider(
          create: (context) =>
              AuthController(authRepository: context.read<AuthRepository>())..loadSession(),
        ),
      ],
      child: const DemoApp(),
    ),
  );
}

class DemoApp extends StatelessWidget {
  const DemoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'StreamFlix Tickets',
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      initialRoute: SplashScreen.route,
      routes: {
        SplashScreen.route: (context) => const SplashScreen(),
        OnboardingScreen.route: (context) => const OnboardingScreen(),
        AuthScreen.route: (context) => const AuthScreen(),
        SignInScreen.route: (context) => const AuthScreen(), // Redirect to combined auth
        SignUpScreen.route: (context) => const AuthScreen(), // Redirect to combined auth
        ForgotPasswordScreen.route: (context) => const ForgotPasswordScreen(),
        NavigationShell.route: (context) => const NavigationShell(),
        HomeScreen.route: (context) => const HomeScreen(),
        CheckoutScreen.route: (context) => const CheckoutScreen(),
        BookingConfirmationScreen.route: (context) => const BookingConfirmationScreen(),
        AdminLoginScreen.route: (context) => const AdminLoginScreen(),
        AdminHomeScreen.route: (context) => const AdminHomeScreen(),
        SearchScreen.route: (context) => const SearchScreen(),
        BookingsScreen.route: (context) => const BookingsScreen(),
        ProfileScreen.route: (context) => const ProfileScreen(),
        MovieDetailScreen.route: (context) => const MovieDetailScreen(),
        SeatSelectionScreen.route: (context) => const SeatSelectionScreen(),
        EditProfileScreen.route: (context) => const EditProfileScreen(),
        PaymentMethodsScreen.route: (context) => const PaymentMethodsScreen(),
        SavedTheatresScreen.route: (context) => const SavedTheatresScreen(),
        HelpSupportScreen.route: (context) => const HelpSupportScreen(),
        TermsPrivacyScreen.route: (context) => const TermsPrivacyScreen(),
        NotificationsSettingsScreen.route: (context) => const NotificationsSettingsScreen(),
      },
    );
  }
}
