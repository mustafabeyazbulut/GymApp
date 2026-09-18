import 'branch_option.dart';
import 'branch_summary.dart';
import 'company_summary.dart';
import 'staff_member_summary.dart';

abstract interface class TenantRepository {
  // Sadece Company oluşturur ve GymAdmin'e bir davet gönderir (telefon
  // numarasıyla eşleştirilen ZATEN KAYITLI bir kullanıcıya) - sadece Super
  // Admin, sunucu tarafında zorunlu kılınır. Branch KASITLI OLARAK burada
  // yok - yeni GymAdmin daveti onayladıktan sonra kendi şubesini kendisi
  // oluşturur (bkz. GymAppApi'nin project-branch-ownership-flow.md'si).
  // Assignment de hemen oluşmaz - davet, GymAdmin kendi
  // confirmAssignmentInvitation çağrısıyla onaylayana kadar sadece bekler.
  Future<void> createCompany({
    required String companyName,
    required String gymAdminPhone,
  });

  // Çağıranın kendi telefonuna gelen bir davet kodunu onaylar - hem
  // createCompany (GymAdmin daveti) hem addStaffMember (Member/Trainer
  // daveti) hem de inviteGymAdmin'in ürettiği davetler için tek, ortak onay
  // noktası (POST /api/assignments/confirm).
  Future<void> confirmAssignmentInvitation(String code);

  // ZATEN KAYITLI bir kullanıcıyı bu şirkete İKİNCİ (veya üçüncü...) bir
  // GymAdmin olarak davet eder - bir şirketin birden fazla GymAdmin'i
  // olabilir (ör. iş ortakları). Sadece mevcut bir GymAdmin/Super Admin,
  // sunucu tarafında zorunlu kılınır. Assignment hemen oluşmaz - davet
  // edilen kişi kendi confirmAssignmentInvitation çağrısıyla onaylayana
  // kadar sadece bekler.
  Future<void> inviteGymAdmin({required int companyId, required String phone});

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

  // Bir şubeye ZATEN KAYITLI bir Member/Trainer'ı (telefon numarasıyla
  // eşleştirilir, yeni kullanıcı oluşturulmaz) davet eder - sadece Gym
  // Admin/Branch Manager/Super Admin, sunucu tarafında zorunlu kılınır (bir
  // Branch Manager ayrıca kendi şubesiyle, bir Gym Admin ise kendi
  // şirketiyle sınırlıdır - burada hangi branchId gönderilirse gönderilsin
  // ikisi de sunucu tarafında yeniden kontrol edilir). Assignment hemen
  // oluşmaz - davet edilen kişi kendi confirmAssignmentInvitation
  // çağrısıyla onaylayana kadar sadece bekler.
  Future<void> addStaffMember({
    required String phone,
    required String role, // 'Member' veya 'Trainer'
    required int branchId,
  });

  // "Şubelerim" ekranı için - listBranches()'ın (dropdown'lar için sadece
  // id/name) aksine adres ve aktiflik durumunu da döner. Bir GymAdmin'in
  // daveti onayladıktan SONRA ilk şubesini kendisinin oluşturması gerekir
  // (bkz. GymAppApi'nin project-branch-ownership-flow.md'si) - bu üçü
  // olmadan yeni bir GymAdmin uygulamadan hiçbir şey yapamaz.
  Future<List<BranchSummary>> getManagedBranches();

  Future<void> createBranch({required int companyId, required String name, required String address});

  Future<void> updateBranch({required int branchId, required String name, required String address});

  // Sadece kapatabilir (isActive: false) - backend'de bir kez kapatılan
  // şube herkesten (kapatan GymAdmin dahil) gizlenir, yalnızca Super Admin
  // tekrar açabilir (bkz. project-branch-ownership-flow.md'nin Task 6
  // notu). Bilinçli bir backend kısıtı, mobil tarafta "aç" seçeneği yok.
  Future<void> setBranchActive({required int branchId, required bool isActive});

  // "Personelim" ekranı için - personel eklemenin (addStaffMember/
  // inviteGymAdmin) ve kaldırmanın (removeAssignment) arasında "şu an
  // kimler çalışıyor" sorusunun cevabıydı bu.
  Future<List<StaffMemberSummary>> getStaffMembers();

  Future<void> removeAssignment(int assignmentId);
}
