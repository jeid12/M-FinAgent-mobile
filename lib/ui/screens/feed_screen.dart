import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../state/app_state.dart';
import '../widgets/transaction_tile.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key, required this.state});

  final AppState state;

  @override
  Widget build(BuildContext context) {
    final money = NumberFormat.currency(symbol: 'RWF ', decimalDigits: 0);

    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: TextButton(
          onPressed: state.refreshData,
          child: Text('Retry: ${state.error}'),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: state.refreshData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF003049), Color(0xFF005A7A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '7-Day Net Flow',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 6),
                Text(
                  money.format(state.summary.netFlow),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _StatChip(
                      label: 'Income',
                      value: money.format(state.summary.totalIncome),
                      background: const Color(0x3300E676),
                    ),
                    const SizedBox(width: 8),
                    _StatChip(
                      label: 'Expense',
                      value: money.format(state.summary.totalExpense),
                      background: const Color(0x33FF5252),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (state.alerts.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Live Alerts',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            for (final alert in state.alerts.take(3))
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5DE),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(alert),
              ),
          ],
          const SizedBox(height: 14),
          const Text(
            'Activity Feed',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 6),
          for (final tx in state.transactions) TransactionTile(item: tx),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value, required this.background});

  final String label;
  final String value;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}
