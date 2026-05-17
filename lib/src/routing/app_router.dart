import 'package:go_router/go_router.dart';
import 'package:adadi/src/routing/global_navigator.dart';
import 'package:adadi/src/routing/app_routes.dart';

import 'package:adadi/src/features/auth/presentation/screens/login_screen.dart';
import 'package:adadi/src/features/auth/presentation/screens/signup_screen.dart';
import 'package:adadi/src/features/auth/presentation/screens/forgot_password_screen.dart';

import 'package:adadi/src/features/home/presentation/screens/home_page.dart';
import 'package:adadi/src/features/onboarding/presentation/screens/onboarding_page.dart';
import 'package:adadi/src/features/apartments/views/apartment_list_screen.dart';
import 'package:adadi/src/features/apartments/views/apartment_form_screen.dart';

final GoRouter appRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: AppRoutes.onboarding,
  routes: <RouteBase>[
    GoRoute(
      path: AppRoutes.onboarding,
      name: 'onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: AppRoutes.login,
      name: 'login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.signup,
      name: 'signup',
      builder: (context, state) => const SignupScreen(),
    ),
    GoRoute(
      path: AppRoutes.forgotPassword,
      name: 'forgotPassword',
      builder: (context, state) => const ForgotPasswordScreen(),
    ),
    GoRoute(
      path: AppRoutes.home,
      name: 'home',
      builder: (context, state) => const HomePage(),
    ),
    GoRoute(
      path: AppRoutes.apartments,
      name: 'apartments',
      builder: (context, state) => const ApartmentListScreen(),
    ),
    GoRoute(
      path: AppRoutes.apartmentsAdd,
      name: 'apartmentsAdd',
      builder: (context, state) => const ApartmentFormScreen(),
    ),
  ],
);
