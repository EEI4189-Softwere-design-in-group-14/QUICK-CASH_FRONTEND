
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/api_client.dart';

class LoanDisbursementScreen extends StatefulWidget {
  final String token;
  final int loanId;
  final String loanCode;

  const LoanDisbursementScreen({
    super.key,
    required this.token,
    required this.loanId,
    required this.loanCode,
  });

  @override
  State<LoanDisbursementScreen> createState() =>
      _LoanDisbursementScreenState();
}

class _LoanDisbursementScreenState
    extends State<LoanDisbursementScreen> {
  final TextEditingController _otpController =
  TextEditingController();

  bool _loading = false;
  bool _completed = false;
  int? _disbursementId;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _generateOtp() async {
    setState(() {
      _loading = true;
      _error = null;
      _message = null;
      _disbursementId = null;
    });

    final api = ApiClient();

    try {
      final result = await api.request(
        'POST',
        '/manager/disbursements/loan/${widget.loanId}/otp',
        token: widget.token,
      );

      if (result is! Map ||
          result['disbursementId'] is! num) {
        throw const ApiException('Invalid OTP response');
      }

      if (!mounted) return;

      setState(() {
        _disbursementId =
            (result['disbursementId'] as num).toInt();
        _message = 'OTP generated successfully.';
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      api.close();
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _confirmDisbursement() async {
    final otp = _otpController.text.trim();

    if (!RegExp(r'^\d{6}$').hasMatch(otp)) {
      setState(() {
        _error = 'Please enter a valid 6-digit OTP.';
      });
      return;
    }

    if (_disbursementId == null) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final api = ApiClient();

    try {
      final result = await api.request(
        'POST',
        '/manager/disbursements/$_disbursementId/confirm',
        token: widget.token,
        body: {'otp': otp},
      );

      if (result is! Map ||
          result['status'] != 'COMPLETED') {
        throw const ApiException(
          'Disbursement was not confirmed.',
        );
      }

      if (!mounted) return;

      setState(() {
        _completed = true;
        _message = 'Loan disbursed successfully!';
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = e.toString());
      }
    } finally {
      api.close();
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loan Disbursement'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Icon(
                      Icons.account_balance_wallet,
                      size: 55,
                      color: Color(0xFF087F5B),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Loan Disbursement Verification',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Text('Loan: ${widget.loanCode}'),

                    const SizedBox(height: 20),

                    if (!_completed) ...[
                      ElevatedButton(
                        onPressed:
                        _loading ? null : _generateOtp,
                        child: const Text('Generate OTP'),
                      ),

                      const SizedBox(height: 20),

                      TextField(
                        controller: _otpController,
                        enabled: !_loading,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Enter 6-digit OTP',
                          prefixIcon:
                          Icon(Icons.lock_outline),
                        ),
                      ),

                      ElevatedButton(
                        onPressed: _loading ||
                            _disbursementId == null
                            ? null
                            : _confirmDisbursement,
                        child: const Text(
                          'Confirm Disbursement',
                        ),
                      ),
                    ],

                    if (_loading)
                      const Center(
                        child: CircularProgressIndicator(),
                      ),

                    if (_message != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 16,
                        ),
                        child: Text(
                          _message!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.green,
                          ),
                        ),
                      ),

                    if (_error != null)
                      Padding(
                        padding: const EdgeInsets.only(
                          top: 16,
                        ),
                        child: Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.red,
                          ),
                        ),
                      ),
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
