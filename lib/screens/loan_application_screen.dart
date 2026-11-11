import 'package:flutter/material.dart';
import '../core/api_client.dart';

class LoanApplicationScreen extends StatefulWidget {
  final String token;
  const LoanApplicationScreen({super.key, required this.token});

  @override
  State<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends State<LoanApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amount = TextEditingController();
  final _purpose = TextEditingController();
  final _months = TextEditingController();
  final _guarantorName = TextEditingController();
  final _guarantorNic = TextEditingController();
  final _guarantorPhone = TextEditingController();
  final _guarantorAddress = TextEditingController();
  final _guarantorOccupation = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [
      _amount, _purpose, _months, _guarantorName, _guarantorNic,
      _guarantorPhone, _guarantorAddress, _guarantorOccupation,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) => (value ?? '').trim().isEmpty
      ? 'This field is required' : null;

  Widget _input(String title, TextEditingController controller, {
    TextInputType? type, String? Function(String?)? validate, int lines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        enabled: !_saving,
        keyboardType: type,
        maxLines: lines,
        decoration: InputDecoration(labelText: title),
        validator: validate ?? _required,
      ),
    );
  }

  Future<void> _apply() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    final api = ApiClient();
    try {
      await api.request('POST', '/borrower/loans', token: widget.token, body: {
        'requestedAmount': double.parse(_amount.text.trim()),
        'purpose': _purpose.text.trim(),
        'repaymentMonths': int.parse(_months.text.trim()),
        'guarantorFullName': _guarantorName.text.trim(),
        'guarantorNic': _guarantorNic.text.trim().toUpperCase(),
        'guarantorPhone': _guarantorPhone.text.trim(),
        'guarantorAddress': _guarantorAddress.text.trim(),
        'guarantorOccupation': _guarantorOccupation.text.trim(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Loan application submitted for review.')),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      api.close();
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Apply for a Loan')),
      body: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 550),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Loan information', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _input('Requested amount (LKR) *', _amount,
                type: const TextInputType.numberWithOptions(decimal: true),
                validate: (v) {
                  final n = double.tryParse((v ?? '').trim());
                  return n != null && n.isFinite && n >= 1 ? null : 'Enter an amount of at least LKR 1';
                }),
              _input('Loan purpose *', _purpose, lines: 2),
              _input('Repayment period (months) *', _months,
                type: TextInputType.number,
                validate: (v) {
                  final n = int.tryParse((v ?? '').trim());
                  return n != null && n > 0 ? null : 'Enter a whole number of months';
                }),
              const SizedBox(height: 14),
              Text('Guarantor details', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 16),
              _input('Full name *', _guarantorName),
              _input('NIC *', _guarantorNic,
                validate: (v) => RegExp(r'^(\d{12}|\d{9}[VvXx])$').hasMatch((v ?? '').trim())
                    ? null : 'Enter a valid Sri Lankan NIC'),
              _input('Phone *', _guarantorPhone, type: TextInputType.phone,
                validate: (v) => RegExp(r'^(?:\+94|0)\d{9}$').hasMatch((v ?? '').trim())
                    ? null : 'Enter a valid Sri Lankan phone number'),
              _input('Address *', _guarantorAddress, lines: 2),
              _input('Occupation (optional)', _guarantorOccupation,
                validate: (_) => null),
              if (_error != null) ...[
                Text(_error!, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
              ],
              ElevatedButton(
                onPressed: _saving ? null : _apply,
                child: _saving
                    ? const SizedBox(height: 22, width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Submit application'),
              ),
            ]),
          ),
        ),
      )),
    );
  }
}
