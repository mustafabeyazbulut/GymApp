// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../widgets/app_shell.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/classes/presentation/screens/classes_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/membership/presentation/screens/membership_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';

part 'app_router.g.dart';

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
      final loggingIn = state.matchedLocation == '/login';
      if (!isAuthed && !loggingIn) return '/login';
      if (isAuthed && loggingIn) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
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
