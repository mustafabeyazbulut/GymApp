/// Davetin türü - backend'in ham değeri URL'de de kullanılır
/// (POST /api/invitations/{type}/{id}/accept|reject).
enum InvitationType {
  gymAdmin('GymAdmin'),
  staff('Staff'),
  package('Package');

  const InvitationType(this.apiValue);

  final String apiValue;

  static InvitationType? fromApi(String value) {
    for (final type in values) {
      if (type.apiValue == value) return type;
    }
    return null;
  }
}

/// Kullanıcıya gelen, henüz onaylanmamış/reddedilmemiş ve süresi dolmamış bir
/// davet (ana senaryo §3.4): firma yöneticiliği, personel görevi ya da paket.
class Invitation {
  const Invitation({
    required this.id,
    required this.type,
    required this.companyName,
    required this.branchName,
    required this.role,
    required this.packageName,
    required this.invitedByName,
    required this.createdAt,
    required this.expiresAt,
  });

  /// Bilinmeyen bir tür gelirse null döner (listeden atlanır) - backend yeni
  /// bir davet türü eklerse eski uygulama sürümü çökmesin.
  static Invitation? tryFromJson(Map<String, dynamic> json) {
    final type = InvitationType.fromApi(json['type'] as String);
    if (type == null) return null;
    return Invitation(
      id: json['id'] as int,
      type: type,
      companyName: json['companyName'] as String,
      branchName: json['branchName'] as String?,
      role: json['role'] as String?,
      packageName: json['packageName'] as String?,
      invitedByName: json['invitedByName'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }

  final int id;
  final InvitationType type;
  final String companyName;
  // GymAdmin (firma geneli) davetinde null.
  final String? branchName;
  // Personel davetlerinde "GymAdmin"/"BranchManager"/"Trainer"; paket davetinde null.
  final String? role;
  // Sadece paket davetinde dolu.
  final String? packageName;
  final String? invitedByName;
  final DateTime createdAt;
  final DateTime expiresAt;
}
