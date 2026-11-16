
import 'package:flutter/material.dart';

import 'collector_borrower_search_screen.dart';
import 'daily_payment_collection_screen.dart';
import 'payment_success_screen.dart';

class CollectorDashboardSection extends StatelessWidget {
  final String token;

  const CollectorDashboardSection({
    super.key,
    required this.token,
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

        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) =>
                const CollectorBorrowerSearchScreen(),
              ),
            );
          },
          icon: const Icon(Icons.search),
          label: const Text('Search Borrowers'),
        ),

        const SizedBox(height: 12),

        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => DailyPaymentCollectionScreen(
                  token: token,
                ),
              ),
            );
          },
          icon: const Icon(Icons.payments_outlined),
          label: const Text('Collect Daily Payment'),
        ),

        const SizedBox(height: 12),

        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PaymentReceiptLookupScreen(
                  token: token,
                ),
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
