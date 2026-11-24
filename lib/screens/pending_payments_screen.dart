import 'package:flutter/material.dart';

import '../database/offline_payment_database.dart';
import '../models/offline_payment.dart';

class PendingPaymentsScreen extends StatefulWidget {
  final String collectorId;

  const PendingPaymentsScreen({super.key, required this.collectorId});

  @override
  State<PendingPaymentsScreen> createState() => _PendingPaymentsScreenState();
}

class _PendingPaymentsScreenState extends State<PendingPaymentsScreen> {
  final _database = OfflinePaymentDatabase.instance;

  late Future<List<OfflinePayment>> _payments;

  @override
  void initState() {
    super.initState();
    _payments = _loadPayments();
  }

  Future<List<OfflinePayment>> _loadPayments() {
    return _database.getPendingPayments(widget.collectorId);
  }

  Future<void> _refresh() async {
    setState(() {
      _payments = _loadPayments();
    });

    try {
      await _payments;
    } catch (_) {
      // FutureBuilder displays the error.
    }
  }

  String _formatDate(String value) {
    final date = DateTime.tryParse(value);

    if (date == null) {
      return value;
    }

    return date.toLocal().toString().split('.')[0];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        title: const Text('Pending Payments'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<OfflinePayment>>(
        future: _payments,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Unable to load pending payments.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final payments = snapshot.data ?? [];

          final totalMinor = payments.fold<int>(
            0,
            (sum, payment) => sum + payment.amountMinor,
          );

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Card(
                  color: const Color(0xFFE0F5EA),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.cloud_upload_outlined,
                          size: 42,
                          color: Color(0xFF087F5B),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '${payments.length} Pending Payments',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'LKR ${(totalMinor / 100).toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 20),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'These payments are stored locally '
                      'and have not been confirmed by '
                      'the server. Do not collect the '
                      'same payment again.',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                if (payments.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(30),
                    child: Center(child: Text('No pending payments')),
                  ),
                ...payments.map(
                  (payment) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Loan #${payment.loanId}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const Chip(
                                label: Text('PENDING'),
                                backgroundColor: Color(0xFFFFE8B3),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'LKR ${payment.amount.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text('Date: ${_formatDate(payment.createdAt)}'),
                          const SizedBox(height: 8),
                          SelectableText(
                            'Transaction ID: '
                            '${payment.clientTransactionId}',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
