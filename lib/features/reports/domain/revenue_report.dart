class RevenueReport {
  const RevenueReport({
    required this.fromDate,
    required this.toDate,
    required this.totalAmount,
    required this.methodBreakdown,
    required this.dailyBreakdown,
  });

  factory RevenueReport.fromJson(Map<String, dynamic> json) => RevenueReport(
        fromDate: DateTime.parse(json['fromDate'] as String),
        toDate: DateTime.parse(json['toDate'] as String),
        totalAmount: (json['totalAmount'] as num).toDouble(),
        methodBreakdown: (json['methodBreakdown'] as List)
            .map((e) => RevenueMethodBreakdown.fromJson(e as Map<String, dynamic>))
            .toList(),
        dailyBreakdown: (json['dailyBreakdown'] as List)
            .map((e) => RevenueDailyBreakdown.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  final DateTime fromDate;
  final DateTime toDate;
  final double totalAmount;
  final List<RevenueMethodBreakdown> methodBreakdown;
  final List<RevenueDailyBreakdown> dailyBreakdown;
}

class RevenueMethodBreakdown {
  const RevenueMethodBreakdown({required this.method, required this.amount});

  factory RevenueMethodBreakdown.fromJson(Map<String, dynamic> json) => RevenueMethodBreakdown(
        method: json['method'] as String,
        amount: (json['amount'] as num).toDouble(),
      );

  // Backend'in ham enum ismi ("Cash"/"Card"/"BankTransfer").
  final String method;
  final double amount;
}

class RevenueDailyBreakdown {
  const RevenueDailyBreakdown({required this.date, required this.amount});

  factory RevenueDailyBreakdown.fromJson(Map<String, dynamic> json) => RevenueDailyBreakdown(
        date: DateTime.parse(json['date'] as String),
        amount: (json['amount'] as num).toDouble(),
      );

  final DateTime date;
  final double amount;
}
