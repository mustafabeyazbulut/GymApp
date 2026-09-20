class ContentItem {
  const ContentItem({
    required this.id,
    required this.companyId,
    required this.branchId,
    required this.title,
    required this.description,
    required this.requiredAccessTier,
    required this.mediaFileId,
    required this.mediaContentType,
    required this.isActive,
    required this.createdAt,
    required this.hasAccess,
  });

  factory ContentItem.fromJson(Map<String, dynamic> json) => ContentItem(
        id: json['id'] as int,
        companyId: json['companyId'] as int,
        branchId: json['branchId'] as int?,
        title: json['title'] as String,
        description: json['description'] as String?,
        requiredAccessTier: json['requiredAccessTier'] as String,
        mediaFileId: json['mediaFileId'] as int,
        mediaContentType: json['mediaContentType'] as String,
        isActive: json['isActive'] as bool,
        createdAt: DateTime.parse(json['createdAt'] as String),
        hasAccess: json['hasAccess'] as bool,
      );

  final int id;
  final int companyId;
  final int? branchId;
  final String title;
  final String? description;
  // Backend'in ham enum ismi ("Standard"/"Premium") - diğer raw-string
  // alanlarla (ör. MePackageAssignment.category) aynı desen.
  final String requiredAccessTier;
  final int mediaFileId;
  final String mediaContentType;
  final bool isActive;
  final DateTime createdAt;

  // Sadece Member için anlamlı - backend, erişemediği Premium içeriği de
  // (upsell için) listede döner ama bu false olur; gerçek indirme kontrolü
  // GET /api/media/{id}'de backend tarafından yeniden yapılır, bu alan
  // sadece kilit ikonunu göstermek için.
  final bool hasAccess;

  bool get isPremium => requiredAccessTier == 'Premium';
  bool get isVideo => mediaContentType.startsWith('video/');
}
