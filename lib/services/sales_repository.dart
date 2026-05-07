import 'dart:async';
import 'dart:convert';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/sales_model.dart';
import 'app_logger.dart';
import 'sales_remote_service.dart';

class SalesRepository {
  final SalesRemoteService remoteService;
  final StreamController<List<SalesModel>> _salesController = StreamController<List<SalesModel>>.broadcast();

  List<SalesModel> _localSales = [];
  Timer? _syncTimer;
  bool _wasOffline = false;
  Function()? onSyncComplete;
  SharedPreferences? _prefs;
  static const String _storageKey = 'sales_data';
  bool _initialized = false;

  SalesRepository({
    required this.remoteService,
  });

  Future<void> init() async {
    if (_initialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _loadFromLocal();
    _startSyncTimer();
    _initialized = true;
    AppLogger.info('Repository inicializado');
  }

  void _loadFromLocal() {
    final jsonStr = _prefs?.getString(_storageKey);
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = json.decode(jsonStr);
        _localSales = jsonList.map((item) => SalesModel.fromJson(item, id: item['id'] as int)).toList();
        AppLogger.info('Cargadas ${_localSales.length} ventas desde local');
      } catch (e) {
        AppLogger.warning('Error cargando datos locales');
        _localSales = [];
      }
    } else {
      _localSales = [];
    }
    _notify();
  }

  Future<void> _saveToLocal() async {
    final jsonStr = json.encode(_localSales.map((s) => {'id': s.id, ...s.toJson()}).toList());
    await _prefs?.setString(_storageKey, jsonStr);
  }

  void _startSyncTimer() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final results = await Connectivity().checkConnectivity();
      final isConnected = results.isNotEmpty && !results.contains(ConnectivityResult.none);
      
      if (isConnected) {
        AppLogger.info('Sync automático...');
        _autoSync();
      } else if (!isConnected) {
        _wasOffline = true;
      }
    });
  }

  Future<void> _autoSync() async {
    try {
      await syncPendingSales();
      await refreshFromRemote();
      _notify();
      onSyncComplete?.call();
    } catch (e, st) {
      AppLogger.warning('Auto sync falló (sin conexión)');
    }
  }

  void _notify() {
    _salesController.add(List.from(_localSales));
  }

  List<SalesModel> getSales() => List.from(_localSales);

  Future<void> loadInitialData() async {
    await init();
    AppLogger.info('Cargando datos iniciales');

    try {
      await refreshFromRemote();
      await syncPendingSales();
    } catch (e) {
      AppLogger.warning('Sin conexión, trabajando offline');
    }
  }

  Future<bool> addSale({
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
    await _saveToLocal();
    _notify();
    AppLogger.info('Venta creada: ${sale.id}');

    try {
      await remoteService.upsertSale(sale);
      _updateSale(sale.copyWith(pendingSync: false));
      await _saveToLocal();
      _notify();
      AppLogger.info('Venta sincronizada: ${sale.id}');
      return true;
    } catch (e) {
      AppLogger.info('Venta guardada localmente, pendiente de sync: ${sale.id}');
      return false;
    }
  }

  void _updateSale(SalesModel updated) {
    final idx = _localSales.indexWhere((s) => s.id == updated.id);
    if (idx >= 0) _localSales[idx] = updated;
  }

  Future<bool> togglePaid(SalesModel sale) async {
    if (sale.id == null) return false;
    final updated = sale.copyWith(isPaid: !sale.isPaid, updatedAt: DateTime.now(), pendingSync: true);
    _updateSale(updated);
    await _saveToLocal();
    _notify();
    AppLogger.info('Estado actualizado: ${sale.id}, isPaid: ${updated.isPaid}');

    try {
      await remoteService.upsertSale(updated);
      _updateSale(updated.copyWith(pendingSync: false));
      await _saveToLocal();
      _notify();
      return true;
    } catch (e) {
      AppLogger.info('Estado guardado localmente, pendiente de sync');
      return false;
    }
  }

  Future<bool> deleteSale(SalesModel sale) async {
    if (sale.id == null) return false;
    _localSales.removeWhere((s) => s.id == sale.id);
    await _saveToLocal();
    _notify();
    AppLogger.info('Venta eliminada: ${sale.id}');

    try {
      await remoteService.deleteSale(sale.id!);
      return true;
    } catch (e) {
      AppLogger.info('Venta eliminada localmente, pendiente de sync');
      return false;
    }
  }

  Future<void> refreshFromRemote() async {
    AppLogger.info('Refrescando desde Firebase');
    try {
      final remoteSales = await remoteService.fetchSales();
      for (final sale in remoteSales) {
        final idx = _localSales.indexWhere((s) => s.id == sale.id);
        if (idx >= 0) {
          final localSale = _localSales[idx];
          // Only update if remote is newer and local is already synced
          if (!localSale.pendingSync && sale.updatedAt.isAfter(localSale.updatedAt)) {
            _localSales[idx] = sale;
          }
        } else {
          _localSales.add(sale);
        }
      }
      await _saveToLocal();
      _notify();
      AppLogger.info('Ventas desde Firebase: ${remoteSales.length}');
    } catch (e) {
      AppLogger.warning('Error refrescando, usando datos locales');
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
      } catch (e) {
        AppLogger.info('Sync pendiente: ${sale.id}');
      }
    }
    await _saveToLocal();
    _notify();
  }

  void simulatePermissionDenied() => remoteService.simulatePermissionDeniedOnce();
  void simulateNetworkError() => remoteService.simulateNetworkErrorOnce();
  void simulateUnexpectedError() => remoteService.simulateUnexpectedErrorOnce();

  void dispose() {
    _syncTimer?.cancel();
    _salesController.close();
  }
}