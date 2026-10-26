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
  final _guarantorNameController = TextEditingController();
  final _guarantorNicController = TextEditingController();
  final _guarantorPhoneController = TextEditingController();
  final _guarantorAddressController = TextEditingController();
  final _guarantorOccupationController = TextEditingController();
  final ApiService _api = ApiService();

  bool _submitting = false;
  bool _termsAccepted = false;

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _validateAmount(String? value) {
    final amount = double.tryParse(value?.trim() ?? '');
    if (amount == null || !amount.isFinite || amount < 1) {
      return 'Enter an amount greater than zero';
    }
    return null;
  }

  String? _validateNic(String? value) {
    final nic = value?.trim() ?? '';
    if (!RegExp(r'^(\d{12}|\d{9}[VvXx])$').hasMatch(nic)) {
      return 'Enter a valid Sri Lankan NIC';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';
    if (!RegExp(r'^(?:\+94|0)\d{9}$').hasMatch(phone)) {
      return 'Use 0XXXXXXXXX or +94XXXXXXXXX';
    }
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

    setState(() => _submitting = true);
    try {
      final response = await _api.applyForLoan(
        requestedAmount: double.parse(_amountController.text.trim()),
        purpose: _purposeController.text.trim(),
        repaymentMonths: int.parse(_termController.text.trim()),
        guarantorFullName: _guarantorNameController.text.trim(),
        guarantorNic: _guarantorNicController.text.trim(),
        guarantorPhone: _guarantorPhoneController.text.trim(),
        guarantorAddress: _guarantorAddressController.text.trim(),
        guarantorOccupation: _guarantorOccupationController.text.trim(),
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Application submitted'),
          content: Text(
            'Application ' + (response['loanCode']?.toString() ?? '') +
            ' submitted successfully. Status: ' +
            (response['status']?.toString() ?? 'PENDING') + '.',
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
    _guarantorNameController.dispose();
    _guarantorNicController.dispose();
    _guarantorPhoneController.dispose();
    _guarantorAddressController.dispose();
    _guarantorOccupationController.dispose();
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
                    child: const Text(
                      'Complete your loan and guarantor details. '
                      'Your application will be reviewed before approval.',
                      style: TextStyle(height: 1.4),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _heading('Loan details'),
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
                      if (months == null || months < 1) {
                        return 'Repayment period must be at least 1 month';
                      }
                      return null;
                    },
                    decoration: _decoration('Repayment period (months)', Icons.calendar_month_outlined),
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
                  _heading('Guarantor details'),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _guarantorNameController,
                    textCapitalization: TextCapitalization.words,
                    validator: _required,
                    decoration: _decoration('Guarantor full name', Icons.person_outline),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _guarantorNicController,
                    textCapitalization: TextCapitalization.characters,
                    validator: _validateNic,
                    decoration: _decoration('Guarantor NIC', Icons.badge_outlined),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _guarantorPhoneController,
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                    decoration: _decoration('Guarantor phone number', Icons.phone_outlined),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _guarantorAddressController,
                    minLines: 2,
                    maxLines: 4,
                    validator: _required,
                    decoration: _decoration('Guarantor address', Icons.home_outlined)
                        .copyWith(alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _guarantorOccupationController,
                    decoration: _decoration('Guarantor occupation (optional)', Icons.work_outline),
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
                      'I confirm that the information provided is accurate and the guarantor has agreed.',
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _heading(String text) => Text(
        text,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      );

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
