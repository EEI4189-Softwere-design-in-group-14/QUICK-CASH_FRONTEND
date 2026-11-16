import 'package:flutter/material.dart';
import '../core/api_client.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullName = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _nic = TextEditingController();
  final _address = TextEditingController();
  final _gender = TextEditingController();
  final _occupation = TextEditingController();
  final _monthlyIncome = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  DateTime? _dob;
  bool _loading = false;
  bool _hidePassword = true;
  String? _error;

  @override
  void dispose() {
    for (final field in [
      _fullName, _email, _phone, _nic, _address, _gender, _occupation,
      _monthlyIncome, _password, _confirmPassword,
    ]) {
      field.dispose();
    }
    super.dispose();
  }

  String? _required(String? value) {
    if ((value ?? '').trim().isEmpty) return 'This field is required';
    return null;
  }

  Widget _field(String label, TextEditingController controller, {
    TextInputType? inputType,
    String? Function(String?)? validator,
    bool obscure = false,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: TextFormField(
        controller: controller,
        enabled: !_loading,
        keyboardType: inputType,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label, suffixIcon: suffixIcon),
        validator: validator,
      ),
    );
  }

  Future<void> _chooseDate() async {
    final today = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _dob ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime(today.year, today.month, today.day).subtract(const Duration(days: 1)),
    );
    if (selected != null && mounted) setState(() => _dob = selected);
  }

  String _dateIso(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      setState(() => _error = 'Please select your date of birth.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final api = ApiClient();
    try {
      final result = await api.request('POST', '/auth/register', body: {
        'fullName': _fullName.text.trim(),
        'email': _email.text.trim().toLowerCase(),
        'phone': _phone.text.trim(),
        'nic': _nic.text.trim().toUpperCase(),
        'address': _address.text.trim(),
        'dateOfBirth': _dateIso(_dob!),
        'gender': _gender.text.trim(),
        'occupation': _occupation.text.trim(),
        'monthlyIncome': _monthlyIncome.text.trim().isEmpty
            ? null : num.parse(_monthlyIncome.text.trim()),
        'password': _password.text,
      });
      if (!mounted) return;
      final message = result is Map && result['message'] is String
          ? result['message'] as String
          : 'Registration successful. Awaiting manager approval.';
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Registration submitted'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted) Navigator.pop(context);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      api.close();
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Borrower Registration')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Create your QuickCash account',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('After registration, a manager must approve your account before you can sign in.'),
                    const SizedBox(height: 22),
                    _field('Full name *', _fullName, validator: _required),
                    _field('Email address *', _email, inputType: TextInputType.emailAddress,
                        validator: (value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch((value ?? '').trim())
                            ? null : 'Enter a valid email address'),
                    _field('Phone number *', _phone, inputType: TextInputType.phone,
                        validator: (value) => RegExp(r'^(?:\+94|0)\d{9}$').hasMatch((value ?? '').trim())
                            ? null : 'Enter a valid Sri Lankan phone number'),
                    _field('NIC *', _nic,
                        validator: (value) => RegExp(r'^(\d{12}|\d{9}[VvXx])$').hasMatch((value ?? '').trim())
                            ? null : 'Enter a valid Sri Lankan NIC'),
                    _field('Address *', _address, validator: _required),
                    OutlinedButton.icon(
                      onPressed: _loading ? null : _chooseDate,
                      icon: const Icon(Icons.calendar_today_outlined),
                      label: Text(_dob == null ? 'Select date of birth *' : 'Date of birth: ${_dateIso(_dob!)}'),
                    ),
                    const SizedBox(height: 13),
                    _field('Gender (optional)', _gender),
                    _field('Occupation (optional)', _occupation),
                    _field('Monthly income in LKR (optional)', _monthlyIncome,
                        inputType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (value) {
                          if ((value ?? '').trim().isEmpty) return null;
                          final amount = num.tryParse(value!.trim());
                          if (amount == null || !amount.isFinite || amount < 0) return 'Enter a non-negative amount';
                          return null;
                        }),
                    _field('Password *', _password,
                        obscure: _hidePassword,
                        validator: (value) => (value ?? '').length < 8 || (value ?? '').length > 72
                            ? 'Use 8–72 characters' : null,
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _hidePassword = !_hidePassword),
                          icon: Icon(_hidePassword ? Icons.visibility_off : Icons.visibility),
                        )),
                    _field('Confirm password *', _confirmPassword,
                        obscure: _hidePassword,
                        validator: (value) => value != _password.text ? 'Passwords do not match' : null),
                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 12),
                    ],
                    ElevatedButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('Register'),
                    ),
                    const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
