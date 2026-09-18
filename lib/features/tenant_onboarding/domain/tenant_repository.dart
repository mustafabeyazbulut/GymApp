import 'branch_option.dart';
import 'company_summary.dart';

abstract interface class TenantRepository {
  // Company + Branch + bir Gym Admin (telefon numarasıyla eşleştirilen yeni
  // veya mevcut kullanıcı) tek bir çağrıda - sadece Super Admin, sunucu
  // tarafında zorunlu kılınır.
  Future<void> createCompany({
    required String companyName,
    required String branchName,
    required String branchAddress,
    required String gymAdminFullName,
    required String gymAdminPhone,
    String? gymAdminEmail,
  });

  // Company Management liste ekranı için tüm şirketler - sadece Super Admin.
  Future<List<CompanyListItem>> listCompanies();

  Future<CompanyDetail> getCompanyDetail(int companyId);

  Future<void> updateCompanyName({required int companyId, required String name});

  Future<void> setCompanyActive({required int companyId, required bool isActive});

  // Çağıran kullanıcıya görünen şubeler - backend'in gerçek tenant context'i
  // devreye girdiğinde, bir GymAdmin yalnızca kendi şirketinin şubelerini
  // görür. AddStaffMemberScreen'de bir GymAdmin için şube seçicisini
  // doldurmak amacıyla kullanılır (bir BranchManager'ın zaten sabit tek bir
  // şubesi vardır ve buna hiçbir zaman ihtiyaç duymaz).
  Future<List<BranchOption>> listBranches();

  // Bir şubeye bağlanan yeni bir Member/Trainer (telefon numarasıyla
  // eşleştirilen yeni veya mevcut kullanıcı) - sadece Gym Admin/Branch
  // Manager/Super Admin, sunucu tarafında zorunlu kılınır (bir Branch
  // Manager ayrıca kendi şubesiyle, bir Gym Admin ise kendi şirketiyle
  // sınırlıdır - burada hangi branchId gönderilirse gönderilsin ikisi de
  // sunucu tarafında yeniden kontrol edilir).
  Future<void> addStaffMember({
    required String fullName,
    required String phone,
    String? email,
    required String role, // 'Member' veya 'Trainer'
    required int branchId,
  });
}
