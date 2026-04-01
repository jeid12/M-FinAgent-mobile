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
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF032A43), Color(0xFF0A5D7F), Color(0xFF157A8C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33053D61),
                  blurRadius: 24,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'YOUR MONEY RADAR',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  money.format(state.summary.netFlow),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  state.summary.netFlow.isNegative
                      ? 'You are running negative this week. Tighten transfers and airtime spend.'
                      : 'Healthy weekly balance. Keep this pace and lock savings early.',
                  style: const TextStyle(color: Colors.white70, fontSize: 12.5),
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
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3D8),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFF4D08A)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.notifications_active_rounded, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(alert)),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: const Color(0xFFEFF7EF),
              border: Border.all(color: const Color(0xFFB8D8B8)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.tips_and_updates_rounded, color: Color(0xFF1F6E43), size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Quick Comment',
                        style: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1F6E43)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        state.financeQuickComment,
                        style: const TextStyle(color: Color(0xFF2E4F3A), fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Activity Feed',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F7FB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFD8E3ED)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.sync_rounded, size: 16, color: Color(0xFF0A5D7F)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    state.smsSyncStatus,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF1F3B4D)),
                  ),
                ),
              ],
            ),
          ),
          if (state.historicalSmsLoading)
            Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F4FD),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF90CAF9)),
              ),
              child: Row(
                children: [
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Importing SMS history… ${state.historicalSmsProgress}',
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          if (state.transactions.isEmpty && !state.historicalSmsLoading)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFDCE7EF)),
              ),
              child: const Text(
                'No transactions yet. SMS from MTN MoMo, Airtel Money, MoCash, and banks will appear here automatically.',
                textAlign: TextAlign.center,
              ),
            ),
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
