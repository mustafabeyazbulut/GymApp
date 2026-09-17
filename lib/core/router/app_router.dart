// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../widgets/app_shell.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/classes/presentation/screens/classes_screen.dart';
import '../../features/tenant_onboarding/presentation/screens/add_staff_member_screen.dart';
import '../../features/tenant_onboarding/presentation/screens/create_company_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/membership/presentation/screens/membership_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';

part 'app_router.g.dart';

// Routes reachable while NOT authenticated. Every route added here that
// should be usable before login (register, password-reset flows, etc.)
// must be added to this set, or `redirect` below will bounce it straight
// back to /login. Centralized here after Task 6's own review found the
// original two-line `||` check was already about to be forgotten for
// Task 7's /forgot-password route.
const _publicRoutes = {'/login', '/register', '/forgot-password'};

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateProvider);
  final isAuthed = authState.value ?? false;
  // While the initial silent-refresh check is still loading (authState is
  // AsyncLoading), isAuthed defaults to false — briefly showing /login
  // during app startup rather than blocking on a splash screen. Acceptable
  // for this plan's scope (a proper splash/loading screen is a follow-up).

  final router = GoRouter(
    initialLocation: isAuthed ? '/home' : '/login',
    redirect: (context, state) {
      final loggingIn = _publicRoutes.contains(state.matchedLocation);
      if (!isAuthed && !loggingIn) return '/login';
      if (isAuthed && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/admin/create-company',
        builder: (context, state) => const CreateCompanyScreen(),
      ),
      GoRoute(
        path: '/admin/add-staff-member',
        builder: (context, state) => const AddStaffMemberScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) => AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/home', builder: (context, state) => const HomeScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/classes', builder: (context, state) => const ClassesScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/progress', builder: (context, state) => const ProgressScreen())],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(path: '/membership', builder: (context, state) => const MembershipScreen()),
            ],
          ),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
}
