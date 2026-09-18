import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/real_membership_repository.dart';
import '../../domain/membership_summary.dart';

part 'membership_provider.g.dart';

@riverpod
Future<List<PaymentHistoryEntry>> membershipPayments(Ref ref, int packageAssignmentId) =>
    ref.watch(membershipRepositoryProvider).getPayments(packageAssignmentId);
