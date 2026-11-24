import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/offline_payment.dart';

class OfflinePaymentDatabase {
  OfflinePaymentDatabase._();

  static final OfflinePaymentDatabase instance = OfflinePaymentDatabase._();

  static const String tableName = 'offline_payments';

  Future<Database>? _database;

  Future<Database> get database async {
    try {
      return await (_database ??= _initDatabase());
    } catch (_) {
      _database = null;
      rethrow;
    }
  }

  // Create or open the local SQLite database.
  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();

    final path = join(databasePath, 'quickcash_offline.db');

    return openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  // Create the offline payments table.
  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE offline_payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        client_transaction_id TEXT NOT NULL UNIQUE,
        collector_id TEXT NOT NULL,
        loan_id INTEGER NOT NULL CHECK(loan_id > 0),
        amount_minor INTEGER NOT NULL CHECK(amount_minor > 0),
        created_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'PENDING'
          CHECK(sync_status IN ('PENDING', 'SYNCED')),
        server_payment_id INTEGER,
        CHECK(
          (sync_status = 'PENDING' AND server_payment_id IS NULL)
          OR
          (sync_status = 'SYNCED' AND server_payment_id IS NOT NULL)
        )
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_offline_payment_owner
      ON offline_payments (collector_id, sync_status)
    ''');
  }

  // Save a payment locally.
  Future<void> savePayment(OfflinePayment payment) async {
    final db = await database;

    await db.transaction((txn) async {
      final existing = await txn.query(
        tableName,
        where: 'client_transaction_id = ?',
        whereArgs: [payment.clientTransactionId],
        limit: 1,
      );

      if (existing.isNotEmpty) {
        final saved = OfflinePayment.fromMap(existing.first);

        if (saved.collectorId != payment.collectorId ||
            saved.loanId != payment.loanId ||
            saved.amountMinor != payment.amountMinor) {
          throw StateError('Transaction ID conflict');
        }

        return;
      }

      await txn.insert(tableName, payment.toMap());
    });
  }

  // Retrieve payments belonging to the current collector.
  Future<List<OfflinePayment>> getPendingPayments(String collectorId) async {
    final db = await database;

    final results = await db.query(
      tableName,
      where: 'collector_id = ? AND sync_status = ?',
      whereArgs: [collectorId, 'PENDING'],
      orderBy: 'created_at ASC',
    );

    return results.map((row) => OfflinePayment.fromMap(row)).toList();
  }

  // Count pending payments.
  Future<int> getPendingCount(String collectorId) async {
    final db = await database;

    final result = await db.rawQuery(
      '''
      SELECT COUNT(*)
      FROM offline_payments
      WHERE collector_id = ?
      AND sync_status = ?
      ''',
      [collectorId, 'PENDING'],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Mark a payment as synced only after backend confirmation.
  Future<void> markAsSynced({
    required String collectorId,
    required String transactionId,
    required int serverPaymentId,
  }) async {
    if (serverPaymentId <= 0) {
      throw ArgumentError('Invalid server payment ID');
    }

    final db = await database;

    await db.update(
      tableName,
      {'sync_status': 'SYNCED', 'server_payment_id': serverPaymentId},
      where: '''
        collector_id = ?
        AND client_transaction_id = ?
        AND sync_status = ?
      ''',
      whereArgs: [collectorId, transactionId, 'PENDING'],
    );
  }
}
