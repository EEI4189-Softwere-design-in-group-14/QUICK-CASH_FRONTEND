
import 'package:flutter/material.dart';

import '../widgets/dashboard_metrics.dart';
import 'borrower_loans_screen.dart';
import 'loan_application_screen.dart';
import 'borrower_payment_history_screen.dart';
import 'borrower_repayment_schedule_screen.dart';

class BorrowerDashboardSection extends StatelessWidget {
  final String token;
  final Map<String, dynamic> data;
  final VoidCallback onRefresh;

  const BorrowerDashboardSection({
    super.key,
    required this.token,
    required this.data,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final loans = data['loans'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My loan overview',
          style: Theme.of(context).textTheme.titleLarge,
        ),

        const SizedBox(height: 12),

        DashboardMetrics(
          items: [
            ('Total loans', data['totalLoans']),
            ('Active loans', data['activeLoans']),
            ('Principal', formatLkr(data['activePrincipal'])),
            ('Paid', formatLkr(data['activePaid'])),
            (
            'Outstanding',
            formatLkr(data['activeOutstanding']),
            ),
            (
            'Unread alerts',
            data['unreadNotifications'],
            ),
          ],
        ),

        const SizedBox(height: 20),

        if (loans is List && loans.isNotEmpty) ...[
          Text(
            'Active loan cards',
            style: Theme.of(context).textTheme.titleMedium,
          ),

          const SizedBox(height: 8),

          ...loans.whereType<Map>().map(
                (loan) => Card(
              child: ListTile(
                title: Text(
                  '${loan['loanCode'] ?? 'Loan'}',
                ),
                subtitle: Text(
                  'Status: ${loan['status'] ?? '-'} '
                      '• Next due: ${loan['nextDueDate'] ?? '-'}',
                ),
                trailing: Text(
                  formatLkr(loan['outstandingPrincipal']),
                ),
              ),
            ),
          ),
        ],

        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => LoansScreen(
                  title: 'My loans',
                  path: '/borrower/loans',
                  token: token,
                ),
              ),
            );
          },
          icon: const Icon(Icons.receipt_long_outlined),
          label: const Text('View all loans'),
        ),

        const SizedBox(height: 12),

        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BorrowerPaymentHistoryScreen(
                  token: token,
                ),
              ),
            );
          },
          icon: const Icon(Icons.history),
          label: const Text('View Payment History'),
        ),


        const SizedBox(height: 8),

        ElevatedButton.icon(
          onPressed: () async {
            final saved = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => LoanApplicationScreen(
                  token: token,
                ),
              ),
            );

            if (saved == true && context.mounted) {
              onRefresh();
            }
          },
          icon: const Icon(Icons.add_circle_outline),
          label: const Text('Apply for a new loan'),
        ),
        const SizedBox(height: 12),

// KAN-128: Borrower Repayment Schedule
        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BorrowerRepaymentScheduleScreen(
                  token: token,
                ),
              ),
            );
          },
          icon: const Icon(Icons.calendar_month_outlined),
          label: const Text('View Repayment Schedule'),
        ),

        const SizedBox(height: 12),

      ],
    );
  }
}
