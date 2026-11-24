class OfflinePayment {
  final String clientTransactionId;
  final String collectorId;
  final int loanId;
  final int amountMinor;
  final String createdAt;
  final String syncStatus;
  final int? serverPaymentId;

  const OfflinePayment({
    required this.clientTransactionId,
    required this.collectorId,
    required this.loanId,
    required this.amountMinor,
    required this.createdAt,
    this.syncStatus = 'PENDING',
    this.serverPaymentId,
  });

  double get amount => amountMinor / 100;

  Map<String, dynamic> toMap() {
    return {
      'client_transaction_id': clientTransactionId,
      'collector_id': collectorId,
      'loan_id': loanId,
      'amount_minor': amountMinor,
      'created_at': createdAt,
      'sync_status': syncStatus,
      'server_payment_id': serverPaymentId,
    };
  }

  factory OfflinePayment.fromMap(Map<String, dynamic> map) {
    return OfflinePayment(
      clientTransactionId: map['client_transaction_id'] as String,
      collectorId: map['collector_id'] as String,
      loanId: map['loan_id'] as int,
      amountMinor: map['amount_minor'] as int,
      createdAt: map['created_at'] as String,
      syncStatus: map['sync_status'] as String,
      serverPaymentId: map['server_payment_id'] as int?,
    );
  }

  Map<String, dynamic> toApiBody() {
    return {
      'loanId': loanId,
      'amount': amount,
      'clientTransactionId': clientTransactionId,
    };
  }
}
