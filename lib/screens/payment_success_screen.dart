
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:printing/printing.dart';

import '../core/api_client.dart';

const Color quickCashGreen = Color(0xFF087F5B);

String receiptMoney(Object? value) {
  final amount = num.tryParse('$value');
  return amount == null
      ? 'LKR -'
      : 'LKR ${amount.toStringAsFixed(2)}';
}

String receiptDate(Object? value) {
  if (value == null) return '-';
  return value.toString().replaceFirst('T', ' ');
}

Widget receiptRow(String title, Object? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 9),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(color: Colors.black54),
          ),
        ),
        Expanded(
          child: Text(
            '${value ?? '-'}',
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    ),
  );
}

// =======================================
// KAN-127: PAYMENT SUCCESS SCREEN
// =======================================

class PaymentSuccessScreen extends StatelessWidget {
  final String token;
  final Map<String, dynamic> payment;
  final String borrowerName;
  final Map<String, dynamic>? receipt;
  final bool previewMode;

  const PaymentSuccessScreen({
    super.key,
    required this.token,
    required this.payment,
    required this.borrowerName,
    this.receipt,
    this.previewMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final confirmed =
        payment['status'] == 'ACCEPTED' &&
            payment['paymentId'] is num;

    if (!previewMode && !confirmed) {
      return Scaffold(
        appBar: AppBar(title: const Text('Payment Status')),
        body: const Center(
          child: Text('Payment is not confirmed.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        title: const Text('Payment Confirmation'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 25),
            const Icon(
              Icons.check_circle,
              size: 90,
              color: quickCashGreen,
            ),
            const SizedBox(height: 20),
            Text(
              previewMode
                  ? 'Payment Preview'
                  : 'Payment Successful!',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              previewMode
                  ? 'No payment has been saved.'
                  : 'Your loan payment has been recorded.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text('Payment Amount'),
                    const SizedBox(height: 10),
                    Text(
                      receiptMoney(payment['amount']),
                      style: const TextStyle(
                        fontSize: 29,
                        fontWeight: FontWeight.bold,
                        color: quickCashGreen,
                      ),
                    ),
                    const Divider(height: 30),
                    receiptRow('Borrower', borrowerName),
                    receiptRow(
                      'Loan Code',
                      payment['loanCode'],
                    ),
                    receiptRow(
                      'Payment Reference',
                      payment['paymentCode'],
                    ),
                    receiptRow(
                      'Payment Date',
                      receiptDate(payment['paymentDate']),
                    ),
                    receiptRow(
                      'Collector',
                      payment['collector'],
                    ),
                    const Divider(),
                    receiptRow(
                      'Remaining Balance',
                      receiptMoney(payment['balanceAfter']),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: previewMode
                  ? null
                  : () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PaymentReceiptScreen(
                      token: token,
                      payment: payment,
                      borrowerName: borrowerName,
                      initialReceipt: receipt,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.receipt_long),
              label: const Text('View Receipt Details'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).popUntil(
                      (route) => route.isFirst,
                );
              },
              icon: const Icon(Icons.dashboard),
              label: const Text('Back to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }
}

// =======================================
// KAN-127: RECEIPT DETAILS SCREEN
// =======================================

class PaymentReceiptScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> payment;
  final String borrowerName;
  final Map<String, dynamic>? initialReceipt;

  const PaymentReceiptScreen({
    super.key,
    required this.token,
    required this.payment,
    required this.borrowerName,
    this.initialReceipt,
  });

  @override
  State<PaymentReceiptScreen> createState() =>
      _PaymentReceiptScreenState();
}

class _PaymentReceiptScreenState
    extends State<PaymentReceiptScreen> {
  late Future<Map<String, dynamic>> _receiptFuture;

  @override
  void initState() {
    super.initState();
    _receiptFuture = _loadReceipt();
  }

  Future<Map<String, dynamic>> _loadReceipt() async {
    if (widget.initialReceipt != null) {
      return widget.initialReceipt!;
    }

    final id = widget.payment['paymentId'];

    if (id is! num) {
      throw const ApiException('Invalid Payment ID');
    }

    final api = ApiClient();

    try {
      final response = await api.request(
        'GET',
        '/receipts/payment/${id.toInt()}',
        token: widget.token,
      );

      if (response is! Map) {
        throw const ApiException(
          'Invalid receipt response',
        );
      }

      return Map<String, dynamic>.from(response);
    } finally {
      api.close();
    }
  }

  void _retry() {
    setState(() {
      _receiptFuture = _loadReceipt();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Receipt'),
      ),
      backgroundColor: const Color(0xFFF5F8F6),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _receiptFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState !=
              ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${snapshot.error}'),
                  TextButton(
                    onPressed: _retry,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final receipt = snapshot.data!;

          final receiptId = receipt['receiptId'];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              const SizedBox(height: 15),
              const Icon(
                Icons.receipt_long_outlined,
                size: 65,
                color: quickCashGreen,
              ),
              const SizedBox(height: 12),
              const Text(
                'QuickCash',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Official Payment Receipt',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 25),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      receiptRow(
                        'Receipt Number',
                        receipt['receiptNumber'],
                      ),
                      receiptRow(
                        'Payment Reference',
                        receipt['paymentCode'],
                      ),
                      receiptRow(
                        'Borrower',
                        receipt['borrowerName'],
                      ),
                      receiptRow(
                        'Borrower Code',
                        receipt['borrowerCode'],
                      ),
                      receiptRow(
                        'Loan Code',
                        receipt['loanCode'],
                      ),
                      receiptRow(
                        'Collector',
                        receipt['collectorName'],
                      ),
                      receiptRow(
                        'Payment Date',
                        receiptDate(receipt['paymentDate']),
                      ),
                      const Divider(),
                      receiptRow(
                        'Amount Paid',
                        receiptMoney(receipt['amount']),
                      ),
                      receiptRow(
                        'Remaining Balance',
                        receiptMoney(
                          receipt['balanceAfter'],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: receiptId is num
                    ? () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PdfReceiptViewerScreen(
                            token: widget.token,
                            receiptId: receiptId.toInt(),
                            receiptNumber:
                            '${receipt['receiptNumber'] ?? 'receipt'}',
                          ),
                    ),
                  );
                }
                    : null,
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('View PDF Receipt'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// =======================================
// KAN-127: AUTHENTICATED PDF VIEWER
// =======================================

class PdfReceiptViewerScreen extends StatefulWidget {
  final String token;
  final int receiptId;
  final String receiptNumber;

  const PdfReceiptViewerScreen({
    super.key,
    required this.token,
    required this.receiptId,
    required this.receiptNumber,
  });

  @override
  State<PdfReceiptViewerScreen> createState() =>
      _PdfReceiptViewerScreenState();
}

class _PdfReceiptViewerScreenState
    extends State<PdfReceiptViewerScreen> {
  late Future<Uint8List> _pdfFuture;

  @override
  void initState() {
    super.initState();
    _pdfFuture = _fetchPdf();
  }

  Future<Uint8List> _fetchPdf() async {
    final url = Uri.parse(
      '${ApiClient.baseUrl}'
          '/receipts/${widget.receiptId}/pdf',
    );

    final response = await http.get(
      url,
      headers: {
        'Authorization': 'Bearer ${widget.token}',
        'Accept': 'application/pdf',
      },
    ).timeout(const Duration(seconds: 25));

    if (response.statusCode == 401) {
      throw Exception('Session expired. Log in again.');
    }

    if (response.statusCode == 403) {
      throw Exception('Receipt access denied.');
    }

    if (response.statusCode != 200) {
      throw Exception(
        'PDF download failed: HTTP ${response.statusCode}',
      );
    }

    final bytes = response.bodyBytes;

    // Verify that the response starts with %PDF.
    if (bytes.length < 5 ||
        bytes[0] != 37 ||
        bytes[1] != 80 ||
        bytes[2] != 68 ||
        bytes[3] != 70 ||
        bytes[4] != 45) {
      throw Exception('Invalid PDF response.');
    }

    return bytes;
  }

  void _retry() {
    setState(() {
      _pdfFuture = _fetchPdf();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Receipt'),
      ),
      body: FutureBuilder<Uint8List>(
        future: _pdfFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState !=
              ConnectionState.done) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _retry,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          final pdfBytes = snapshot.data!;

          return PdfPreview(
            build: (_) async => pdfBytes,
            pdfFileName: '${widget.receiptNumber}.pdf',
            allowPrinting: true,
            allowSharing: true,
            canChangePageFormat: false,
            canChangeOrientation: false,
            canDebug: false,
          );
        },
      ),
    );
  }
}

// =======================================
// VIEW AN EXISTING PAYMENT RECEIPT
// No new payment required.
// =======================================

class PaymentReceiptLookupScreen extends StatefulWidget {
  final String token;

  const PaymentReceiptLookupScreen({
    super.key,
    required this.token,
  });

  @override
  State<PaymentReceiptLookupScreen> createState() =>
      _PaymentReceiptLookupScreenState();
}

class _PaymentReceiptLookupScreenState
    extends State<PaymentReceiptLookupScreen> {
  final _paymentId = TextEditingController();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _paymentId.dispose();
    super.dispose();
  }

  Future<void> _findReceipt() async {
    final id = int.tryParse(_paymentId.text.trim());

    if (id == null || id <= 0) {
      setState(() {
        _error = 'Enter a valid Payment ID';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final api = ApiClient();

    try {
      final response = await api.request(
        'GET',
        '/receipts/payment/$id',
        token: widget.token,
      );

      if (response is! Map) {
        throw const ApiException(
          'Receipt not found',
        );
      }

      final receipt =
      Map<String, dynamic>.from(response);

      final payment = <String, dynamic>{
        'paymentId': receipt['paymentId'],
        'paymentCode': receipt['paymentCode'],
        'loanCode': receipt['loanCode'],
        'amount': receipt['amount'],
        'balanceAfter': receipt['balanceAfter'],
        'paymentDate': receipt['paymentDate'],
        'collector': receipt['collectorName'],
      };

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentReceiptScreen(
            token: widget.token,
            payment: payment,
            borrowerName:
            '${receipt['borrowerName'] ?? '-'}',
            initialReceipt: receipt,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
        });
      }
    } finally {
      api.close();
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find Payment Receipt'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Enter an existing Payment ID '
                  'to view its receipt.',
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _paymentId,
              enabled: !_loading,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Payment ID',
                hintText: 'e.g. 2',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loading ? null : _findReceipt,
              icon: const Icon(Icons.search),
              label: Text(
                _loading ? 'Loading...' : 'Find Receipt',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
