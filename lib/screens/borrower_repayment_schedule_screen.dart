
import 'package:flutter/material.dart';

import '../core/api_client.dart';

const Color _primaryGreen = Color(0xFF087F5B);

String _money(Object? value) {
  final amount = num.tryParse('$value');

  if (amount == null) return 'LKR -';

  return 'LKR ${amount.toStringAsFixed(2)}';
}

String _display(Object? value) {
  if (value == null) return '-';
  return value.toString().replaceAll('_', ' ');
}

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'PAID':
    case 'COMPLETED':
      return Colors.green;
    case 'DUE_SOON':
    case 'PARTIALLY_PAID':
      return Colors.orange;
    case 'OVERDUE':
      return Colors.red;
    case 'ACTIVE':
      return _primaryGreen;
    default:
      return Colors.grey;
  }
}

Widget _detailRow(String label, Object? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
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
            _display(value),
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

// ==========================================
// KAN-128: SELECT BORROWER LOAN
// ==========================================

class BorrowerRepaymentScheduleScreen
    extends StatefulWidget {
  final String token;

  const BorrowerRepaymentScheduleScreen({
    super.key,
    required this.token,
  });

  @override
  State<BorrowerRepaymentScheduleScreen> createState() =>
      _BorrowerRepaymentScheduleScreenState();
}

class _BorrowerRepaymentScheduleScreenState
    extends State<BorrowerRepaymentScheduleScreen> {
  late Future<List<Map<String, dynamic>>> _loans;

  @override
  void initState() {
    super.initState();
    _loans = _loadLoans();
  }

  Future<List<Map<String, dynamic>>> _loadLoans() async {
    final api = ApiClient();

    try {
      final response = await api.request(
        'GET',
        '/borrower/loans',
        token: widget.token,
      );

      if (response is! List) {
        throw const ApiException(
          'Unexpected loans response.',
        );
      }

      return response
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
    } finally {
      api.close();
    }
  }

  Future<void> _refresh() async {
    final next = _loadLoans();

    setState(() {
      _loans = next;
    });

    try {
      await next;
    } catch (_) {
      // FutureBuilder displays the error.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        title: const Text('Repayment Schedule'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _loans,
        builder: (context, snapshot) {
          if (snapshot.connectionState !=
              ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${snapshot.error}'),
                  TextButton(
                    onPressed: _refresh,
                    child: const Text('Try Again'),
                  ),
                ],
              ),
            );
          }

          final loans = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Select a Loan',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),

                const SizedBox(height: 8),

                const Text(
                  'Choose a loan to view its '
                      'repayment summary and installments.',
                ),

                const SizedBox(height: 16),

                if (loans.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'No loans found.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),

                ...loans.map((loan) {
                  final id = loan['loanId'];
                  final code = _display(loan['loanCode']);
                  final status = _display(loan['status']);

                  return Card(
                    child: ListTile(
                      leading: const Icon(
                        Icons.account_balance_wallet,
                        color: _primaryGreen,
                      ),
                      title: Text(code),
                      subtitle: Text(
                        'Status: $status\n'
                            'Outstanding: '
                            '${_money(loan['outstandingBalance'])}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(
                        Icons.chevron_right,
                      ),
                      onTap: id is num
                          ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                _LoanScheduleDetailsScreen(
                                  token: widget.token,
                                  loanId: id.toInt(),
                                  loanCode: code,
                                ),
                          ),
                        );
                      }
                          : null,
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ==========================================
// API DATA FOR SELECTED LOAN
// ==========================================

class _ScheduleData {
  final Map<String, dynamic> summary;
  final List<Map<String, dynamic>> installments;

  const _ScheduleData({
    required this.summary,
    required this.installments,
  });
}

// ==========================================
// REPAYMENT SUMMARY + INSTALLMENTS
// ==========================================

class _LoanScheduleDetailsScreen
    extends StatefulWidget {
  final String token;
  final int loanId;
  final String loanCode;

  const _LoanScheduleDetailsScreen({
    required this.token,
    required this.loanId,
    required this.loanCode,
  });

  @override
  State<_LoanScheduleDetailsScreen> createState() =>
      _LoanScheduleDetailsScreenState();
}

class _LoanScheduleDetailsScreenState
    extends State<_LoanScheduleDetailsScreen> {
  late Future<_ScheduleData> _schedule;

  @override
  void initState() {
    super.initState();
    _schedule = _loadSchedule();
  }

  Future<_ScheduleData> _loadSchedule() async {
    final api = ApiClient();

    try {
      final summaryResponse = await api.request(
        'GET',
        '/borrower/loans/${widget.loanId}/repayment-summary',
        token: widget.token,
      );

      if (summaryResponse is! Map) {
        throw const ApiException(
          'Invalid repayment summary response.',
        );
      }

      final installmentResponse = await api.request(
        'GET',
        '/borrower/loans/${widget.loanId}/installments',
        token: widget.token,
      );

      if (installmentResponse is! List) {
        throw const ApiException(
          'Invalid installment response.',
        );
      }

      final installments = installmentResponse
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();

      installments.sort((a, b) {
        final numberA =
            (a['installmentNumber'] as num?)?.toInt() ?? 0;
        final numberB =
            (b['installmentNumber'] as num?)?.toInt() ?? 0;
        return numberA.compareTo(numberB);
      });

      return _ScheduleData(
        summary: Map<String, dynamic>.from(summaryResponse),
        installments: installments,
      );
    } finally {
      api.close();
    }
  }

  Future<void> _refresh() async {
    final next = _loadSchedule();

    setState(() {
      _schedule = next;
    });

    try {
      await next;
    } catch (_) {
      // FutureBuilder displays the error.
    }
  }

  Widget _summaryCard(Map<String, dynamic> summary) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Repayment Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 14),

            _detailRow(
              'Loan Code',
              summary['loanCode'],
            ),
            _detailRow(
              'Total Principal',
              _money(summary['totalPrincipal']),
            ),
            _detailRow(
              'Total Paid',
              _money(summary['totalPaid']),
            ),
            _detailRow(
              'Outstanding Balance',
              _money(summary['outstandingBalance']),
            ),

            const Divider(height: 24),

            _detailRow(
              'Total Installments',
              summary['totalInstallments'],
            ),
            _detailRow(
              'Paid Installments',
              summary['paidInstallments'],
            ),
            _detailRow(
              'Remaining Installments',
              summary['remainingInstallments'],
            ),

            const Divider(height: 24),

            _detailRow(
              'Next Installment',
              summary['nextInstallmentNumber'] == null
                  ? 'None'
                  : '#${summary['nextInstallmentNumber']}',
            ),
            _detailRow(
              'Next Due Date',
              summary['nextDueDate'] ?? 'None',
            ),
            _detailRow(
              'Next Amount Due',
              _money(summary['nextInstallmentRemaining']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _installmentCard(Map<String, dynamic> item) {
    final status = _display(item['status']);
    final color = _statusColor(status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Installment #${item['installmentNumber'] ?? '-'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    status,
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  backgroundColor:
                  color.withValues(alpha: 0.10),
                  side: BorderSide.none,
                ),
              ],
            ),

            const Divider(),

            _detailRow('Due Date', item['dueDate']),
            _detailRow(
              'Principal',
              _money(item['principalDue']),
            ),
            _detailRow(
              'Interest',
              _money(item['interestDue']),
            ),
            _detailRow(
              'Total Due',
              _money(item['totalDue']),
            ),
            _detailRow(
              'Paid',
              _money(item['paidAmount']),
            ),
            _detailRow(
              'Remaining',
              _money(item['remainingAmount']),
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
        title: const Text('Loan Repayment Schedule'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_ScheduleData>(
        future: _schedule,
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
                      Icons.info_outline,
                      size: 45,
                      color: Colors.orange,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Repayment schedule is unavailable.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'A pending or not-yet-disbursed loan '
                          'may not have a schedule.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    TextButton(
                      onPressed: _refresh,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics:
              const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  widget.loanCode,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),

                const SizedBox(height: 12),

                _summaryCard(data.summary),

                const SizedBox(height: 20),

                Text(
                  'Installment Schedule',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge,
                ),

                const SizedBox(height: 12),

                if (data.installments.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'No installments available.',
                      ),
                    ),
                  ),

                ...data.installments.map(_installmentCard),
              ],
            ),
          );
        },
      ),
    );
  }
}
