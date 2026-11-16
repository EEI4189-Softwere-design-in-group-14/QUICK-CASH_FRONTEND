
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import 'payment_success_screen.dart';

class DailyPaymentCollectionScreen extends StatefulWidget {
  final String token;
  final int? initialLoanId;
  final String? initialBorrowerName;

  const DailyPaymentCollectionScreen({
    super.key,
    required this.token,
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

  final _amountController = TextEditingController();

  bool _submitting = false;
  String? _error;

  // Keep the same request when retrying after a network error.
  ({
  int loanId,
  String amount,
  String transactionId,
  })? _pendingPayment;

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

  String _money(Object? value) {
    final amount = num.tryParse(value.toString());

    if (amount == null) return 'LKR -';

    return 'LKR ${amount.toStringAsFixed(2)}';
  }

  String _generateTransactionId() {
    final random = Random.secure();

    final bytes = List<int>.generate(
      16,
          (_) => random.nextInt(256),
    );

    final randomPart = bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();

    return 'QC-${DateTime.now().microsecondsSinceEpoch}-$randomPart';
  }

  void _clearForm() {
    if (_submitting || _pendingPayment != null) return;

    _formKey.currentState?.reset();

    _loanIdController.text =
        widget.initialLoanId?.toString() ?? '';

    _borrowerController.text =
        widget.initialBorrowerName ?? '';

    _amountController.clear();

    setState(() {
      _error = null;
    });
  }

  void _reviewPayment() {
    // Retry the exact same payment if the previous result
    // was uncertain.
    if (_pendingPayment != null) {
      _submitPayment();
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    final loanId = int.parse(
      _loanIdController.text.trim(),
    );

    final amount = _amountController.text.trim();

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Loan Payment'),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please verify the payment details '
                    'before saving.',
              ),

              const SizedBox(height: 18),

              Text('Loan ID: $loanId'),

              const SizedBox(height: 10),

              Text('Amount: ${_money(amount)}'),

              const SizedBox(height: 10),

              const Text('Payment Method: Cash'),

              const SizedBox(height: 18),

              const Text(
                'Confirm only after receiving the cash. '
                    'This action records an actual payment '
                    'and updates the loan balance.',
                style: TextStyle(
                  color: Colors.deepOrange,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);

                setState(() {
                  _pendingPayment = (
                  loanId: loanId,
                  amount: amount,
                  transactionId: _generateTransactionId(),
                  );
                });

                _submitPayment();
              },
              child: const Text('Confirm & Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _submitPayment() async {
    final pending = _pendingPayment;

    if (pending == null || _submitting) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    final api = ApiClient();

    try {
      // STEP 1: Save actual payment to Spring Boot.
      final response = await api.request(
        'POST',
        '/collector/payments',
        token: widget.token,
        body: {
          'loanId': pending.loanId,
          'amount': double.parse(pending.amount),
          'clientTransactionId': pending.transactionId,
        },
      );

      if (response is! Map) {
        throw const ApiException(
          'Unexpected payment response. '
              'Verify the payment before retrying.',
        );
      }

      final payment = Map<String, dynamic>.from(response);

      final paymentId = payment['paymentId'];

      // Do not show success for an unconfirmed payment.
      if (payment['status'] != 'ACCEPTED' ||
          paymentId is! num) {
        throw const ApiException(
          'Payment is not confirmed. '
              'Please verify the payment status.',
        );
      }

      // STEP 2: Load the actual receipt.
      // A receipt request failure must not make the
      // already-saved payment appear unsuccessful.
      Map<String, dynamic>? receipt;

      try {
        final receiptResponse = await api.request(
          'GET',
          '/receipts/payment/${paymentId.toInt()}',
          token: widget.token,
        );

        if (receiptResponse is Map) {
          receipt = Map<String, dynamic>.from(
            receiptResponse,
          );
        }
      } catch (_) {
        // Payment is saved, but receipt lookup
        // can be retried during KAN-132 integration.
      }

      if (!mounted) return;

      final verifiedBorrowerName =
          receipt?['borrowerName']?.toString() ??
              'Borrower details unavailable';

      // STEP 3: Navigate only after confirmed payment.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
            builder: (_) => PaymentSuccessScreen(
              token: widget.token,
              payment: payment,
              borrowerName: verifiedBorrowerName,
              receipt: receipt,
              previewMode: false,
            ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _error =
        '$error\n\n'
            'Payment confirmation was not received. '
            'Do not submit this payment as a new transaction. '
            'Use Retry Same Payment or verify it with the manager.';
      });
    } finally {
      api.close();

      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = _submitting ||
        _pendingPayment != null;

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
            constraints: const BoxConstraints(maxWidth: 600),

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

                  const SizedBox(height: 8),

                  const Text(
                    'Record a payment for an assigned loan.',
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
                            enabled: !locked,
                            maxLength: 100,
                            decoration: const InputDecoration(
                              labelText: 'Borrower Name',
                              hintText: 'Borrower name',
                              prefixIcon: Icon(
                                Icons.person_outline,
                              ),
                              helperText:
                              'For reference only. '
                                  'Backend verifies the loan.',
                            ),
                          ),

                          const SizedBox(height: 12),

                          TextFormField(
                            controller: _loanIdController,
                            enabled: !locked,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],

                            decoration: const InputDecoration(
                              labelText: 'Loan ID *',
                              hintText: 'Enter Loan ID',
                              prefixIcon: Icon(Icons.numbers),
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
                            enabled: !locked,

                            keyboardType:
                            const TextInputType.numberWithOptions(
                              decimal: true,
                            ),

                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
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
                              final input = value?.trim() ?? '';

                              if (!RegExp(
                                r'^\d+(\.\d{1,2})?$',
                              ).hasMatch(input)) {
                                return 'Enter a valid amount '
                                    'with up to 2 decimals';
                              }

                              final amount = double.tryParse(input);

                              if (amount == null ||
                                  !amount.isFinite ||
                                  amount <= 0) {
                                return 'Amount must be greater than zero';
                              }

                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          const Row(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                color: primaryGreen,
                              ),
                              SizedBox(width: 12),
                              Text('Payment Method: Cash'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  if (_error != null)
                    Card(
                      color: const Color(0xFFFFF1F0),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _error!,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
                    ),

                  if (_pendingPayment != null)
                    const Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                        'An earlier payment attempt may have '
                            'reached the server. The amount and '
                            'loan are locked to prevent an '
                            'accidental duplicate transaction.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.deepOrange,
                        ),
                      ),
                    ),

                  const SizedBox(height: 18),

                  SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed:
                      _submitting ? null : _reviewPayment,

                      icon: _submitting
                          ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                          : Icon(
                        _pendingPayment == null
                            ? Icons.fact_check_outlined
                            : Icons.refresh,
                      ),

                      label: Text(
                        _submitting
                            ? 'Saving Payment...'
                            : _pendingPayment != null
                            ? 'Retry Same Payment'
                            : 'Review Payment',
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  OutlinedButton.icon(
                    onPressed: locked ? null : _clearForm,
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
