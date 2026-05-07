import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

import '../models/sales_model.dart';

part 'sales_database.g.dart';

class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get clientName => text()();
  TextColumn get product => text()();
  RealColumn get amount => real()();
  DateTimeColumn get saleDate => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  BoolColumn get pendingSync => boolean().withDefault(const Constant(true))();
}

@DriftDatabase(tables: [Sales])
class SalesDatabase extends _$SalesDatabase {
  SalesDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'sales_app_db',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationSupportDirectory,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
    );
  }

  SalesModel _mapSaleToModel(Sale row) {
    return SalesModel(
      id: row.id,
      clientName: row.clientName,
      product: row.product,
      amount: row.amount,
      saleDate: row.saleDate,
      updatedAt: row.updatedAt,
      pendingSync: row.pendingSync,
    );
  }

  Stream<List<SalesModel>> watchSales() {
    final query = select(sales)
      ..orderBy([
        (t) => OrderingTerm.desc(t.saleDate),
      ]);

    return query.watch().map(
      (rows) => rows.map(_mapSaleToModel).toList(),
    );
  }

  Future<List<SalesModel>> getAllSales() async {
    final rows = await select(sales).get();
    return rows.map(_mapSaleToModel).toList();
  }

  Future<SalesModel> insertSale(SalesModel sale) async {
    final insertedId = await into(sales).insert(
      SalesCompanion.insert(
        clientName: sale.clientName,
        product: sale.product,
        amount: sale.amount,
        saleDate: sale.saleDate,
        updatedAt: sale.updatedAt,
        pendingSync: Value(sale.pendingSync),
      ),
    );

    return sale.copyWith(id: insertedId);
  }

  Future<void> deleteSale(int id) async {
    await (delete(sales)..where((t) => t.id.equals(id))).go();
  }

  Future<List<SalesModel>> getPendingSales() async {
    final rows = await (select(sales)..where((t) => t.pendingSync.equals(true))).get();
    return rows.map(_mapSaleToModel).toList();
  }

  Future<void> markAsSynced(int id) async {
    await (update(sales)..where((t) => t.id.equals(id))).write(
      const SalesCompanion(
        pendingSync: Value(false),
      ),
    );
  }

  Future<void> upsertFromRemote(SalesModel sale) async {
    if (sale.id == null) return;

    await into(sales).insertOnConflictUpdate(
      SalesCompanion(
        id: Value(sale.id!),
        clientName: Value(sale.clientName),
        product: Value(sale.product),
        amount: Value(sale.amount),
        saleDate: Value(sale.saleDate),
        updatedAt: Value(sale.updatedAt),
        pendingSync: const Value(false),
      ),
    );
  }
}