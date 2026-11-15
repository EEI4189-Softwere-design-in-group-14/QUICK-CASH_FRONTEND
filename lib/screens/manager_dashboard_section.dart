
import 'package:flutter/material.dart';

import '../widgets/dashboard_metrics.dart';
import 'manager_review_screen.dart';
import 'loan_disbursement_screen.dart';
import 'manager_reports_screen.dart';
import 'manager_reconciliation_screen.dart';

// ==========================================
// QUICKCASH - MANAGER DASHBOARD
// KAN-129: Reports and Bank Reconciliation
// ==========================================

class ManagerDashboardSection extends StatelessWidget {
  final String token;
  final Map<String, dynamic> data;
  final VoidCallback onRefresh;
  final bool canReconcile;

  const ManagerDashboardSection({
    super.key,
    required this.token,
    required this.data,
    required this.onRefresh,
    this.canReconcile = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ======================================
        // MANAGER OVERVIEW
        // ======================================

        Text(
          'Manager overview',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        // ======================================
        // DASHBOARD METRICS
        // ======================================

        DashboardMetrics(
          items: [
            ('Borrowers', data['totalBorrowers']),
            ('Pending borrowers', data['pendingBorrowers']),
            ('Total loans', data['totalLoans']),
            ('Pending loans', data['pendingLoans']),
            ('Active loans', data['activeLoans']),
            ('Completed loans', data['completedLoans']),
            (
            'Disbursed',
            formatLkr(data['totalDisbursed']),
            ),
            (
            'Collected',
            formatLkr(data['totalCollected']),
            ),
            (
            'Outstanding',
            formatLkr(data['totalOutstanding']),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ======================================
        // REVIEW PENDING LOANS
        // ======================================

        OutlinedButton.icon(
          onPressed: () async {
            final changed =
            await Navigator.of(context).push<bool>(
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
          icon: const Icon(
            Icons.assignment_outlined,
          ),
          label: const Text(
            'Review pending loans',
          ),
        ),

        const SizedBox(height: 12),

        // ======================================
        // REVIEW PENDING BORROWERS
        // ======================================

        OutlinedButton.icon(
          onPressed: () async {
            final changed =
            await Navigator.of(context).push<bool>(
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
          icon: const Icon(
            Icons.people_outline,
          ),
          label: const Text(
            'Review pending borrowers',
          ),
        ),

        const SizedBox(height: 12),

        // ======================================
        // KAN-47: LOAN DISBURSEMENT WITH OTP
        // ======================================

        OutlinedButton.icon(
          onPressed: () {
            _openDisbursement(context);
          },
          icon: const Icon(
            Icons.lock_outline,
          ),
          label: const Text(
            'Disburse approved loan (OTP)',
          ),
        ),

        const SizedBox(height: 20),

        // ======================================
        // KAN-129: MANAGER REPORTS
        // ======================================

        Text(
          'Reports & Reconciliation',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 12),

        // VIEW MANAGER REPORTS

        OutlinedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => ManagerReportsScreen(
                  token: token,
                ),
              ),
            );
          },
          icon: const Icon(
            Icons.bar_chart,
          ),
          label: const Text(
            'View Manager Reports',
          ),
        ),

        const SizedBox(height: 12),

        // ======================================
        // KAN-129: BANK RECONCILIATION
        // Only MANAGER can access this feature.
        // ======================================

        if (canReconcile)
          OutlinedButton.icon(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ManagerReconciliationScreen(
                        token: token,
                      ),
                ),
              );
            },
            icon: const Icon(
              Icons.account_balance,
            ),
            label: const Text(
              'Bank Reconciliation',
            ),
          ),

        const SizedBox(height: 20),
      ],
    );
  }

  // ==========================================
  // KAN-47: MANAGER LOAN DISBURSEMENT
  // ==========================================

  // Temporary manual loan selection
  // for local OTP testing.

  Future<void> _openDisbursement(
      BuildContext context,
      ) async {
    final formKey = GlobalKey<FormState>();

    int? selectedId;
    String selectedCode = '';

    // ======================================
    // SELECT APPROVED LOAN
    // ======================================

    final loan =
    await showDialog<({int id, String code})>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'Approved Loan Details',
        ),

        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'For local testing only. '
                      'Check the loan ID, loan code, '
                      'and APPROVED status in the '
                      'database before continuing.',
                ),

                const SizedBox(height: 12),

                // LOAN ID

                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Loan ID',
                    border: OutlineInputBorder(),
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
                    selectedId = int.parse(
                      value!.trim(),
                    );
                  },
                ),

                const SizedBox(height: 12),

                // LOAN CODE

                TextFormField(
                  decoration: const InputDecoration(
                    labelText: 'Loan Code',
                    border: OutlineInputBorder(),
                  ),

                  validator: (value) {
                    if ((value ?? '').trim().isEmpty) {
                      return 'Enter Loan Code';
                    }

                    return null;
                  },

                  onSaved: (value) {
                    selectedCode = value!.trim();
                  },
                ),
              ],
            ),
          ),
        ),

        // ======================================
        // DIALOG BUTTONS
        // ======================================

        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Cancel',
            ),
          ),

          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) {
                return;
              }

              formKey.currentState!.save();

              Navigator.pop(
                dialogContext,
                (
                id: selectedId!,
                code: selectedCode,
                ),
              );
            },
            child: const Text(
              'Continue',
            ),
          ),
        ],
      ),
    );

    // ======================================
    // LOAN SELECTION CANCELLED
    // ======================================

    if (loan == null || !context.mounted) {
      return;
    }

    // ======================================
    // OPEN LOAN DISBURSEMENT SCREEN
    // ======================================

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoanDisbursementScreen(
          token: token,
          loanId: loan.id,
          loanCode: loan.code,
        ),
      ),
    );

    // ======================================
    // REFRESH MANAGER DASHBOARD
    // ======================================

    if (context.mounted) {
      onRefresh();
    }
  }
}
