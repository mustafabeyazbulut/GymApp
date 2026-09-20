// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../widgets/app_shell.dart';
import '../../features/auth/presentation/providers/auth_state_provider.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/class_scheduling/presentation/screens/create_class_session_screen.dart';
import '../../features/classes/presentation/screens/classes_screen.dart';
import '../../features/content_library/presentation/screens/content_library_screen.dart';
import '../../features/content_library/presentation/screens/upload_content_item_screen.dart';
import '../../features/door_access/presentation/screens/door_access_screen.dart';
import '../../features/tenant_onboarding/presentation/screens/add_staff_member_screen.dart';
import '../../features/tenant_onboarding/presentation/screens/branch_management_screen.dart';
import '../../features/tenant_onboarding/presentation/screens/company_detail_screen.dart';
import '../../features/tenant_onboarding/presentation/screens/company_management_screen.dart';
import '../../features/tenant_onboarding/presentation/screens/create_company_screen.dart';
import '../../features/tenant_onboarding/presentation/screens/staff_management_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/invitations/presentation/screens/confirm_invitation_screen.dart';
import '../../features/membership/presentation/screens/membership_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/package_management/presentation/screens/assign_package_screen.dart';
import '../../features/package_management/presentation/screens/create_package_screen.dart';
import '../../features/package_management/presentation/screens/package_assignments_screen.dart';
import '../../features/package_management/presentation/screens/package_management_screen.dart';
import '../../features/progress/presentation/screens/progress_screen.dart';
import '../../features/trainer_schedule/presentation/screens/trainer_schedule_screen.dart';

part 'app_router.g.dart';

// Kimliği doğrulanmamışken (NOT authenticated) erişilebilen rotalar. Burada
// login öncesi kullanılabilmesi gereken (register, şifre sıfırlama akışları
// vb.) her yeni rota bu sete de eklenmeli, aksi halde aşağıdaki `redirect`
// onu doğrudan /login'e geri gönderir. Task 6'nın kendi incelemesi, orijinal
// iki satırlık `||` kontrolünün Task 7'nin /forgot-password rotası için
// unutulmak üzere olduğunu bulduktan sonra burada merkezileştirildi.
const _publicRoutes = {'/login', '/register', '/forgot-password'};

@riverpod
GoRouter appRouter(Ref ref) {
  final authState = ref.watch(authStateProvider);
  final isAuthed = authState.value ?? false;
  // İlk sessiz yenileme (silent-refresh) kontrolü henüz yüklenirken
  // (authState AsyncLoading durumundayken) isAuthed varsayılan olarak false
  // olur — bu da bir splash ekranında beklemek yerine uygulama başlangıcında
  // kısa süreliğine /login'in gösterilmesine yol açar. Bu planın kapsamı
  // için kabul edilebilir (düzgün bir splash/yükleme ekranı sonraki bir
  // adımdır).

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
        path: '/admin/companies',
        builder: (context, state) => const CompanyManagementScreen(),
      ),
      GoRoute(
        path: '/admin/companies/:id',
        builder: (context, state) => CompanyDetailScreen(companyId: int.parse(state.pathParameters['id']!)),
      ),
      GoRoute(
        path: '/admin/create-company',
        builder: (context, state) => const CreateCompanyScreen(),
      ),
      GoRoute(
        path: '/admin/add-staff-member',
        builder: (context, state) => const AddStaffMemberScreen(),
      ),
      GoRoute(
        path: '/staff/branches',
        builder: (context, state) => const BranchManagementScreen(),
      ),
      GoRoute(
        path: '/staff/members',
        builder: (context, state) => const StaffManagementScreen(),
      ),
      GoRoute(
        path: '/trainer/schedule',
        builder: (context, state) => const TrainerScheduleScreen(),
      ),
      GoRoute(
        path: '/staff/classes/create',
        builder: (context, state) => const CreateClassSessionScreen(),
      ),
      GoRoute(
        path: '/confirm-invitation',
        builder: (context, state) => const ConfirmInvitationScreen(),
      ),
      GoRoute(
        path: '/staff/packages',
        builder: (context, state) => const PackageManagementScreen(),
      ),
      GoRoute(
        path: '/staff/packages/create',
        builder: (context, state) => const CreatePackageScreen(),
      ),
      GoRoute(
        path: '/staff/packages/assign',
        builder: (context, state) => const AssignPackageScreen(),
      ),
      GoRoute(
        path: '/staff/packages/assignments',
        builder: (context, state) => const PackageAssignmentsScreen(),
      ),
      GoRoute(
        path: '/staff/analytics',
        builder: (context, state) => const AnalyticsScreen(),
      ),
      GoRoute(
        path: '/content-library',
        builder: (context, state) => const ContentLibraryScreen(),
      ),
      GoRoute(
        path: '/content-library/upload',
        builder: (context, state) => const UploadContentItemScreen(),
      ),
      GoRoute(
        path: '/staff/door-access',
        builder: (context, state) => const DoorAccessScreen(),
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
