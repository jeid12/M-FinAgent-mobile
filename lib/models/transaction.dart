class TransactionItem {
  TransactionItem({
    required this.id,
    required this.provider,
    required this.kind,
    required this.category,
    required this.amount,
    required this.counterparty,
    required this.occurredAt,
  });

  final String id;
  final String provider;
  final String kind;
  final String category;
  final double amount;
  final String? counterparty;
  final DateTime occurredAt;

  factory TransactionItem.fromJson(Map<String, dynamic> json) {
    return TransactionItem(
      id: json['id'] as String,
      provider: json['provider'] as String,
      kind: json['kind'] as String,
      category: json['category'] as String,
      amount: double.parse(json['amount'].toString()),
      counterparty: json['counterparty'] as String?,
      occurredAt: DateTime.parse(json['occurred_at'] as String),
    );
  }
}
