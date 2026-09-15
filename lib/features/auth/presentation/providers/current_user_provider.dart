import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/real_auth_repository.dart';
import '../../domain/me_result.dart';

part 'current_user_provider.g.dart';

@riverpod
Future<MeResult> currentUser(Ref ref) => ref.watch(authRepositoryProvider).getMe();
