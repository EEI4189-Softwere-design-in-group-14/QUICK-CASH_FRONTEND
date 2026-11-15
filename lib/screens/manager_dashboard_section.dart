
import 'package:flutter/material.dart';

import '../widgets/dashboard_metrics.dart';
import 'manager_review_screen.dart';
import 'loan_disbursement_screen.dart';

class ManagerDashboardSection extends StatelessWidget {
  final String token;
  final Map<String, dynamic> data;
  final VoidCallback onRefresh;

  const ManagerDashboardSection({
    super.key,
    required this.token,
    required this.data,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Manager overview',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        DashboardMetrics(
          items: [
            ('Borrowers', data['totalBorrowers']),
            ('Pending borrowers', data['pendingBorrowers']),
            ('Total loans', data['totalLoans']),
            ('Pending loans', data['pendingLoans']),
            ('Active loans', data['activeLoans']),
            ('Completed loans', data['completedLoans']),
            ('Disbursed', formatLkr(data['totalDisbursed'])),
            ('Collected', formatLkr(data['totalCollected'])),
            (
            'Outstanding',
            formatLkr(data['totalOutstanding']),
            ),
          ],
        ),

        const SizedBox(height: 20),

        OutlinedButton.icon(
          onPressed: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => ManagerReviewScreen(
                  token: token,
                  type: ReviewType.loans,
                ),
              ),
            );

            if (changed == true && context.mounted) {
              onRefresh();
            }
          },
          icon: const Icon(Icons.assignment_outlined),
          label: const Text('Review pending loans'),
        ),

        OutlinedButton.icon(
          onPressed: () async {
            final changed = await Navigator.of(context).push<bool>(
              MaterialPageRoute(
                builder: (_) => ManagerReviewScreen(
                  token: token,
                  type: ReviewType.borrowers,
                ),
              ),
            );

            if (changed == true && context.mounted) {
              onRefresh();
            }
          },
          icon: const Icon(Icons.people_outline),
          label: const Text('Review pending borrowers'),
        ),

        const SizedBox(height: 8),

        OutlinedButton.icon(
          onPressed: () {
            _openDisbursement(context);
          },
          icon: const Icon(Icons.lock_outline),
          label: const Text(
            'Disburse approved loan (OTP)',
          ),
        ),
      ],
    );
  }

  // KAN-47: Manual loan selection for local OTP testing.
  Future<void> _openDisbursement(BuildContext context) async {
    final formKey = GlobalKey<FormState>();

    int? selectedId;
    String selectedCode = '';

    final loan = await showDialog<({int id, String code})>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Approved Loan Details'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'For local testing only. Check the loan ID, '
                      'loan code, and APPROVED status in the '
                      'database before continuing.',
                ),

                const SizedBox(height: 12),

                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Loan ID',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final id = int.tryParse(
                      (value ?? '').trim(),
                    );

                    return id != null && id > 0
                        ? null
                        : 'Enter a valid Loan ID';
                  },
                  onSaved: (value) {
                    selectedId = int.parse(value!.trim());
                  },
                ),

                const SizedBox(height: 12),

                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Loan Code',
                  ),
                  validator: (value) =>
                  (value ?? '').trim().isNotEmpty
                      ? null
                      : 'Enter Loan Code',
                  onSaved: (value) {
                    selectedCode = value!.trim();
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;

              formKey.currentState!.save();

              Navigator.pop(
                dialogContext,
                (id: selectedId!, code: selectedCode),
              );
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (loan == null || !context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoanDisbursementScreen(
          token: token,
          loanId: loan.id,
          loanCode: loan.code,
        ),
      ),
    );

    if (context.mounted) {
      onRefresh();
    }
  }
}
