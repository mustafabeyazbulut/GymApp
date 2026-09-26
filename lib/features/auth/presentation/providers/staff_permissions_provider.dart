import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/providers/active_staff_assignment_provider.dart';
import '../../domain/staff_permissions.dart';
import 'current_user_provider.dart';

part 'staff_permissions_provider.g.dart';

/// Aktif göreve göre yetki matrisi - kullanıcı yüklenmediyse hiçbir yetki
/// yoktur. Menü, rota korumaları ve personel ekranları bunu izler; görev
/// değişince hepsi birlikte yeniden hesaplanır.
@riverpod
StaffPermissions staffPermissions(Ref ref) => StaffPermissions.of(
      ref.watch(currentUserProvider).asData?.value,
      ref.watch(activeStaffAssignmentProvider),
    );
