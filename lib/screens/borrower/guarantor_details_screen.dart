import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class GuarantorDetailsScreen extends StatefulWidget {
  const GuarantorDetailsScreen({super.key});

  @override
  State<GuarantorDetailsScreen> createState() => _GuarantorDetailsScreenState();
}

class _GuarantorDetailsScreenState extends State<GuarantorDetailsScreen> {
  static const Color primary = Color(0xFF168B62);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _nicController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _relationshipController = TextEditingController();
  final _occupationController = TextEditingController();
  final ApiService _api = ApiService();

  bool _declarationAccepted = false;
  bool _submitting = false;

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'This field is required' : null;

  String? _validatePhone(String? value) {
    final phone = value?.replaceAll(RegExp(r'\s+'), '') ?? '';
    if (!RegExp(r'^\+?[0-9]{9,15}$').hasMatch(phone)) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return null;
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _submit() async {
    if (_submitting || !_formKey.currentState!.validate()) return;
    if (!_declarationAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please confirm that the details are correct.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      // Confirm the endpoint and field names with the backend team.
      final response = await _api.post(
        '/api/loans/guarantors',
        {
          'fullName': _nameController.text.trim(),
          'nic': _nicController.text.trim(),
          'phoneNumber': _phoneController.text.trim(),
          'email': _emailController.text.trim(),
          'address': _addressController.text.trim(),
          'relationship': _relationshipController.text.trim(),
          'occupation': _occupationController.text.trim(),
        },
      );

      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Guarantor details submitted'),
          content: Text(
            response is Map && response['message'] != null
                ? response['message'].toString()
                : 'Your guarantor details have been submitted for review.',
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
          content: Text('Unable to submit details. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _relationshipController.dispose();
    _occupationController.dispose();
    _api.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAF7),
      appBar: AppBar(
        title: const Text('Guarantor Details'),
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
                        Icon(Icons.verified_user_outlined,
                            color: primary, size: 28),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Provide the details of the person who has agreed '
                            'to act as your guarantor. Make sure you have '
                            'their permission to share this information.',
                            style: TextStyle(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Personal information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    validator: _required,
                    decoration: _decoration('Full name', Icons.person_outline),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _nicController,
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'NIC number is required';
                      }
                      if (!RegExp(
                        r'^(?:[0-9]{9}[vVxX]|[0-9]{12})$',
                      ).hasMatch(value.trim())) {
                        return 'Enter a valid NIC number';
                      }
                      return null;
                    },
                    decoration: _decoration('NIC number', Icons.badge_outlined),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                    decoration: _decoration('Phone number', Icons.phone_outlined),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                    decoration: _decoration('Email address (optional)', Icons.email_outlined),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _addressController,
                    textCapitalization: TextCapitalization.sentences,
                    minLines: 2,
                    maxLines: 4,
                    validator: _required,
                    decoration: _decoration('Residential address', Icons.home_outlined)
                        .copyWith(alignLabelWithHint: true),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Additional information',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _relationshipController,
                    validator: _required,
                    decoration: _decoration(
                      'Relationship to borrower',
                      Icons.people_outline,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _occupationController,
                    validator: _required,
                    decoration: _decoration(
                      'Occupation / employment',
                      Icons.work_outline,
                    ),
                  ),
                  const SizedBox(height: 18),
                  CheckboxListTile(
                    value: _declarationAccepted,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                    activeColor: primary,
                    onChanged: (value) => setState(
                      () => _declarationAccepted = value ?? false,
                    ),
                    title: const Text(
                      'I confirm that these details are correct and that I '
                      'have permission to provide them.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _submitting ? null : _submit,
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
                      label: Text(
                        _submitting ? 'Submitting...' : 'Submit guarantor details',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Guarantor information should be handled securely and only '
                    'used for the loan application process.',
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
