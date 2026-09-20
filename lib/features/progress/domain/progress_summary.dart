class ProgressNote {
  const ProgressNote({
    required this.id,
    required this.techniqueScore,
    required this.conditionScore,
    required this.noteText,
    required this.createdAt,
    this.mediaFileId,
    this.mediaContentType,
  });

  factory ProgressNote.fromJson(Map<String, dynamic> json) => ProgressNote(
        id: json['id'] as int,
        techniqueScore: json['techniqueScore'] as int,
        conditionScore: json['conditionScore'] as int,
        noteText: json['noteText'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
        mediaFileId: json['mediaFileId'] as int?,
        mediaContentType: json['mediaContentType'] as String?,
      );

  final int id;
  // 0-100, bir antrenörün öznel değerlendirmesi.
  final int techniqueScore;
  final int conditionScore;
  final String? noteText;
  final DateTime createdAt;

  // İkisi de null = medyasız not (mevcut davranış). Opsiyonel "önce/sonra"
  // fotoğraf/video eki - content-library'nin aynı GET /api/media/{id}
  // endpoint'ini paylaşır (bkz. docs/superpowers/specs/2026-09-20-progress-media-design.md).
  final int? mediaFileId;
  final String? mediaContentType;

  bool get hasMedia => mediaFileId != null;
  bool get isVideoMedia => mediaContentType?.startsWith('video/') ?? false;
}

class ProgressSummary {
  const ProgressSummary({
    required this.classesThisMonth,
    required this.attendanceValue,
    required this.notes,
  });

  final int classesThisMonth;

  // 0.0-1.0 - gerçek CheckIn kayıtlarından hesaplanır (bkz.
  // progress_summary_provider.dart), antrenörün elle girdiği bir alan
  // DEĞİLDİR - bu bilinçli bir tasarım kararı, iki "gerçek" kaynağın
  // birbirinden sapmasını önlemek için (bkz. backend'in ProgressNote
  // entity'sinin kendi doc comment'i).
  final double attendanceValue;

  // Backend'den zaten en yeniden en eskiye sıralı gelir.
  final List<ProgressNote> notes;

  ProgressNote? get latestNote => notes.isEmpty ? null : notes.first;
  double get techniqueValue => (latestNote?.techniqueScore ?? 0) / 100;
  double get conditionValue => (latestNote?.conditionScore ?? 0) / 100;
}
