import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../models/transaction.dart';

class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.item});

  final TransactionItem item;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: 'RWF ', decimalDigits: 0);
    final time = DateFormat('EEE dd MMM, HH:mm').format(item.occurredAt.toLocal());
    final meta = _KindMeta.from(item.kind);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        color: meta.bgColor,
        border: Border.all(color: meta.borderColor),
        boxShadow: const [
          BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 3)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(shape: BoxShape.circle, color: meta.iconBg),
            child: Icon(meta.icon, color: Colors.white, size: 19),
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${item.provider} • $time',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _KindChip(label: meta.label, color: meta.iconBg),
                  ],
                ),
              ],
            ),
          ),
          Text(
            '${meta.prefix}${money.format(item.amount)}',
            style: TextStyle(fontWeight: FontWeight.w800, color: meta.amountColor),
          ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _KindMeta {
  const _KindMeta({
    required this.label,
    required this.icon,
    required this.iconBg,
    required this.bgColor,
    required this.borderColor,
    required this.amountColor,
    required this.prefix,
  });

  final String label;
  final IconData icon;
  final Color iconBg;
  final Color bgColor;
  final Color borderColor;
  final Color amountColor;
  final String prefix;

  factory _KindMeta.from(String kind) {
    switch (kind) {
      case 'income':
        return const _KindMeta(
          label: 'Income',
          icon: Icons.call_received_rounded,
          iconBg: Color(0xFF00A656),
          bgColor: Color(0xFFE9FFF1),
          borderColor: Color(0xFFC9F0D8),
          amountColor: Color(0xFF006A38),
          prefix: '+',
        );
      case 'loan_disbursement':
        return const _KindMeta(
          label: 'Loan In',
          icon: Icons.account_balance_rounded,
          iconBg: Color(0xFF6C63FF),
          bgColor: Color(0xFFF0EEFF),
          borderColor: Color(0xFFD0CAFF),
          amountColor: Color(0xFF3B32B0),
          prefix: '+',
        );
      case 'loan_repayment':
        return const _KindMeta(
          label: 'Loan Out',
          icon: Icons.account_balance_rounded,
          iconBg: Color(0xFFE53935),
          bgColor: Color(0xFFFFF0F0),
          borderColor: Color(0xFFFFCDD2),
          amountColor: Color(0xFFB71C1C),
          prefix: '-',
        );
      case 'transfer':
        return const _KindMeta(
          label: 'Transfer',
          icon: Icons.swap_horiz_rounded,
          iconBg: Color(0xFF0288D1),
          bgColor: Color(0xFFE1F5FE),
          borderColor: Color(0xFFB3E5FC),
          amountColor: Color(0xFF01579B),
          prefix: '±',
        );
      default: // expense
        return const _KindMeta(
          label: 'Expense',
          icon: Icons.call_made_rounded,
          iconBg: Color(0xFFFF8A00),
          bgColor: Color(0xFFFFF1E8),
          borderColor: Color(0xFFFFD6BF),
          amountColor: Color(0xFFB13A00),
          prefix: '-',
        );
    }
  }
}
