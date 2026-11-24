import 'package:flutter/material.dart';

import 'collector_borrower_search_screen.dart';
import 'daily_payment_collection_screen.dart';
import 'payment_success_screen.dart';
import 'pending_payments_screen.dart';

class CollectorDashboardSection extends StatelessWidget {
  final String token;
  final String collectorId;

  const CollectorDashboardSection({
    super.key,
    required this.token,
    required this.collectorId,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Collector Dashboard\n'
              'Borrower search and payment collection.',
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Search borrowers
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const CollectorBorrowerSearchScreen(),
              ),
            );
          },
          icon: const Icon(Icons.search),
          label: const Text('Search Borrowers'),
        ),

        const SizedBox(height: 12),

        // Daily payment collection
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DailyPaymentCollectionScreen(
                  token: token,
                  collectorId: collectorId,
                ),
              ),
            );
          },
          icon: const Icon(Icons.payments_outlined),
          label: const Text('Collect Daily Payment'),
        ),

        const SizedBox(height: 12),

        // Offline pending payments - KAN-136
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PendingPaymentsScreen(collectorId: collectorId),
              ),
            );
          },
          icon: const Icon(Icons.cloud_upload_outlined),
          label: const Text('Pending Payments'),
        ),

        const SizedBox(height: 12),

        // Find payment receipt
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PaymentReceiptLookupScreen(token: token),
              ),
            );
          },
          icon: const Icon(Icons.receipt_long),
          label: const Text('Find Payment Receipt'),
        ),
      ],
    );
  }
}
