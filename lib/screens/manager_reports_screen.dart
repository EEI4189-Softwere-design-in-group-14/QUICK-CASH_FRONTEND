
import 'package:flutter/material.dart';

import '../core/api_client.dart';

enum _ReportType {
  payments,
  activeLoans,
  borrowers,
}

class ManagerReportsScreen extends StatefulWidget {
  final String token;

  const ManagerReportsScreen({
    super.key,
    required this.token,
  });

  @override
  State<ManagerReportsScreen> createState() =>
      _ManagerReportsScreenState();
}

class _ManagerReportsScreenState
    extends State<ManagerReportsScreen> {
  static const Color primaryGreen = Color(0xFF087F5B);

  _ReportType _selected = _ReportType.payments;
  DateTimeRange? _dateRange;

  late Future<List<Map<String, dynamic>>> _report;

  @override
  void initState() {
    super.initState();
    _report = _loadReport();
  }

  String _date(DateTime date) {
    return '${date.year.toString().padLeft(4, '0')}-'
        '${date.month.toString().padLeft(2, '0')}-'
        '${date.day.toString().padLeft(2, '0')}';
  }

  String _money(Object? value) {
    final amount = num.tryParse('$value');

    if (amount == null) return 'LKR -';

    return 'LKR ${amount.toStringAsFixed(2)}';
  }

  String _display(Object? value) {
    if (value == null || '$value'.isEmpty) return '-';

    return '$value'.replaceAll('_', ' ');
  }

  Future<List<Map<String, dynamic>>> _loadReport() async {
    final api = ApiClient();

    try {
      String path;

      switch (_selected) {
        case _ReportType.payments:
          if (_dateRange == null) {
            path = '/manager/reports/payments';
          } else {
            path = '/manager/reports/payments/filter'
                '?from=${_date(_dateRange!.start)}'
                '&to=${_date(_dateRange!.end)}';
          }
          break;

        case _ReportType.activeLoans:
          path = '/manager/reports/active-loans';
          break;

        case _ReportType.borrowers:
          path = '/manager/reports/borrowers';
          break;
      }

      final result = await api.request(
        'GET',
        path,
        token: widget.token,
      );

      if (result is! List) {
        throw const ApiException(
          'Unexpected report response.',
        );
      }

      return result
          .whereType<Map>()
          .map(
            (item) => Map<String, dynamic>.from(item),
      )
          .toList();
    } finally {
      api.close();
    }
  }

  void _reload() {
    setState(() {
      _report = _loadReport();
    });
  }

  void _selectReport(_ReportType type) {
    if (_selected == type) return;

    setState(() {
      _selected = type;
      _report = _loadReport();
    });
  }

  Future<void> _chooseDateRange() async {
    final result = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
      helpText: 'Select Payment Report Dates',
    );

    if (!mounted || result == null) return;

    setState(() {
      _dateRange = result;
      _report = _loadReport();
    });
  }

  Widget _detail(String label, Object? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.black54,
              ),
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

  Widget _paymentCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _display(item['paymentCode']),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _money(item['amount']),
              style: const TextStyle(
                color: primaryGreen,
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            _detail('Loan Code', item['loanCode']),
            _detail('Collector', item['collector']),
            _detail('Status', item['status']),
            _detail('Source', item['source']),
            _detail('Payment Date', item['paymentDate']),
          ],
        ),
      ),
    );
  }

  Widget _loanCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _detail('Loan Code', item['loanCode']),
            _detail('Borrower Code', item['borrowerCode']),
            _detail(
              'Approved Amount',
              _money(item['approvedAmount']),
            ),
            _detail(
              'Outstanding',
              _money(item['outstandingBalance']),
            ),
            _detail('Purpose', item['purpose']),
            _detail('Status', item['status']),
          ],
        ),
      ),
    );
  }

  Widget _borrowerCard(Map<String, dynamic> item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _detail('Borrower Code', item['borrowerCode']),
            _detail('Name', item['fullName']),
            _detail('Phone', item['phone']),
            _detail('Status', item['status']),
          ],
        ),
      ),
    );
  }

  Widget _buildResults(
      List<Map<String, dynamic>> items,
      ) {
    if (items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Center(
            child: Text('No report records found.'),
          ),
        ),
      );
    }

    num acceptedTotal = 0;

    if (_selected == _ReportType.payments) {
      for (final payment in items) {
        if (payment['status'] == 'ACCEPTED') {
          acceptedTotal +=
              num.tryParse('${payment['amount']}') ?? 0;
        }
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Records: ${items.length}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (_selected == _ReportType.payments) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Accepted Payment Total: '
                        '${_money(acceptedTotal)}',
                    style: const TextStyle(
                      color: primaryGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        ...items.map((item) {
          switch (_selected) {
            case _ReportType.payments:
              return _paymentCard(item);

            case _ReportType.activeLoans:
              return _loanCard(item);

            case _ReportType.borrowers:
              return _borrowerCard(item);
          }
        }),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        title: const Text('Manager Reports'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final next = _loadReport();

          setState(() {
            _report = next;
          });

          try {
            await next;
          } catch (_) {
            // FutureBuilder displays the error.
          }
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Business Reports',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                ChoiceChip(
                  label: const Text('Payments'),
                  selected:
                  _selected == _ReportType.payments,
                  onSelected: (_) {
                    _selectReport(_ReportType.payments);
                  },
                ),
                ChoiceChip(
                  label: const Text('Active Loans'),
                  selected:
                  _selected == _ReportType.activeLoans,
                  onSelected: (_) {
                    _selectReport(_ReportType.activeLoans);
                  },
                ),
                ChoiceChip(
                  label: const Text('Borrowers'),
                  selected:
                  _selected == _ReportType.borrowers,
                  onSelected: (_) {
                    _selectReport(_ReportType.borrowers);
                  },
                ),
              ],
            ),

            const SizedBox(height: 12),

            if (_selected == _ReportType.payments)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _chooseDateRange,
                        icon: const Icon(Icons.date_range),
                        label: const Text(
                          'Filter Payments by Date',
                        ),
                      ),

                      if (_dateRange != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${_date(_dateRange!.start)} '
                              'to ${_date(_dateRange!.end)}',
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _dateRange = null;
                              _report = _loadReport();
                            });
                          },
                          child: const Text('Clear Filter'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 16),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: _report,
              builder: (context, snapshot) {
                if (snapshot.connectionState !=
                    ConnectionState.done) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            '${snapshot.error}',
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: _reload,
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return _buildResults(snapshot.data!);
              },
            ),
          ],
        ),
      ),
    );
  }
}
