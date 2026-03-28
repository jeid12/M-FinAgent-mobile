class SpendingSummary {
  SpendingSummary({
    required this.totalIncome,
    required this.totalExpense,
    required this.netFlow,
    required this.byCategory,
  });

  final double totalIncome;
  final double totalExpense;
  final double netFlow;
  final Map<String, double> byCategory;

  factory SpendingSummary.fromJson(Map<String, dynamic> json) {
    final rawMap = (json['by_category'] as Map<String, dynamic>? ?? {});
    return SpendingSummary(
      totalIncome: double.parse(json['total_income'].toString()),
      totalExpense: double.parse(json['total_expense'].toString()),
      netFlow: double.parse(json['net_flow'].toString()),
      byCategory: rawMap.map(
        (key, value) => MapEntry(key, double.parse(value.toString())),
      ),
    );
  }

  static SpendingSummary empty() {
    return SpendingSummary(
      totalIncome: 0,
      totalExpense: 0,
      netFlow: 0,
      byCategory: const {},
    );
  }
}
