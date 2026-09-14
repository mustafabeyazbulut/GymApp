import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../domain/home_repository.dart';
import '../domain/home_summary.dart';

part 'fake_home_repository.g.dart';

class FakeHomeRepository implements HomeRepository {
  @override
  Future<HomeSummary> getHomeSummary() async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const HomeSummary(
      greetingName: 'Elnara',
      activePackageName: 'BJJ + Fitness',
      daysLeft: 18,
      nextClassName: 'BJJ Temel',
      nextClassTime: 'Bugün 19:00',
      nextClassTrainer: 'Mert Demir',
      weeklyAttendance: [
        ('Pzt', true), ('Sal', true), ('Çar', false), ('Per', true),
        ('Cum', false), ('Cmt', true), ('Paz', false),
      ],
    );
  }
}

@riverpod
HomeRepository homeRepository(Ref ref) => FakeHomeRepository();
