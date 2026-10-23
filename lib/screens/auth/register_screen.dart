import 'package:flutter/material.dart';
import '../../services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  static const Color green = Color(0xFF168B55);
  final _formKey = GlobalKey<FormState>();
  final _api = ApiService();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _nic = TextEditingController();
  final _address = TextEditingController();
  final _occupation = TextEditingController();
  final _income = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  DateTime? _dob;
  String? _gender;
  bool _busy = false;
  bool _obscure = true;

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Required field' : null;

  Widget _field(String label, TextEditingController controller,
      {TextInputType? keyboardType,
        bool optional = false,
        bool secret = false,
        String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: secret && _obscure,
        validator: validator ?? (optional ? (_) => null : _required),
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF5F8F6),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          suffixIcon: secret
              ? IconButton(
            onPressed: () => setState(() => _obscure = !_obscure),
            icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
          )
              : null,
        ),
      ),
    );
  }

  Future<void> _pickDob() async {
    final today = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime(today.year - 20),
      firstDate: DateTime(1900),
      lastDate: today.subtract(const Duration(days: 1)),
    );
    if (date != null && mounted) setState(() => _dob = date);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _busy) return;
    setState(() => _busy = true);
    try {
      final date = _dob;
      final response = await _api.register(
        fullName: _name.text,
        email: _email.text,
        phone: _phone.text,
        nic: _nic.text,
        address: _address.text,
        password: _password.text,
        dateOfBirth: date == null
            ? null
            : '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
        gender: _gender,
        occupation: _occupation.text,
        monthlyIncome: _income.text.trim().isEmpty
            ? null
            : double.parse(_income.text.trim()),
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Registration submitted'),
          content: Text(response['message']?.toString() ??
              'Your account is awaiting manager approval.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unexpected error. Please try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Borrower Registration'),
        backgroundColor: green,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.all(20),
                children: [
                  const Icon(Icons.account_balance_wallet, color: green, size: 56),
                  const SizedBox(height: 8),
                  const Text('Create your QuickCash account',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text('Your registration will be reviewed by a manager.',
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  _field('Full Name *', _name, validator: (v) {
                    if (_required(v) != null) return 'Full name is required';
                    return v!.trim().length > 100 ? 'Maximum 100 characters' : null;
                  }),
                  _field('Email *', _email,
                      keyboardType: TextInputType.emailAddress,
                      validator: (v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
                          .hasMatch(v?.trim() ?? '')
                          ? null
                          : 'Enter a valid email'),
                  _field('Phone *', _phone,
                      keyboardType: TextInputType.phone,
                      validator: (v) => RegExp(r'^(?:\+94|0)\d{9}$')
                          .hasMatch(v?.trim() ?? '')
                          ? null
                          : 'Enter a valid Sri Lankan phone number'),
                  _field('NIC *', _nic,
                      validator: (v) => RegExp(r'^(\d{12}|\d{9}[VvXx])$')
                          .hasMatch(v?.trim() ?? '')
                          ? null
                          : 'Enter a valid NIC'),
                  _field('Address *', _address),
                  OutlinedButton.icon(
                    onPressed: _pickDob,
                    icon: const Icon(Icons.calendar_month),
                    label: Text(_dob == null
                        ? 'Date of Birth (optional)'
                        : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}'),
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: 'Gender (optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Male', 'Female', 'Other']
                        .map((g) => DropdownMenuItem(value: g, child: Text(g)))
                        .toList(),
                    onChanged: (g) => setState(() => _gender = g),
                  ),
                  const SizedBox(height: 14),
                  _field('Occupation (optional)', _occupation, optional: true),
                  _field('Monthly Income (optional)', _income,
                      optional: true,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return null;
                        final number = double.tryParse(v.trim());
                        return number == null || !number.isFinite || number < 0
                            ? 'Enter a non-negative amount'
                            : null;
                      }),
                  _field('Password *', _password,
                      secret: true,
                      validator: (v) => v == null || v.length < 8 || v.length > 72
                          ? 'Password must be 8–72 characters'
                          : null),
                  _field('Confirm Password *', _confirm,
                      secret: true,
                      validator: (v) => v != _password.text
                          ? 'Passwords do not match'
                          : _required(v)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _busy ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: green,
                        foregroundColor: Colors.white,
                      ),
                      child: _busy
                          ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                          : const Text('Register'),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: const Text('Already registered? Log in'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _name, _email, _phone, _nic, _address,
      _occupation, _income, _password, _confirm,
    ]) {
      controller.dispose();
    }
    _api.dispose();
    super.dispose();
  }
}
