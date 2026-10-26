import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class LoanApplicationScreen extends StatefulWidget {
  const LoanApplicationScreen({super.key});

  @override
  State<LoanApplicationScreen> createState() => _LoanApplicationScreenState();
}

class _LoanApplicationScreenState extends State<LoanApplicationScreen> {
  static const Color primary = Color(0xFF168B62);

  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _purposeController = TextEditingController();
  final _termController = TextEditingController(text: '12');
  final _incomeController = TextEditingController();
  final _employmentController = TextEditingController();
  final ApiService _api = ApiService();

  String _loanType = 'Personal Loan';
  bool _submitting = false;
  bool _termsAccepted = false;

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _validateAmount(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null || !amount.isFinite) return 'Enter a valid amount';
    if (amount < 1000) return 'Minimum loan amount is Rs. 1,000';
    if (amount > 10000000) return 'Maximum amount is Rs. 10,000,000';
    return null;
  }

  Future<void> _submitApplication() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please confirm the declaration first.')),
      );
      return;
    }

    final amount = double.tryParse(_amountController.text.trim());
    final term = int.tryParse(_termController.text.trim());
    final income = double.tryParse(_incomeController.text.trim());
    if (amount == null || term == null || income == null) return;

    setState(() => _submitting = true);
    try {
      // Endpoint and request fields should match the backend contract.
      final response = await _api.post(
        '/api/loans/applications',
        {
          'loanType': _loanType,
          'requestedAmount': amount,
          'purpose': _purposeController.text.trim(),
          'termMonths': term,
          'monthlyIncome': income,
          'employmentDetails': _employmentController.text.trim(),
        },
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Application submitted'),
          content: Text(
            response is Map && response['message'] != null
                ? response['message'].toString()
                : 'Your loan application has been submitted for review.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message), backgroundColor: Colors.red),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not submit the application. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _purposeController.dispose();
    _termController.dispose();
    _incomeController.dispose();
    _employmentController.dispose();
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF7),
      appBar: AppBar(
        title: const Text('Loan Application'),
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F4EB),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline, color: primary, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Complete the details below to request a loan. '
                            'Submitting an application does not guarantee approval.',
                            style: TextStyle(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Loan details',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _loanType,
                    decoration: _decoration('Loan type', Icons.category_outlined),
                    items: const [
                      DropdownMenuItem(
                        value: 'Personal Loan',
                        child: Text('Personal Loan'),
                      ),
                      DropdownMenuItem(
                        value: 'Business Loan',
                        child: Text('Business Loan'),
                      ),
                      DropdownMenuItem(
                        value: 'Education Loan',
                        child: Text('Education Loan'),
                      ),
                      DropdownMenuItem(
                        value: 'Emergency Loan',
                        child: Text('Emergency Loan'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _loanType = value);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: _validateAmount,
                    decoration: _decoration('Requested amount (LKR)', Icons.payments_outlined),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _termController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      final months = int.tryParse(value?.trim() ?? '');
                      if (months == null || months < 1 || months > 120) {
                        return 'Enter a term between 1 and 120 months';
                      }
                      return null;
                    },
                    decoration: _decoration('Repayment term (months)', Icons.calendar_month_outlined),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _purposeController,
                    minLines: 3,
                    maxLines: 5,
                    validator: _required,
                    decoration: _decoration('Purpose of the loan', Icons.description_outlined)
                        .copyWith(alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Financial information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _incomeController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) {
                      final income = double.tryParse(value?.trim() ?? '');
                      if (income == null || !income.isFinite || income <= 0) {
                        return 'Enter a valid monthly income';
                      }
                      return null;
                    },
                    decoration: _decoration('Monthly income (LKR)', Icons.account_balance_outlined),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _employmentController,
                    validator: _required,
                    decoration: _decoration('Occupation / employment details', Icons.work_outline),
                  ),
                  const SizedBox(height: 18),
                  CheckboxListTile(
                    value: _termsAccepted,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: primary,
                    onChanged: (value) =>
                        setState(() => _termsAccepted = value ?? false),
                    title: const Text(
                      'I confirm that the information provided is accurate.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _submitApplication,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: _submitting
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send_outlined),
                      label: Text(_submitting ? 'Submitting...' : 'Submit application'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your application will be reviewed according to the lender’s approval process.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _decoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFDDE9E1)),
      ),
    );
  }
}
