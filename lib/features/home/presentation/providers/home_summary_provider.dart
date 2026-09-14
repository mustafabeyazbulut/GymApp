import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/fake_home_repository.dart';
import '../../domain/home_summary.dart';

part 'home_summary_provider.g.dart';

@riverpod
Future<HomeSummary> homeSummary(Ref ref) {
  return ref.watch(homeRepositoryProvider).getHomeSummary();
}
