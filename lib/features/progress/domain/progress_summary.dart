enum ProgressCategory { bjj, fitness }

class ProgressSummary {
  const ProgressSummary({
    required this.achievementTitle,
    required this.achievementQuote,
    required this.classesThisMonth,
    required this.techniqueValue,
    required this.attendanceValue,
    required this.conditionValue,
    required this.trainerNoteText,
    required this.trainerNoteAuthor,
    required this.trainerNoteDate,
  });

  final String achievementTitle;
  final String achievementQuote;
  final int classesThisMonth;
  final double techniqueValue;
  final double attendanceValue;
  final double conditionValue;
  final String trainerNoteText;
  final String trainerNoteAuthor;
  final String trainerNoteDate;
}
