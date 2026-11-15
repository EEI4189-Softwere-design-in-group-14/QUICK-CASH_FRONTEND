
import 'package:flutter/material.dart';

import '../core/api_client.dart';



String _money(Object? value) {
  final amount = num.tryParse('$value');

  if (amount == null) return 'LKR -';

  return 'LKR ${amount.toStringAsFixed(2)}';
}

String _date(DateTime date) {
  return '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';
}

Widget _infoRow(String title, Object? value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
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

class _ReconciliationData {
  final Map<String, dynamic> preview;
  final List<Map<String, dynamic>> history;

  const _ReconciliationData({
    required this.preview,
    required this.history,
  });
}

class ManagerReconciliationScreen extends StatefulWidget {
  final String token;

  const ManagerReconciliationScreen({
    super.key,
    required this.token,
  });

  @override
  State<ManagerReconciliationScreen> createState() =>
      _ManagerReconciliationScreenState();
}

class _ManagerReconciliationScreenState
    extends State<ManagerReconciliationScreen> {
  final _actualController = TextEditingController();
  final _noteController = TextEditingController();

  late Future<_ReconciliationData> _data;

  DateTime _selectedDate = DateTime.now();
  bool _saving = false;

  @override
  void initState() {
    super.initState();

    _data = _loadData();

    _actualController.addListener(_updateInput);
  }

  void _updateInput() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _actualController.removeListener(_updateInput);
    _actualController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<_ReconciliationData> _loadData() async {
    final api = ApiClient();

    try {
      final preview = await api.request(
        'GET',
        '/manager/reconciliations/preview'
            '?date=${_date(_selectedDate)}',
        token: widget.token,
      );

      final history = await api.request(
        'GET',
        '/manager/reconciliations',
        token: widget.token,
      );

      if (preview is! Map || history is! List) {
        throw const ApiException(
          'Unexpected reconciliation response.',
        );
      }

      return _ReconciliationData(
        preview: Map<String, dynamic>.from(preview),
        history: history
            .whereType<Map>()
            .map(
              (item) => Map<String, dynamic>.from(item),
        )
            .toList(),
      );
    } finally {
      api.close();
    }
  }

  void _refresh() {
    setState(() {
      _data = _loadData();
    });
  }

  Future<void> _selectDate() async {
    if (_saving) return;

    final selected = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDate: _selectedDate,
      helpText: 'Choose Reconciliation Date',
    );

    if (selected == null || !mounted) return;

    setState(() {
      _selectedDate = selected;

      // Prevent using an amount entered for another date.
      _actualController.clear();
      _noteController.clear();

      _data = _loadData();
    });
  }

  Map<String, dynamic>? _existingRecord(
      List<Map<String, dynamic>> history,
      ) {
    final date = _date(_selectedDate);

    for (final record in history) {
      if ('${record['reconciliationDate']}' == date) {
        return record;
      }
    }

    return null;
  }

  num? _validActualAmount() {
    final text = _actualController.text.trim();

    final validFormat =
    RegExp(r'^\d+(?:\.\d{1,2})?$').hasMatch(text);

    if (!validFormat) return null;

    final amount = num.tryParse(text);

    if (amount == null || !amount.isFinite || amount < 0) {
      return null;
    }

    return amount;
  }

  Future<void> _submit(
      _ReconciliationData currentData,
      ) async {
    if (_saving) return;

    final actual = _validActualAmount();

    if (actual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Enter a valid actual amount '
                'with up to 2 decimal places.',
          ),
        ),
      );
      return;
    }

    final note = _noteController.text.trim();

    if (note.length > 500) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Note cannot exceed 500 characters.'),
        ),
      );
      return;
    }

    if (_existingRecord(currentData.history) != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reconciliation already exists for this date.',
          ),
        ),
      );
      return;
    }

    final systemTotal = num.tryParse(
      '${currentData.preview['systemCollectionTotal']}',
    );

    if (systemTotal == null) {
      return;
    }

    final difference = actual - systemTotal;
    final selectedDateText = _date(_selectedDate);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirm Reconciliation'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'This action will create a real '
                      'reconciliation record in the database.',
                ),
                const SizedBox(height: 16),
                Text('Date: $selectedDateText'),
                const SizedBox(height: 8),
                Text(
                  'System Total: ${_money(systemTotal)}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Actual Amount: ${_money(actual)}',
                ),
                const SizedBox(height: 8),
                Text(
                  'Difference: ${_money(difference)}',
                ),
                const SizedBox(height: 16),
                const Text(
                  'Confirm the actual amount against '
                      'the bank or cash collection records '
                      'before saving.',
                  style: TextStyle(
                    color: Colors.deepOrange,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Confirm & Save'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _saving = true;
    });

    final api = ApiClient();

    try {
      await api.request(
        'POST',
        '/manager/reconciliations',
        token: widget.token,
        body: {
          'reconciliationDate': selectedDateText,
          'actualAmount': actual,
          'note': note,
        },
      );

      if (!mounted) return;

      _actualController.clear();
      _noteController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Bank reconciliation saved successfully.',
          ),
        ),
      );

      _refresh();
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not confirm reconciliation: $error. '
                'Check reconciliation history before '
                'trying again.',
          ),
          duration: const Duration(seconds: 7),
        ),
      );

      _refresh();
    } finally {
      api.close();

      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  Widget _historyCard(Map<String, dynamic> item) {
    final status = '${item['status'] ?? 'UNKNOWN'}';

    final color = status == 'MATCHED'
        ? Colors.green
        : Colors.orange;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${item['reconciliationDate'] ?? '-'}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Chip(
                  label: Text(status),
                  backgroundColor: color.withValues(
                    alpha: 0.12,
                  ),
                  side: BorderSide.none,
                ),
              ],
            ),
            const Divider(),
            _infoRow(
              'System Total',
              _money(item['systemCollectionTotal']),
            ),
            _infoRow(
              'Actual Amount',
              _money(item['actualAmount']),
            ),
            _infoRow(
              'Difference',
              _money(item['difference']),
            ),
            _infoRow(
              'Reconciled By',
              item['reconciledBy'],
            ),
            if (item['note'] != null &&
                '${item['note']}'.isNotEmpty)
              _infoRow('Note', item['note']),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(_ReconciliationData data) {
    final systemTotal = num.tryParse(
      '${data.preview['systemCollectionTotal']}',
    );

    final existing = _existingRecord(data.history);
    final actual = _validActualAmount();

    final difference =
    systemTotal != null && actual != null
        ? actual - systemTotal
        : null;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Bank Reconciliation',
          style: Theme.of(context).textTheme.titleLarge,
        ),

        const SizedBox(height: 8),

        const Text(
          'Compare the system payment collection total '
              'with the actual amount received.',
        ),

        const SizedBox(height: 16),

        OutlinedButton.icon(
          onPressed: _saving ? null : _selectDate,
          icon: const Icon(Icons.calendar_month),
          label: Text(
            'Date: ${_date(_selectedDate)}',
          ),
        ),

        const SizedBox(height: 12),

        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Collection Preview',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),

                const SizedBox(height: 15),

                _infoRow(
                  'Date',
                  data.preview['date'],
                ),

                _infoRow(
                  'System Collection Total',
                  _money(systemTotal),
                ),

                if (existing != null) ...[
                  const Divider(),
                  const Text(
                    'Reconciliation already exists '
                        'for this date.',
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _infoRow(
                    'Status',
                    existing['status'],
                  ),
                ] else ...[
                  const SizedBox(height: 12),

                  TextField(
                    controller: _actualController,
                    enabled: !_saving,
                    keyboardType:
                    const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Actual Amount (LKR)',
                      hintText: '0.00',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 12),

                  TextField(
                    controller: _noteController,
                    enabled: !_saving,
                    maxLength: 500,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Note (Optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  if (difference != null)
                    _infoRow(
                      'Estimated Difference',
                      _money(difference),
                    ),

                  const SizedBox(height: 8),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _saving ||
                          systemTotal == null ||
                          actual == null
                          ? null
                          : () => _submit(data),
                      icon: const Icon(Icons.save_outlined),
                      label: Text(
                        _saving
                            ? 'Saving...'
                            : 'Review & Save Reconciliation',
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  const Text(
                    'Saving creates an actual financial '
                        'reconciliation record. Use only '
                        'verified amounts.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 24),

        Text(
          'Reconciliation History',
          style: Theme.of(context).textTheme.titleLarge,
        ),

        const SizedBox(height: 12),

        if (data.history.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                'No reconciliation records found.',
              ),
            ),
          )
        else
          ...data.history.map(_historyCard),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F8F6),
      appBar: AppBar(
        title: const Text('Bank Reconciliation'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _saving ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<_ReconciliationData>(
        future: _data,
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
                      onPressed: _refresh,
                      child: const Text('Try Again'),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildContent(snapshot.data!);
        },
      ),
    );
  }
}
