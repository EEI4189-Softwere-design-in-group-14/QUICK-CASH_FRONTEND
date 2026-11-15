
import 'package:flutter/material.dart';

class PaymentSuccessScreen extends StatelessWidget {
  final Map<String, dynamic> payment;
  final String borrowerName;
  final Map<String, dynamic>? receipt;
  final bool previewMode;
  final VoidCallback? onOpenPdf;

  const PaymentSuccessScreen({
    super.key,
    required this.payment,
    required this.borrowerName,
    this.receipt,
    this.previewMode = false,
    this.onOpenPdf,
  });

  static const Color primaryGreen = Color(0xFF087F5B);

  String _money(Object? value) {
    final amount = num.tryParse(value.toString());
    if (amount == null) return 'LKR -';
    return 'LKR ${amount.toStringAsFixed(2)}';
  }

  String _date(Object? value) {
    if (value == null) return '-';
    return value.toString().replaceFirst('T', ' ');
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            flex: 3,
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

  @override
  Widget build(BuildContext context) {
    final accepted = payment['status'] == 'ACCEPTED' &&
        payment['paymentId'] is num;

    // Never show a real success screen for a failed payment.
    if (!previewMode && !accepted) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Status')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Payment is not confirmed. '
                  'Please verify the payment with the server.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        title: const Text('Payment Confirmation'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 16),

                CircleAvatar(
                  radius: 47,
                  backgroundColor: previewMode
                      ? Colors.orange.shade100
                      : const Color(0xFFE0F5EA),
                  child: Icon(
                    previewMode
                        ? Icons.visibility_outlined
                        : Icons.check_circle,
                    size: 64,
                    color: previewMode
                        ? Colors.orange.shade800
                        : primaryGreen,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  previewMode
                      ? 'Payment UI Preview'
                      : 'Payment Successful!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 9),

                Text(
                  previewMode
                      ? 'Demo only. No payment has been saved.'
                      : 'Your loan payment has been recorded.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 24),

                Card(
                  elevation: 1,
                  child: Padding(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      children: [
                        const Text(
                          'Payment Amount',
                          style: TextStyle(
                            color: Colors.black54,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          _money(payment['amount']),
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                            color: primaryGreen,
                          ),
                        ),

                        const Divider(height: 32),

                        _detailRow(
                          'Borrower',
                          borrowerName,
                        ),

                        _detailRow(
                          'Loan Code',
                          '${payment['loanCode'] ?? '-'}',
                        ),

                        _detailRow(
                          'Payment Reference',
                          '${payment['paymentCode'] ?? '-'}',
                        ),

                        _detailRow(
                          'Payment Date',
                          _date(payment['paymentDate']),
                        ),

                        _detailRow(
                          'Collector',
                          '${payment['collector'] ?? '-'}',
                        ),

                        const Divider(height: 28),

                        _detailRow(
                          'Remaining Balance',
                          _money(payment['balanceAfter']),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => PaymentReceiptScreen(
                            payment: payment,
                            borrowerName: borrowerName,
                            receipt: receipt,
                            onOpenPdf: previewMode
                                ? null
                                : onOpenPdf,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long),
                    label: const Text('View Receipt Details'),
                  ),
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).popUntil(
                          (route) => route.isFirst,
                    );
                  },
                  icon: const Icon(Icons.dashboard_outlined),
                  label: const Text('Back to Dashboard'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PaymentReceiptScreen extends StatelessWidget {
  final Map<String, dynamic> payment;
  final String borrowerName;
  final Map<String, dynamic>? receipt;
  final VoidCallback? onOpenPdf;

  const PaymentReceiptScreen({
    super.key,
    required this.payment,
    required this.borrowerName,
    this.receipt,
    this.onOpenPdf,
  });

  String _money(Object? value) {
    final amount = num.tryParse(value.toString());
    return amount == null
        ? 'LKR -'
        : 'LKR ${amount.toStringAsFixed(2)}';
  }

  Widget _row(String title, Object? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(color: Colors.black54),
            ),
          ),
          Expanded(
            child: Text(
              '${value ?? '-'}',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Receipt'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                const Icon(
                  Icons.receipt_long_outlined,
                  size: 62,
                  color: Color(0xFF087F5B),
                ),

                const SizedBox(height: 12),

                const Text(
                  'QuickCash',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const Text(
                  'Payment Receipt Details',
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 20),

                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _row(
                          'Receipt Number',
                          receipt?['receiptNumber'],
                        ),
                        _row(
                          'Payment Reference',
                          payment['paymentCode'],
                        ),
                        _row(
                          'Borrower',
                          borrowerName,
                        ),
                        _row(
                          'Loan Code',
                          payment['loanCode'],
                        ),
                        _row(
                          'Collector',
                          payment['collector'],
                        ),
                        _row(
                          'Payment Date',
                          payment['paymentDate'],
                        ),

                        const Divider(),

                        _row(
                          'Amount Paid',
                          _money(payment['amount']),
                        ),

                        _row(
                          'Balance After',
                          _money(payment['balanceAfter']),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                SizedBox(
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: onOpenPdf,
                    icon: const Icon(Icons.picture_as_pdf),
                    label: const Text('View PDF Receipt'),
                  ),
                ),

                if (onOpenPdf == null)
                  const Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      'PDF viewing will be enabled '
                          'after API integration (KAN-132).',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
