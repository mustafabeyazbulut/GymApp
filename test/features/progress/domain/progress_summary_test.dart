import 'package:flutter_test/flutter_test.dart';
import 'package:gym_app/features/progress/domain/progress_summary.dart';

void main() {
  test('ProgressNote.fromJson parses all fields including a null noteText', () {
    final note = ProgressNote.fromJson({
      'id': 1,
      'techniqueScore': 70,
      'conditionScore': 60,
      'noteText': null,
      'createdAt': '2026-01-01T10:00:00Z',
    });

    expect(note.id, 1);
    expect(note.techniqueScore, 70);
    expect(note.conditionScore, 60);
    expect(note.noteText, isNull);
  });

  test('latestNote/techniqueValue/conditionValue fall back to zero with no notes', () {
    const summary = ProgressSummary(classesThisMonth: 0, attendanceValue: 0, notes: []);

    expect(summary.latestNote, isNull);
    expect(summary.techniqueValue, 0);
    expect(summary.conditionValue, 0);
  });

  test('latestNote/techniqueValue/conditionValue use the first (newest) note', () {
    final summary = ProgressSummary(
      classesThisMonth: 3,
      attendanceValue: 0.5,
      notes: [
        ProgressNote(id: 2, techniqueScore: 80, conditionScore: 90, noteText: 'Yeni', createdAt: DateTime(2026, 2)),
        ProgressNote(id: 1, techniqueScore: 40, conditionScore: 40, noteText: 'Eski', createdAt: DateTime(2026, 1)),
      ],
    );

    expect(summary.latestNote!.id, 2);
    expect(summary.techniqueValue, 0.8);
    expect(summary.conditionValue, 0.9);
  });
}
