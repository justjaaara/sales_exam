import 'dart:async';

import '../models/sales_model.dart';
import 'app_logger.dart';
import 'sales_remote_service.dart';

class SalesRepository {
  final SalesRemoteService remoteService;
  final StreamController<List<SalesModel>> _salesController = StreamController<List<SalesModel>>.broadcast();

  final List<SalesModel> _localSales = [];

  SalesRepository({
    required this.remoteService,
  });

  Stream<List<SalesModel>> watchSales() {
    AppLogger.debug('Escuchando ventas');
    return _salesController.stream;
  }

  void _notify() {
    _salesController.add(List.from(_localSales));
  }

  Future<void> loadInitialData() async {
    AppLogger.info('Cargando datos iniciales');
    await refreshFromRemote();
  }

  Future<void> addSale({
    required String clientName,
    required String product,
    required double amount,
    required DateTime saleDate,
  }) async {
    final newId = _localSales.isEmpty ? 1 : _localSales.map((s) => s.id ?? 0).reduce((a, b) => a > b ? a : b) + 1;
    
    final sale = SalesModel(
      id: newId,
      clientName: clientName,
      product: product,
      amount: amount,
      saleDate: saleDate,
      updatedAt: DateTime.now(),
      pendingSync: true,
    );

    _localSales.add(sale);
    _notify();
    AppLogger.info('Venta creada: ${sale.id}');

    try {
      await remoteService.upsertSale(sale);
      _updateSale(sale.copyWith(pendingSync: false));
      _notify();
      AppLogger.info('Venta sincronizada: ${sale.id}');
    } catch (error, stackTrace) {
      AppLogger.warning('Venta pendiente de sincronización');
      AppLogger.error('Error sincronizando venta', error: error, stackTrace: stackTrace);
    }
  }

  void _updateSale(SalesModel updated) {
    final idx = _localSales.indexWhere((s) => s.id == updated.id);
    if (idx >= 0) _localSales[idx] = updated;
  }

  Future<void> deleteSale(SalesModel sale) async {
    if (sale.id == null) return;
    _localSales.removeWhere((s) => s.id == sale.id);
    _notify();
    AppLogger.info('Venta eliminada: ${sale.id}');

    try {
      await remoteService.deleteSale(sale.id!);
    } catch (error, stackTrace) {
      AppLogger.warning('Venta eliminada localmente');
      AppLogger.error('Error eliminando venta', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> refreshFromRemote() async {
    AppLogger.info('Refrescando desde Firebase');
    try {
      final remoteSales = await remoteService.fetchSales();
      for (final sale in remoteSales) {
        final idx = _localSales.indexWhere((s) => s.id == sale.id);
        if (idx >= 0) {
          _localSales[idx] = sale;
        } else {
          _localSales.add(sale);
        }
      }
      _notify();
      AppLogger.info('Ventas desde Firebase: ${remoteSales.length}');
    } catch (error, stackTrace) {
      AppLogger.error('Error refrescando', error: error, stackTrace: stackTrace);
    }
  }

  Future<void> syncPendingSales() async {
    AppLogger.info('Sincronizando pendientes');
    final pending = _localSales.where((s) => s.pendingSync).toList();
    
    for (final sale in pending) {
      try {
        await remoteService.upsertSale(sale);
        _updateSale(sale.copyWith(pendingSync: false));
        AppLogger.info('Sincronizado: ${sale.id}');
      } catch (error, stackTrace) {
        AppLogger.error('Error sincronizando: ${sale.id}', error: error, stackTrace: stackTrace);
      }
    }
  }

  void simulatePermissionDenied() => remoteService.simulatePermissionDeniedOnce();
  void simulateNetworkError() => remoteService.simulateNetworkErrorOnce();
  void simulateUnexpectedError() => remoteService.simulateUnexpectedErrorOnce();
}