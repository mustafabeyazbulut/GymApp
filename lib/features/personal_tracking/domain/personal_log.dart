import 'package:intl/intl.dart';

final _apiDateFormat = DateFormat('yyyy-MM-dd');

String personalLogApiDate(DateTime date) => _apiDateFormat.format(date);

enum PersonalLogKind {
  workout('Workout'),
  measurement('Measurement');

  const PersonalLogKind(this.apiValue);

  final String apiValue;

  static PersonalLogKind fromApi(String value) =>
      value == PersonalLogKind.measurement.apiValue ? PersonalLogKind.measurement : PersonalLogKind.workout;
}

/// Kullanıcının kendi girdiği, gym'den bağımsız kişisel takip kaydı (ana
/// senaryo §5.1): antrenman ya da vücut ölçümü.
class PersonalLog {
  const PersonalLog({
    required this.id,
    required this.date,
    required this.kind,
    required this.title,
    required this.durationMinutes,
    required this.notes,
    required this.weightKg,
    required this.bodyFatPercent,
    required this.waistCm,
    required this.createdAt,
  });

  factory PersonalLog.fromJson(Map<String, dynamic> json) => PersonalLog(
        id: json['id'] as int,
        // Gün bazlı tarih - saat dilimi kaymasın diye yerel gün olarak ayrıştırılır.
        date: _apiDateFormat.parseStrict(json['date'] as String),
        kind: PersonalLogKind.fromApi(json['kind'] as String),
        title: json['title'] as String?,
        durationMinutes: json['durationMinutes'] as int?,
        notes: json['notes'] as String?,
        weightKg: (json['weightKg'] as num?)?.toDouble(),
        bodyFatPercent: (json['bodyFatPercent'] as num?)?.toDouble(),
        waistCm: (json['waistCm'] as num?)?.toDouble(),
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  final int id;
  final DateTime date;
  final PersonalLogKind kind;
  final String? title;
  final int? durationMinutes;
  final String? notes;
  final double? weightKg;
  final double? bodyFatPercent;
  final double? waistCm;
  final DateTime createdAt;

  PersonalLogDraft toDraft() => PersonalLogDraft(
        date: date,
        kind: kind,
        title: title,
        durationMinutes: durationMinutes,
        notes: notes,
        weightKg: weightKg,
        bodyFatPercent: bodyFatPercent,
        waistCm: waistCm,
      );
}

/// Oluşturma/güncelleme isteğinin gövdesi.
class PersonalLogDraft {
  const PersonalLogDraft({
    required this.date,
    required this.kind,
    this.title,
    this.durationMinutes,
    this.notes,
    this.weightKg,
    this.bodyFatPercent,
    this.waistCm,
  });

  final DateTime date;
  final PersonalLogKind kind;
  final String? title;
  final int? durationMinutes;
  final String? notes;
  final double? weightKg;
  final double? bodyFatPercent;
  final double? waistCm;

  Map<String, dynamic> toJson() => {
        'date': personalLogApiDate(date),
        'kind': kind.apiValue,
        'title': title,
        'durationMinutes': durationMinutes,
        'notes': notes,
        'weightKg': weightKg,
        'bodyFatPercent': bodyFatPercent,
        'waistCm': waistCm,
      };
}
