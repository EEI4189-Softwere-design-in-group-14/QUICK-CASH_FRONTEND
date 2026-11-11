
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DailyPaymentCollectionScreen extends StatefulWidget {
  final int? initialLoanId;
  final String? initialBorrowerName;

  const DailyPaymentCollectionScreen({
    super.key,
    this.initialLoanId,
    this.initialBorrowerName,
  });

  @override
  State<DailyPaymentCollectionScreen> createState() =>
      _DailyPaymentCollectionScreenState();
}

class _DailyPaymentCollectionScreenState
    extends State<DailyPaymentCollectionScreen> {
  static const Color primaryGreen = Color(0xFF087F5B);

  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _loanIdController;
  late final TextEditingController _borrowerController;

  final TextEditingController _amountController =
  TextEditingController();

  final DateTime _paymentDate = DateTime.now();

  @override
  void initState() {
    super.initState();

    _loanIdController = TextEditingController(
      text: widget.initialLoanId?.toString() ?? '',
    );

    _borrowerController = TextEditingController(
      text: widget.initialBorrowerName ?? '',
    );
  }

  @override
  void dispose() {
    _loanIdController.dispose();
    _borrowerController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String get _formattedDate {
    final day = _paymentDate.day.toString().padLeft(2, '0');
    final month = _paymentDate.month.toString().padLeft(2, '0');
    final year = _paymentDate.year;

    return '$year-$month-$day';
  }

  void _clearForm() {
    _formKey.currentState?.reset();

    _loanIdController.text =
        widget.initialLoanId?.toString() ?? '';

    _borrowerController.text =
        widget.initialBorrowerName ?? '';

    _amountController.clear();
  }

  void _reviewPayment() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final loanId = int.parse(
      _loanIdController.text.trim(),
    );

    final amount = double.parse(
      _amountController.text.trim(),
    );

    final borrowerName =
    _borrowerController.text.trim().isEmpty
        ? 'Not selected'
        : _borrowerController.text.trim();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(
                Icons.receipt_long_outlined,
                color: primaryGreen,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text('Payment Preview'),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text('Borrower: $borrowerName'),

              const SizedBox(height: 8),

              Text('Loan ID: $loanId'),

              const SizedBox(height: 8),

              Text(
                'Amount: LKR ${amount.toStringAsFixed(2)}',
              ),

              const SizedBox(height: 8),

              Text('Date: $_formattedDate'),

              const SizedBox(height: 8),

              const Text('Payment Method: Cash'),

              const Divider(height: 26),

              const Text(
                'UI preview only. No payment has '
                    'been submitted or saved.',
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),

      appBar: AppBar(
        title: const Text(
          'Daily Payment Collection',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 19,
          ),
        ),
      ),

      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 600,
            ),

            child: Form(
              key: _formKey,

              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  const CircleAvatar(
                    radius: 35,
                    backgroundColor: Color(0xFFE0F5EA),
                    child: Icon(
                      Icons.payments_outlined,
                      color: primaryGreen,
                      size: 36,
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Collect Loan Payment',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  const SizedBox(height: 7),

                  const Text(
                    'Enter the borrower loan details '
                        'and payment amount.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 24),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Loan Information',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _borrowerController,
                            maxLength: 100,
                            decoration: const InputDecoration(
                              labelText: 'Borrower Name',
                              hintText: 'Enter borrower name',
                              prefixIcon: Icon(
                                Icons.person_outline,
                              ),
                              helperText:
                              'For UI preview only',
                            ),
                          ),

                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _loanIdController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Loan ID *',
                              hintText: 'Enter numeric loan ID',
                              prefixIcon: Icon(
                                Icons.numbers,
                              ),
                            ),
                            validator: (value) {
                              final id = int.tryParse(
                                value?.trim() ?? '',
                              );

                              if (id == null || id <= 0) {
                                return 'Enter a valid Loan ID';
                              }

                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Payment Information',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 16),

                          TextFormField(
                            controller: _amountController,
                            keyboardType:
                            const TextInputType
                                .numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter
                                  .allow(
                                RegExp(r'[0-9.]'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Payment Amount *',
                              hintText: 'e.g. 500.00',
                              prefixIcon: Icon(
                                Icons.payments_outlined,
                              ),
                              prefixText: 'LKR ',
                            ),
                            validator: (value) {
                              final input =
                                  value?.trim() ?? '';

                              if (input.isEmpty) {
                                return 'Enter payment amount';
                              }

                              if (!RegExp(
                                r'^\d+(\.\d{1,2})?$',
                              ).hasMatch(input)) {
                                return 'Enter a valid amount '
                                    'with up to 2 decimals';
                              }

                              final amount =
                              double.tryParse(input);

                              if (amount == null ||
                                  !amount.isFinite ||
                                  amount <= 0) {
                                return 'Amount must be '
                                    'greater than zero';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 20),

                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                color: primaryGreen,
                              ),

                              const SizedBox(width: 12),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Collection Date',
                                      style: TextStyle(
                                        color: Colors.black54,
                                        fontSize: 12,
                                      ),
                                    ),

                                    Text(
                                      _formattedDate,
                                      style: const TextStyle(
                                        fontWeight:
                                        FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 18),

                          const Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                color: primaryGreen,
                              ),

                              SizedBox(width: 12),

                              Text(
                                'Payment Method: Cash',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: primaryGreen,
                          ),

                          SizedBox(width: 12),

                          Expanded(
                            child: Text(
                              'Loan balance verification and '
                                  'payment submission will be '
                                  'enabled after API integration.',
                              style: TextStyle(
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _reviewPayment,
                      icon: const Icon(
                        Icons.fact_check_outlined,
                      ),
                      label: const Text(
                        'Review Payment',
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: _clearForm,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Clear Form'),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
