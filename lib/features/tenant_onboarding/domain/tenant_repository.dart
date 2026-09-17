import 'branch_option.dart';
import 'company_summary.dart';

abstract interface class TenantRepository {
  // Company + Branch + a Gym Admin (new or existing user, matched by phone)
  // in one call - Super Admin only, enforced server-side.
  Future<void> createCompany({
    required String companyName,
    required String branchName,
    required String branchAddress,
    required String gymAdminFullName,
    required String gymAdminPhone,
    String? gymAdminEmail,
  });

  // Every company, for the Company Management list screen - Super Admin only.
  Future<List<CompanyListItem>> listCompanies();

  Future<CompanyDetail> getCompanyDetail(int companyId);

  Future<void> updateCompanyName({required int companyId, required String name});

  Future<void> setCompanyActive({required int companyId, required bool isActive});

  // The branches visible to the caller - once the backend's real tenant
  // context is in place, a GymAdmin sees only their own company's branches.
  // Used to populate the branch picker in AddStaffMemberScreen for a
  // GymAdmin (a BranchManager already has a single fixed branch and never
  // needs this).
  Future<List<BranchOption>> listBranches();

  // A new Member/Trainer (new or existing user, matched by phone) attached
  // to one branch - Gym Admin/Branch Manager/Super Admin only, enforced
  // server-side (a Branch Manager is further restricted to their own
  // branch, a Gym Admin to their own company - both re-checked server-side
  // regardless of what branchId is sent here).
  Future<void> addStaffMember({
    required String fullName,
    required String phone,
    String? email,
    required String role, // 'Member' or 'Trainer'
    required int branchId,
  });
}
