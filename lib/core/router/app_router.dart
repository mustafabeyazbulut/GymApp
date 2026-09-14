import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../widgets/app_shell.dart';
import '../../features/branches/presentation/screens/branch_form_screen.dart';
import '../../features/branches/presentation/screens/branch_list_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(Ref ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AppShell(child: BranchListScreen()),
      ),
      GoRoute(
        path: '/branches/new',
        builder: (context, state) => const BranchFormScreen(),
      ),
    ],
  );
}
