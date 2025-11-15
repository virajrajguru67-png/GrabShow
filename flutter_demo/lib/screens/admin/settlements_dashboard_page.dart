import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../models/admin_models.dart';
import '../../repositories/admin_repository.dart';

class SettlementsDashboardPage extends StatefulWidget {
  const SettlementsDashboardPage({super.key});

  @override
  State<SettlementsDashboardPage> createState() =>
      _SettlementsDashboardPageState();
}

class _SettlementsDashboardPageState extends State<SettlementsDashboardPage> {
  late final AdminRepository _repository;
  bool _isLoading = true;
  String? _error;
  List<SettlementTransaction> _transactions = const [];

  @override
  void initState() {
    super.initState();
    _repository = context.read<AdminRepository>();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final token = context.read<AuthController>().accessToken;
    if (token == null) {
      setState(() {
        _error = 'Session expired. Please sign in again.';
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final data = await _repository.fetchSettlements(token);
      if (!mounted) return;
      setState(() {
        _transactions = data;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  double _totalForStatus(SettlementStatus status) {
    return _transactions
        .where((txn) => txn.status == status)
        .fold<double>(0, (sum, txn) => sum + txn.netPayout);
  }

  int _countForStatus(SettlementStatus status) {
    return _transactions.where((txn) => txn.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 12),
            Text(_error!, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            FilledButton.tonal(
                onPressed: _loadTransactions, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Settlements & payouts',
                  style: theme.textTheme.headlineSmall),
              FilledButton.tonalIcon(
                onPressed: _loadTransactions,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _SettlementMetricCard(
                title: 'Pending payouts',
                value:
                    currency.format(_totalForStatus(SettlementStatus.pending)),
                subtitle:
                    '${_countForStatus(SettlementStatus.pending)} transactions awaiting',
                icon: Icons.schedule,
                color: theme.colorScheme.surfaceVariant,
              ),
              _SettlementMetricCard(
                title: 'Processing',
                value: currency
                    .format(_totalForStatus(SettlementStatus.processing)),
                subtitle:
                    '${_countForStatus(SettlementStatus.processing)} in flight',
                icon: Icons.sync,
                color: theme.colorScheme.secondaryContainer,
              ),
              _SettlementMetricCard(
                title: 'Completed this week',
                value: currency
                    .format(_totalForStatus(SettlementStatus.completed)),
                subtitle:
                    '${_countForStatus(SettlementStatus.completed)} settled',
                icon: Icons.task_alt,
                color: theme.colorScheme.primaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Gateway')),
                    DataColumn(label: Text('Transaction')),
                    DataColumn(label: Text('Booking')),
                    DataColumn(label: Text('Gross')),
                    DataColumn(label: Text('Fees')),
                    DataColumn(label: Text('Net payout')),
                    DataColumn(label: Text('Status')),
                    DataColumn(label: Text('Settled at')),
                  ],
                  rows: _transactions
                      .map(
                        (txn) => DataRow(
                          cells: [
                            DataCell(Text(txn.gateway)),
                            DataCell(Text(txn.transactionId)),
                            DataCell(Text(txn.bookingReference)),
                            DataCell(Text(currency.format(txn.amount))),
                            DataCell(Text(currency.format(txn.fees))),
                            DataCell(Text(currency.format(txn.netPayout))),
                            DataCell(_StatusChip(status: txn.status)),
                            DataCell(
                              Text(
                                txn.settledAt != null
                                    ? DateFormat('dd MMM yyyy')
                                        .format(txn.settledAt!)
                                    : '--',
                              ),
                            ),
                          ],
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SettlementMetricCard extends StatelessWidget {
  const _SettlementMetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 300,
      child: Card(
        color: color,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: 16),
              Text(title, style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                value,
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(subtitle),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final SettlementStatus status;

  Color _colorForStatus(ThemeData theme) {
    switch (status) {
      case SettlementStatus.pending:
        return theme.colorScheme.surfaceVariant;
      case SettlementStatus.processing:
        return theme.colorScheme.secondaryContainer;
      case SettlementStatus.completed:
        return theme.colorScheme.primaryContainer;
    }
  }

  String _labelForStatus() {
    switch (status) {
      case SettlementStatus.pending:
        return 'Pending';
      case SettlementStatus.processing:
        return 'Processing';
      case SettlementStatus.completed:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(_labelForStatus()),
      backgroundColor: _colorForStatus(theme),
    );
  }
}
