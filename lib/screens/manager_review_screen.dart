import 'package:flutter/material.dart';
import '../core/api_client.dart';

enum ReviewType { loans, borrowers }

class ManagerReviewScreen extends StatefulWidget {
  final String token;
  final ReviewType type;
  const ManagerReviewScreen({super.key, required this.token, required this.type});

  @override
  State<ManagerReviewScreen> createState() => _ManagerReviewScreenState();
}

class _ManagerReviewScreenState extends State<ManagerReviewScreen> {
  late Future<dynamic> _items;
  bool _busy = false;
  bool _changed = false;
  String get _resource => widget.type == ReviewType.loans
      ? '/manager/loans' : '/manager/borrowers';

  @override
  void initState() {
    super.initState();
    _items = _load();
  }

  Future<dynamic> _load() async {
    final api = ApiClient();
    try {
      return await api.request('GET', '$_resource/pending', token: widget.token);
    } finally {
      api.close();
    }
  }

  void _reload() => setState(() => _items = _load());

  Future<void> _perform(String path, {Map<String, dynamic>? body}) async {
    setState(() => _busy = true);
    final api = ApiClient();
    try {
      await api.request('PUT', path, token: widget.token, body: body);
      if (!mounted) return;
      _changed = true;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Action completed successfully')),
      );
      _reload();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      api.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reviewBorrower(Map item, bool approve) async {
    final id = item['borrowerId'];
    if (id == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(approve ? 'Approve borrower?' : 'Reject borrower?'),
        content: Text('${item['fullName'] ?? 'This borrower'} will be ${approve ? 'approved' : 'rejected'}. Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Confirm')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _perform('$_resource/$id/${approve ? 'approve' : 'reject'}');
  }

  Future<void> _reviewLoan(Map item, bool approve) async {
    final id = item['loanId'];
    if (id == null) return;
    final amount = TextEditingController(text: '${item['requestedAmount'] ?? ''}');
    final interest = TextEditingController();
    final reason = TextEditingController();
    final formKey = GlobalKey<FormState>();

    try {
      final body = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(approve ? 'Approve loan?' : 'Reject loan?'),
          content: Form(
            key: formKey,
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('${item['loanCode'] ?? 'Loan'} • ${item['purpose'] ?? ''}'),
              const SizedBox(height: 16),
              if (approve) ...[
                TextFormField(
                  controller: amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Approved amount (LKR)'),
                  validator: (value) {
                    final n = double.tryParse((value ?? '').trim());
                    return n != null && n.isFinite && n >= 1 ? null : 'Enter a positive amount';
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: interest,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Interest rate (as required by backend)'),
                  validator: (value) {
                    final n = double.tryParse((value ?? '').trim());
                    return n != null && n.isFinite && n >= 0 ? null : 'Enter a non-negative rate';
                  },
                ),
              ] else
                TextFormField(
                  controller: reason,
                  decoration: const InputDecoration(labelText: 'Rejection reason'),
                  maxLength: 500,
                  maxLines: 2,
                  validator: (value) => (value ?? '').trim().isNotEmpty ? null : 'Reason required',
                ),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            FilledButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                Navigator.pop(context, approve ? {
                  'approvedAmount': double.parse(amount.text.trim()),
                  'interestRate': double.parse(interest.text.trim()),
                } : {'reason': reason.text.trim()});
              },
              child: Text(approve ? 'Approve' : 'Reject'),
            ),
          ],
        ),
      );
      if (body == null || !mounted) return;
      await _perform('$_resource/$id/${approve ? 'approve' : 'reject'}', body: body);
    } finally {
      amount.dispose();
      interest.dispose();
      reason.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final loans = widget.type == ReviewType.loans;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(loans ? 'Pending Loans' : 'Pending Borrowers'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context, _changed),
          ),
          actions: [IconButton(onPressed: _busy ? null : _reload, icon: const Icon(Icons.refresh))],
        ),
        body: FutureBuilder<dynamic>(
          future: _items,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(snapshot.error.toString(), textAlign: TextAlign.center),
                  TextButton(onPressed: _reload, child: const Text('Try again')),
                ]),
              ));
            }
            final items = snapshot.data;
            if (items is! List) return const Center(child: Text('Unexpected response'));
            if (items.isEmpty) return const Center(child: Text('No pending applications'));
            return ListView.builder(
              padding: const EdgeInsets.all(14),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                if (item is! Map) return const SizedBox.shrink();
                return Card(child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('${item[loans ? 'loanCode' : 'fullName'] ?? 'Application'}',
                      style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 7),
                    Text(loans
                      ? 'Amount: LKR ${item['requestedAmount'] ?? '-'}\nPurpose: ${item['purpose'] ?? '-'}\nBorrower: ${item['borrowerCode'] ?? '-'}'
                      : 'Email: ${item['email'] ?? '-'}\nPhone: ${item['phone'] ?? '-'}\nNIC: ${item['nic'] ?? '-'}'),
                    const SizedBox(height: 12),
                    Wrap(spacing: 8, children: [
                      FilledButton.icon(
                        onPressed: _busy ? null : () => loans
                          ? _reviewLoan(item, true) : _reviewBorrower(item, true),
                        icon: const Icon(Icons.check), label: const Text('Approve'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : () => loans
                          ? _reviewLoan(item, false) : _reviewBorrower(item, false),
                        icon: const Icon(Icons.close), label: const Text('Reject'),
                      ),
                    ]),
                  ]),
                ));
              },
            );
          },
        ),
      ),
    );
  }
}
