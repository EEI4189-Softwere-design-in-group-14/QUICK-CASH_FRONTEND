import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api_client.dart';
import '../database/offline_payment_database.dart';
import '../models/offline_payment.dart';
import 'payment_success_screen.dart';

class DailyPaymentCollectionScreen extends StatefulWidget {
  final String token;
  final String collectorId;
  final int? initialLoanId;
  final String? initialBorrowerName;

  const DailyPaymentCollectionScreen({
    super.key,
    required this.token,
    required this.collectorId,
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

  final _localDb = OfflinePaymentDatabase.instance;
  OfflinePayment? _pendingPayment;
  bool _loadingPending = true;
  bool _loadFailed = false;
  bool _savedLocally = false;

  // Convert decimal input to integer cents without floating-point rounding.
  int? _parseAmountMinor(String input) {
    if (!RegExp(r'^\d+(\.\d{1,2})?$').hasMatch(input)) return null;
    final parts = input.split('.');
    final cents = parts.length == 2 ? parts[1].padRight(2, '0') : '00';
    return int.tryParse('${parts[0]}$cents');
  }

  Future<void> _loadPendingPayment() async {
    setState(() {
      _loadingPending = true;
      _loadFailed = false;
      _error = null;
    });
    try {
      if (widget.collectorId.trim().isEmpty) {
        throw StateError('Collector identity is missing');
      }
      final records = await _localDb.getPendingPayments(widget.collectorId);
      if (!mounted) return;
      if (records.isNotEmpty) {
        final record = records.first;
        _loanIdController.text = record.loanId.toString();
        final cents = record.amountMinor.toString().padLeft(3, '0');
        _amountController.text =
            '${cents.substring(0, cents.length - 2)}.${cents.substring(cents.length - 2)}';
        _borrowerController.clear();
        setState(() {
          _pendingPayment = record;
          _savedLocally = true;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _error =
            'Cannot load local payments. Retry loading before collecting cash.';
      });
    } finally {
      if (mounted) setState(() => _loadingPending = false);
    }
  }

  @override
  void initState() {
    super.initState();

    _loanIdController = TextEditingController(
      text: widget.initialLoanId?.toString() ?? '',
    );

    _borrowerController = TextEditingController(
      text: widget.initialBorrowerName ?? '',
    );
    _loadPendingPayment();
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

    final bytes = List<int>.generate(16, (_) => random.nextInt(256));

    final randomPart = bytes
        .map((value) => value.toRadixString(16).padLeft(2, '0'))
        .join();

    return 'QC-${DateTime.now().microsecondsSinceEpoch}-$randomPart';
  }

  void _clearForm() {
    if (_submitting ||
        _loadingPending ||
        _loadFailed ||
        _pendingPayment != null) {
      return;
    }

    _formKey.currentState?.reset();

    _loanIdController.text = widget.initialLoanId?.toString() ?? '';

    _borrowerController.text = widget.initialBorrowerName ?? '';

    _amountController.clear();

    setState(() {
      _error = null;
    });
  }

  void _reviewPayment() {
    if (_submitting || _loadingPending || _loadFailed) return;
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

    final loanId = int.parse(_loanIdController.text.trim());

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
                'This saves a local record first. The loan balance '
                'changes only after backend confirmation.',
                style: TextStyle(color: Colors.deepOrange, fontSize: 13),
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
                  _pendingPayment = OfflinePayment(
                    loanId: loanId,
                    amountMinor: _parseAmountMinor(amount)!,
                    clientTransactionId: _generateTransactionId(),
                    collectorId: widget.collectorId,
                    createdAt: DateTime.now().toUtc().toIso8601String(),
                  );
                  _savedLocally = false;
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
      // STEP 1: Persist before sending any network request.
      await _localDb.savePayment(pending);
      if (mounted) setState(() => _savedLocally = true);
      // STEP 2: Send the same transaction ID to the backend.
      final response = await api.request(
        'POST',
        '/collector/payments',
        token: widget.token,
        body: pending.toApiBody(),
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
          paymentId is! int ||
          paymentId <= 0) {
        throw const ApiException(
          'Payment is not confirmed. '
          'Please verify the payment status.',
        );
      }

      // Persist confirmation before displaying success.
      await _localDb.markAsSynced(
        collectorId: pending.collectorId,
        transactionId: pending.clientTransactionId,
        serverPaymentId: paymentId,
      );

      // STEP 3: Load the actual receipt.
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
          receipt = Map<String, dynamic>.from(receiptResponse);
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
        _error = _savedLocally
            ? 'Saved on this device. Server confirmation or local reconciliation is incomplete.\n\n'
                  '$error\n\nDo not collect this payment again. Verify with the manager before retrying.'
            : 'Local save could not be confirmed. No server request was started in this attempt. '
                  'Retry the same payment. Do not collect the cash again.';
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
    final locked =
        _submitting ||
        _loadingPending ||
        _loadFailed ||
        _pendingPayment != null;

    return PopScope(
      canPop: !_submitting && !_loadingPending,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F8F6),

        appBar: AppBar(
          title: const Text(
            'Daily Payment Collection',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 19),
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
                      style: TextStyle(color: Colors.black54),
                    ),

                    const SizedBox(height: 24),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(18),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

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
                                prefixIcon: Icon(Icons.person_outline),
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
                                final id = int.tryParse(value?.trim() ?? '');

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
                          crossAxisAlignment: CrossAxisAlignment.start,

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
                                prefixIcon: Icon(Icons.payments_outlined),
                                prefixText: 'LKR ',
                              ),

                              validator: (value) {
                                final input = value?.trim() ?? '';

                                if (!RegExp(r'^\d+(\.\d{1,2})?$')
                                    .hasMatch(input)) {
                                  return 'Enter a valid amount '
                                      'with up to 2 decimals';
                                }

                                final amount = _parseAmountMinor(input);

                                if (amount == null || amount <= 0) {
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
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),

                    if (_loadingPending)
                      const Center(child: CircularProgressIndicator()),
                    if (_loadFailed)
                      TextButton(
                        onPressed: _loadPendingPayment,
                        child: const Text('Retry Loading Payments'),
                      ),
                    if (_pendingPayment != null)
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'An earlier payment attempt may have '
                          'reached the server. The amount and '
                          'loan are locked to prevent an '
                          'accidental duplicate transaction.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.deepOrange),
                        ),
                      ),

                    const SizedBox(height: 18),

                    SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed:
                            (_submitting || _loadingPending || _loadFailed)
                            ? null
                            : _reviewPayment,

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
      ),
    );
  }
}
