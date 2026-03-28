import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.item});

  final TransactionItem item;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: 'RWF ', decimalDigits: 0);
    final time = DateFormat('EEE, HH:mm').format(item.occurredAt.toLocal());
    final outgoing = item.kind == 'expense';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: outgoing ? const Color(0xFFFFF1E8) : const Color(0xFFE9FFF1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: outgoing ? const Color(0xFFFF8A00) : const Color(0xFF00A656),
            ),
            child: Icon(
              outgoing ? Icons.call_made : Icons.call_received,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.counterparty ?? item.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
                Text(
                  '${item.provider} • $time',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            '${outgoing ? '-' : '+'}${money.format(item.amount)}',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              color: outgoing ? const Color(0xFFB13A00) : const Color(0xFF006A38),
            ),
          ),
        ],
      ),
    );
  }
}
