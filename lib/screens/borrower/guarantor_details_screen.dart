import 'package:flutter/material.dart';

import 'loan_application_screen.dart';

class GuarantorDetailsScreen extends StatelessWidget {
  const GuarantorDetailsScreen({super.key});

  static const Color primary = Color(0xFF168B62);

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
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [
                        const CircleAvatar(
                          radius: 38,
                          backgroundColor: Color(0xFFE3F4EB),
                          child: Icon(
                            Icons.people_alt_outlined,
                            size: 40,
                            color: primary,
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Text(
                          'Add a guarantor to your loan application',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF18372B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'QuickCash records guarantor details together with '
                          'the loan application. There is no separate '
                          'guarantor submission endpoint in the current backend.',
                          textAlign: TextAlign.center,
                          style: TextStyle(height: 1.5, color: Colors.black54),
                        ),
                        const SizedBox(height: 22),
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'You will need:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(height: 10),
                        const _RequirementRow(text: 'Guarantor full name'),
                        const _RequirementRow(text: 'Sri Lankan NIC number'),
                        const _RequirementRow(text: 'Phone number'),
                        const _RequirementRow(text: 'Residential address'),
                        const _RequirementRow(text: 'Occupation (optional)'),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<bool>(
                                  builder: (_) => const LoanApplicationScreen(),
                                ),
                              );
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Continue to Loan Application'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
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
}

class _RequirementRow extends StatelessWidget {
  const _RequirementRow({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: primary, size: 20),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
