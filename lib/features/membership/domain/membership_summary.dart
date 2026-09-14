enum MembershipStatus { active, frozen }

class PaymentHistoryEntry {
  const PaymentHistoryEntry({required this.date, required this.amount});

  final String date;
  final String amount;
}

class MembershipSummary {
  const MembershipSummary({
    required this.packageName,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.price,
    required this.isPaid,
    required this.paymentHistory,
  });

  final String packageName;
  final MembershipStatus status;
  final String startDate;
  final String endDate;
  final String price;
  final bool isPaid;
  final List<PaymentHistoryEntry> paymentHistory;

  MembershipSummary copyWith({MembershipStatus? status}) {
    return MembershipSummary(
      packageName: packageName,
      status: status ?? this.status,
      startDate: startDate,
      endDate: endDate,
      price: price,
      isPaid: isPaid,
      paymentHistory: paymentHistory,
    );
  }
}
