
import 'package:flutter/material.dart';

import '../core/api_client.dart';
import 'borrower_loan_details_screen.dart';

class LoansScreen extends StatefulWidget {
  final String title;
  final String path;
  final String token;

  const LoansScreen({
    super.key,
    required this.title,
    required this.path,
    required this.token,
  });

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  late Future<dynamic> _items;

  @override
  void initState() {
    super.initState();
    _items = _load();
  }

  Future<dynamic> _load() async {
    final api = ApiClient();

    try {
      return await api.request(
        'GET',
        widget.path,
        token: widget.token,
      );
    } finally {
      api.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: FutureBuilder<dynamic>(
        future: _items,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text('${snapshot.error}'),
              ),
            );
          }

          final result = snapshot.data;

          if (result is! List) {
            return const Center(
              child: Text('Unexpected response from server'),
            );
          }

          if (result.isEmpty) {
            return const Center(
              child: Text('No loans found'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: result.length,
            itemBuilder: (context, index) {
              final item = result[index];

              if (item is! Map) {
                return const SizedBox.shrink();
              }

              return Card(
                child: ListTile(
                  onTap: () {
                    final id = item['loanId'];

                    if (id is! num) return;

                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BorrowerLoanDetailsScreen(
                          token: widget.token,
                          loanId: id.toInt(),
                        ),
                      ),
                    );
                  },
                  title: Text(
                    '${item['loanCode'] ?? 'Loan #${item['loanId'] ?? '-'}'}',
                  ),
                  subtitle: Text(
                    '${item['purpose'] ?? 'No purpose'}\n'
                        'Status: ${item['status'] ?? '-'}',
                  ),
                  isThreeLine: true,
                  trailing: Text(
                    'LKR ${item['requestedAmount'] ?? '-'}',
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
