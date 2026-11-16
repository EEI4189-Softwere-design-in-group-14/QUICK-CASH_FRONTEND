
import 'package:flutter/material.dart';

import '../core/api_client.dart';

class BorrowerPaymentHistoryScreen extends StatefulWidget {
  final String token;

  const BorrowerPaymentHistoryScreen({
    super.key,
    required this.token,
  });

  @override
  State<BorrowerPaymentHistoryScreen> createState() =>
      _BorrowerPaymentHistoryScreenState();
}

class _BorrowerPaymentHistoryScreenState
    extends State<BorrowerPaymentHistoryScreen> {
  static const Color primaryGreen = Color(0xFF087F5B);

  late Future<List<Map<String, dynamic>>> _payments;

  @override
  void initState() {
    super.initState();
    _payments = _loadPayments();
  }

  Future<List<Map<String, dynamic>>> _loadPayments() async {
    final api = ApiClient();

    try {
      final response = await api.request(
        'GET',
        '/borrower/payments',
        token: widget.token,
      );

      if (response is! List) {
        throw const ApiException(
          'Unexpected payment history response.',
        );
      }

      final payments = response
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      // Newest payments first.
      payments.sort((a, b) {
        final dateA = '${a['paymentDate'] ?? ''}';
        final dateB = '${b['paymentDate'] ?? ''}';
        return dateB.compareTo(dateA);
      });

      return payments;
    } finally {
      api.close();
    }
  }

  Future<void> _refresh() async {
    final next = _loadPayments();

    setState(() {
      _payments = next;
    });

    try {
      await next;
    } catch (_) {
      // FutureBuilder displays the error.
    }
  }

  String _money(Object? value) {
    final amount = num.tryParse('$value');

    if (amount == null) return 'LKR -';

    return 'LKR ${amount.toStringAsFixed(2)}';
  }

  String _date(Object? value) {
    if (value == null) return '-';

    return value.toString().replaceFirst('T', ' ');
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACCEPTED':
      case 'PAID':
        return Colors.green;

      case 'PENDING':
        return Colors.orange;

      case 'REJECTED':
      case 'FAILED':
        return Colors.red;

      default:
        return Colors.grey;
    }
  }

  Widget _detailRow(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _paymentCard(Map<String, dynamic> payment) {
    final status = '${payment['status'] ?? 'UNKNOWN'}';
    final statusColor = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.payments_outlined,
                  color: primaryGreen,
                ),

                const SizedBox(width: 10),

                Expanded(
                  child: Text(
                    '${payment['paymentCode'] ?? 'Payment'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Text(
              _money(payment['amount']),
              style: const TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
                color: primaryGreen,
              ),
            ),

            const SizedBox(height: 10),

            Chip(
              label: Text(
                status.replaceAll('_', ' '),
                style: TextStyle(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: statusColor.withValues(
                alpha: 0.10,
              ),
              side: BorderSide.none,
            ),

            const Divider(height: 24),

            _detailRow(
              'Payment Date',
              _date(payment['paymentDate']),
            ),

            _detailRow(
              'Loan ID',
              '${payment['loanId'] ?? '-'}',
            ),

            _detailRow(
              'Payment Source',
              '${payment['source'] ?? '-'}',
            ),

            _detailRow(
              'Balance Before',
              _money(payment['balanceBefore']),
            ),

            _detailRow(
              'Balance After',
              _money(payment['balanceAfter']),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        title: const Text('My Payment History'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _payments,
        builder: (context, snapshot) {
          if (snapshot.connectionState !=
              ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 48,
                    ),

                    const SizedBox(height: 12),

                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 15),

                    ElevatedButton(
                      onPressed: _refresh,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final payments = snapshot.data!;

          if (payments.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refresh,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 120),

                  Icon(
                    Icons.receipt_long_outlined,
                    size: 65,
                    color: Colors.grey,
                  ),

                  SizedBox(height: 15),

                  Text(
                    'No payments found yet.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: payments.length,
              itemBuilder: (context, index) {
                return _paymentCard(payments[index]);
              },
            ),
          );
        },
      ),
    );
  }
}
