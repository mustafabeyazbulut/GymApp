import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'active_staff_company_provider.g.dart';

// Çok şirketli bir personelin (GymAdmin/BranchManager) şu an hangi şirket
// olarak hareket ettiği - dioProvider bunu her isteğe X-Active-Company-Id
// header'ı olarak ekler (bkz. GymAppApi'nin TenantContextMiddleware'i).
// Sadece bir İPUCU: backend, çağıranın kendi Assignment'larından biriyle
// gerçekten eşleşmediği sürece bu değere asla güvenmiyor. null = henüz
// seçim yapılmadı, backend kendi varsayılan (ilk Assignment) davranışına
// döner.
@riverpod
class ActiveStaffCompanyId extends _$ActiveStaffCompanyId {
  @override
  int? build() => null;

  void select(int? companyId) => state = companyId;
}
