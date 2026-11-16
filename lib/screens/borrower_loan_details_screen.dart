
import 'package:flutter/material.dart';
import '../core/api_client.dart';

class BorrowerLoanDetailsScreen extends StatefulWidget {
  final String token;
  final int loanId;

  const BorrowerLoanDetailsScreen({
    super.key,
    required this.token,
    required this.loanId,
  });

  @override
  State<BorrowerLoanDetailsScreen> createState() =>
      _BorrowerLoanDetailsScreenState();
}

class _BorrowerLoanDetailsScreenState
    extends State<BorrowerLoanDetailsScreen> {
  late Future<Map<String, dynamic>> _details;

  @override
  void initState() {
    super.initState();
    _details = _loadDetails();
  }

  Future<Map<String, dynamic>> _loadDetails() async {
    final api = ApiClient();

    try {
      final response = await api.request(
        'GET',
        '/borrower/loans/${widget.loanId}',
        token: widget.token,
      );

      if (response is! Map) {
        throw const ApiException(
          'Unexpected loan details response.',
        );
      }

      return Map<String, dynamic>.from(response);
    } finally {
      api.close();
    }
  }

  Future<void> _refresh() async {
    final next = _loadDetails();

    setState(() {
      _details = next;
    });

    try {
      await next;
    } catch (_) {
      // FutureBuilder displays the error.
    }
  }

  String _money(Object? value) {
    if (value == null) return 'LKR -';

    final amount = num.tryParse(value.toString());

    if (amount == null) {
      return 'LKR $value';
    }

    return 'LKR ${amount.toStringAsFixed(2)}';
  }

  String _date(Object? value) {
    if (value == null) return '-';

    final text = value.toString();

    if (text.isEmpty) return '-';

    return text.split('T').first;
  }

  String _display(Object? value) {
    if (value == null || value.toString().isEmpty) {
      return '-';
    }

    return value.toString().replaceAll('_', ' ');
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'ACTIVE':
      case 'PAID':
      case 'COMPLETED':
        return Colors.green;
      case 'APPROVED':
        return Colors.teal;
      case 'PENDING':
      case 'DUE_SOON':
        return Colors.orange;
      case 'REJECTED':
      case 'OVERDUE':
        return Colors.red;
      case 'PARTIALLY_PAID':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Widget _statusChip(String status) {
    final color = _statusColor(status);

    return Chip(
      avatar: Icon(
        Icons.circle,
        color: color,
        size: 12,
      ),
      label: Text(
        _display(status),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
      backgroundColor: color.withValues(alpha: 0.10),
      side: BorderSide.none,
    );
  }

  Widget _detailRow(String title, Object? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              _display(value),
              textAlign: TextAlign.right,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountCard(
      String title,
      Object? amount,
      IconData icon,
      ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              icon,
              color: const Color(0xFF087F5B),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                _money(amount),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 17,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _installmentCard(Map installment) {
    final number = installment['installmentNumber'];
    final status = _display(installment['status']);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Installment #${number ?? '-'}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _statusChip(status),
              ],
            ),
            const Divider(),
            _detailRow(
              'Due Date',
              _date(installment['dueDate']),
            ),
            _detailRow(
              'Principal Due',
              _money(installment['principalDue']),
            ),
            _detailRow(
              'Amount Paid',
              _money(installment['paidAmount']),
            ),
            _detailRow(
              'Remaining',
              _money(installment['remainingAmount']),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoanDetails(
      Map<String, dynamic> data,
      ) {
    final rawLoan = data['loan'];

    if (rawLoan is! Map) {
      return const Center(
        child: Text('Loan details are not available.'),
      );
    }

    final loan = rawLoan;
    final status = _display(loan['status']);
    final rawInstallments = data['installments'];

    final installments = rawInstallments is List
        ? rawInstallments.whereType<Map>().toList()
        : <Map>[];

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  const CircleAvatar(
                    radius: 32,
                    backgroundColor: Color(0xFFE0F5EA),
                    child: Icon(
                      Icons.account_balance_wallet,
                      size: 34,
                      color: Color(0xFF087F5B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _display(loan['loanCode']),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _statusChip(status),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Text(
            'Loan Summary',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              Expanded(
                child: _amountCard(
                  'Requested Amount',
                  loan['requestedAmount'],
                  Icons.request_page_outlined,
                ),
              ),
              Expanded(
                child: _amountCard(
                  'Approved Amount',
                  loan['approvedAmount'],
                  Icons.check_circle_outline,
                ),
              ),
            ],
          ),

          Row(
            children: [
              Expanded(
                child: _amountCard(
                  'Outstanding Balance',
                  loan['outstandingBalance'],
                  Icons.account_balance_wallet_outlined,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Text(
            'Loan Information',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 8),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _detailRow(
                    'Loan Code',
                    loan['loanCode'],
                  ),
                  _detailRow(
                    'Purpose',
                    loan['purpose'],
                  ),
                  _detailRow(
                    'Loan Status',
                    status,
                  ),
                  _detailRow(
                    'Repayment Months',
                    data['repaymentMonths'],
                  ),
                  _detailRow(
                    'Interest Rate',
                    data['interestRate'] == null
                        ? null
                        : '${data['interestRate']}%',
                  ),
                  _detailRow(
                    'Application Date',
                    _date(loan['applicationDate']),
                  ),
                  _detailRow(
                    'Reviewed Date',
                    _date(data['reviewedAt']),
                  ),
                ],
              ),
            ),
          ),

          if (status == 'REJECTED' &&
              loan['rejectionReason'] != null) ...[
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Rejection Reason',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _display(loan['rejectionReason']),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 18),

          Text(
            'Repayment Schedule',
            style: Theme.of(context).textTheme.titleLarge,
          ),

          const SizedBox(height: 8),

          if (installments.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No repayment installments available yet.',
                ),
              ),
            )
          else
            ...installments.map(_installmentCard),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Loan Details'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _details,
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
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 45,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
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

          final data = snapshot.data;

          if (data == null) {
            return const Center(
              child: Text('No loan details found.'),
            );
          }

          return _buildLoanDetails(data);
        },
      ),
    );
  }
}
