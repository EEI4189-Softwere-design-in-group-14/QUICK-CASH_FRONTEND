import 'package:flutter/material.dart';
import '../core/api_client.dart';
import 'login_screen.dart';
import 'loan_application_screen.dart';
import 'manager_review_screen.dart';
import 'loan_disbursement_screen.dart';
import 'borrower_loan_details_screen.dart';
class HomeScreen extends StatefulWidget {
  final UserSession session;
  const HomeScreen({super.key, required this.session});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<dynamic> _dashboard;
  String? get _dashboardPath => switch (widget.session.role) {
    'MANAGER' || 'OWNER' => '/manager/dashboard',
    'BORROWER' => '/borrower/dashboard',
    _ => null,
  };

  Future<dynamic> _fetchDashboard() async {
    if (_dashboardPath == null) { return null; }
    final api = ApiClient();
    try { return await api.request('GET', _dashboardPath!, token: widget.session.token); }
    finally { api.close(); }
  }

  @override
  void initState() { super.initState(); _dashboard = _fetchDashboard(); }

  void _refresh() {
    setState(() {
      _dashboard = _fetchDashboard();
    });
  }

  void _logout() => Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false,
  );

  @override
  Widget build(BuildContext context) {
    final role = widget.session.role;
    return Scaffold(
      appBar: AppBar(
        title: const Text('QuickCash', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(tooltip: 'Refresh', onPressed: _refresh, icon: const Icon(Icons.refresh)),
          IconButton(tooltip: 'Sign out', onPressed: _logout, icon: const Icon(Icons.logout)),
        ],
      ),
      body: RefreshIndicator(onRefresh: () async { _refresh(); await _dashboard; }, child:
      ListView(padding: const EdgeInsets.all(20), children: [
        Text('Hello, ${widget.session.name}', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 5),
        Text('$role • ${widget.session.email}', style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 25),
        if (_dashboardPath == null)
          const Card(child: Padding(padding: EdgeInsets.all(20), child: Text('Collector dashboard: the main backend branch has no dedicated collector dashboard endpoint yet. Payment-related screens will be connected in the next module.')))
        else FutureBuilder<dynamic>(future: _dashboard, builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) { return const Center(child: Padding(padding: EdgeInsets.all(35), child: CircularProgressIndicator())); }
          if (snapshot.hasError) {
            return Card(child: Padding(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Dashboard could not be loaded', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8), Text('${snapshot.error}'),
              const SizedBox(height: 8), TextButton(onPressed: _refresh, child: const Text('Try again')),
            ])));
          }
          final data = snapshot.data;
          if (data is! Map<String, dynamic>) { return const Text('Unexpected dashboard response'); }
          if (role == 'BORROWER') { return _borrowerDashboard(context, data); }
          return _managerDashboard(context, data);
        }),
      ]),
      ),
    );
  }

  Widget _managerDashboard(BuildContext context, Map<String, dynamic> data) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text('Manager overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
    const SizedBox(height: 12),
    _metrics([
      ('Borrowers', data['totalBorrowers']), ('Pending borrowers', data['pendingBorrowers']),
      ('Total loans', data['totalLoans']), ('Pending loans', data['pendingLoans']),
      ('Active loans', data['activeLoans']), ('Completed loans', data['completedLoans']),
      ('Disbursed', _money(data['totalDisbursed'])), ('Collected', _money(data['totalCollected'])),
      ('Outstanding', _money(data['totalOutstanding'])),
    ]),
    const SizedBox(height: 20),
    OutlinedButton.icon(onPressed: () async {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => ManagerReviewScreen(token: widget.session.token, type: ReviewType.loans)),
      );
      if (changed == true && mounted) _refresh();
    }, icon: const Icon(Icons.assignment_outlined), label: const Text('Review pending loans')),
    OutlinedButton.icon(onPressed: () async {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => ManagerReviewScreen(token: widget.session.token, type: ReviewType.borrowers)),
      );
      if (changed == true && mounted) _refresh();
    }, icon: const Icon(Icons.people_outline), label: const Text('Review pending borrowers')),
    const SizedBox(height: 8),
    OutlinedButton.icon(
      onPressed: _openDisbursement,
      icon: const Icon(Icons.lock_outline),
      label: const Text('Disburse approved loan (OTP)'),
    ),
  ]);

  // KAN-47: Temporary manual loan selection for local OTP testing.
  // Loan ID and code must be checked in the database before proceeding.
  Future<void> _openDisbursement() async {
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
                  'For local testing only. Check the loan ID, loan code, '
                      'and APPROVED status in the database before continuing.',
                ),
                const SizedBox(height: 12),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Loan ID'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    final id = int.tryParse((value ?? '').trim());
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
                  decoration: const InputDecoration(labelText: 'Loan Code'),
                  validator: (value) => (value ?? '').trim().isNotEmpty
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
              Navigator.pop(dialogContext,
                  (id: selectedId!, code: selectedCode));
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );

    if (loan == null || !mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => LoanDisbursementScreen(
          token: widget.session.token,
          loanId: loan.id,
          loanCode: loan.code,
        ),
      ),
    );

    if (mounted) _refresh();
  }

  Widget _borrowerDashboard(BuildContext context, Map<String, dynamic> data) {
    final loans = data['loans'];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('My loan overview', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      _metrics([
        ('Total loans', data['totalLoans']), ('Active loans', data['activeLoans']),
        ('Principal', _money(data['activePrincipal'])), ('Paid', _money(data['activePaid'])),
        ('Outstanding', _money(data['activeOutstanding'])), ('Unread alerts', data['unreadNotifications']),
      ]),
      const SizedBox(height: 20),
      if (loans is List && loans.isNotEmpty) ...[
        Text('Active loan cards', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        ...loans.whereType<Map>().map((loan) => Card(child: ListTile(
          title: Text('${loan['loanCode'] ?? 'Loan'}'),
          subtitle: Text('Status: ${loan['status'] ?? '-'} • Next due: ${loan['nextDueDate'] ?? '-'}'),
          trailing: Text(_money(loan['outstandingPrincipal'])),
        ))),
      ],
      OutlinedButton.icon(onPressed: () => _openLoans('/borrower/loans', 'My loans'), icon: const Icon(Icons.receipt_long_outlined), label: const Text('View all loans')),
      const SizedBox(height: 8),
      ElevatedButton.icon(onPressed: () async {
        final saved = await Navigator.of(context).push<bool>(
          MaterialPageRoute(builder: (_) => LoanApplicationScreen(token: widget.session.token)),
        );
        if (saved == true && mounted) _refresh();
      }, icon: const Icon(Icons.add_circle_outline), label: const Text('Apply for a new loan')),
    ]);
  }

  Widget _metrics(List<(String, Object?)> items) => LayoutBuilder(builder: (context, constraints) {
    final width = constraints.maxWidth;
    final count = width > 850 ? 3 : 2;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: count, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: width > 380 ? 1.9 : 1.45),
      itemBuilder: (_, index) {
        final item = items[index];
        return Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(item.$1, style: const TextStyle(color: Colors.black54, fontSize: 12), maxLines: 2),
          const SizedBox(height: 8),
          FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerLeft, child: Text('${item.$2 ?? '—'}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 19))),
        ])));
      },
    );
  });

  String _money(Object? value) => 'LKR ${value ?? '0'}';

  void _openLoans(String path, String title) => Navigator.push(context, MaterialPageRoute(
    builder: (_) => LoansScreen(title: title, path: path, token: widget.session.token),
  ));
}

class LoansScreen extends StatefulWidget {
  final String title, path, token;
  const LoansScreen({super.key, required this.title, required this.path, required this.token});
  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> {
  late Future<dynamic> _items;
  Future<dynamic> _load() async {
    final api = ApiClient();
    try { return await api.request('GET', widget.path, token: widget.token); }
    finally { api.close(); }
  }
  @override
  void initState() { super.initState(); _items = _load(); }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(widget.title)),
    body: FutureBuilder<dynamic>(future: _items, builder: (_, snapshot) {
      if (!snapshot.hasData && !snapshot.hasError) { return const Center(child: CircularProgressIndicator()); }
      if (snapshot.hasError) { return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text('${snapshot.error}'))); }
      final result = snapshot.data;
      if (result is! List) { return const Center(child: Text('Unexpected response from server')); }
      if (result.isEmpty) { return const Center(child: Text('No loans found')); }
      return ListView.builder(padding: const EdgeInsets.all(12), itemCount: result.length, itemBuilder: (_, index) {
        final item = result[index];
        if (item is! Map) { return const SizedBox.shrink(); }
        return Card(child: ListTile(
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
          title: Text('${item['loanCode'] ?? 'Loan #${item['loanId'] ?? '-'}'}'),
          subtitle: Text('${item['purpose'] ?? 'No purpose'}\nStatus: ${item['status'] ?? '-'}'),
          isThreeLine: true,
          trailing: Text('LKR ${item['requestedAmount'] ?? '-'}'),
        ));
      });
    }),
  );
}
