import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../models/sales_model.dart';
import '../services/app_logger.dart';
import '../services/sales_repository.dart';
import '../widgets/sales_form_dialog.dart';
import '../widgets/sales_tile.dart';

class SalesPage extends StatefulWidget {
  final SalesRepository repository;

  const SalesPage({super.key, required this.repository});

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  bool _loadingInitialData = true;
  bool _initialLoadComplete = false;
  bool _isOffline = false;
  String? _initialErrorMessage;
  Timer? _connectivityTimer;

  @override
  void initState() {
    super.initState();
    AppLogger.info('SalesPage abierta');
    _loadInitialData();
    _startConnectivityMonitor();
    widget.repository.onSyncComplete = _onRepositorySyncComplete;
  }

  void _onRepositorySyncComplete() {
    if (mounted) {
      setState(() {});
      _showMessage('Sincronizado con Firebase');
    }
  }

  void _startConnectivityMonitor() {
    _connectivityTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      final results = await Connectivity().checkConnectivity();
      final wasOffline = _isOffline;
      _isOffline = results.isEmpty || results.contains(ConnectivityResult.none);
      
      if (wasOffline && !_isOffline) {
        if (mounted) {
          AppLogger.info('Conexión restaurada');
          _showMessage('Conexión restaurada');
          setState(() {});
        }
      } else if (!wasOffline && _isOffline) {
        if (mounted) {
          AppLogger.info('Sin conexión');
          _showMessage('Sin conexión');
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _connectivityTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loadingInitialData = true;
      _initialErrorMessage = null;
    });

    try {
      await widget.repository.loadInitialData();
      _initialLoadComplete = true;
      AppLogger.info('Datos cargados');
    } catch (error, stackTrace) {
      AppLogger.error('Error cargando datos', error: error, stackTrace: stackTrace);
    } finally {
      if (!mounted) return;
      setState(() => _loadingInitialData = false);
    }
  }

  Future<void> _openCreateSaleDialog() async {
    AppLogger.debug('Abriendo formulario para crear venta');
    final result = await showDialog<SalesFormResult>(
      context: context,
      builder: (_) => const SalesFormDialog(),
    );

    if (result == null) {
      AppLogger.debug('Creación de venta cancelada');
      return;
    }

    await _createSale(result);
  }

  Future<void> _createSale(SalesFormResult result) async {
    try {
      final wasSynced = await widget.repository.addSale(
        clientName: result.clientName,
        product: result.product,
        amount: result.amount,
        saleDate: result.saleDate,
      );
      setState(() {});
      if (wasSynced) {
        _showMessage('Venta creada y sincronizada');
      } else {
        _showMessage('Venta creada localmente (pendiente de sync)');
      }
    } catch (error, stackTrace) {
      AppLogger.error('Error creando venta', error: error, stackTrace: stackTrace);
      _showMessage('Error al crear venta');
    }
  }

  Future<void> _deleteSale(SalesModel sale) async {
    try {
      final wasSynced = await widget.repository.deleteSale(sale);
      setState(() {});
      if (wasSynced) {
        _showMessage('Venta eliminada');
      } else {
        _showMessage('Venta eliminada localmente (pendiente de sync)');
      }
    } catch (error, stackTrace) {
      AppLogger.error('Error eliminando venta', error: error, stackTrace: stackTrace);
      _showMessage('Error al eliminar venta');
    }
  }

  Future<void> _togglePaid(SalesModel sale) async {
    try {
      final wasSynced = await widget.repository.togglePaid(sale);
      setState(() {});
      final newIsPaid = !sale.isPaid;
      if (wasSynced) {
        _showMessage(newIsPaid ? 'Marcado como cobrado' : 'Marcado como pendiente');
      } else {
        _showMessage(newIsPaid ? 'Cobrado localmente (pendiente sync)' : 'Cambiado localmente (pendiente sync)');
      }
    } catch (error, stackTrace) {
      AppLogger.error('Error actualizando estado', error: error, stackTrace: stackTrace);
      _showMessage('Error al actualizar');
    }
  }

  Future<void> _refreshFromRemote() async {
    try {
      await widget.repository.refreshFromRemote();
      setState(() {});
      _showMessage('Datos actualizados');
    } catch (error, stackTrace) {
      AppLogger.error('Error actualizando', error: error, stackTrace: stackTrace);
      _showMessage('Sin conexión a Firebase');
    }
  }

  Future<void> _syncPendingSales() async {
    try {
      await widget.repository.syncPendingSales();
      setState(() {});
      _showMessage('Sincronización completada');
    } catch (error, stackTrace) {
      AppLogger.error('Error sincronizando', error: error, stackTrace: stackTrace);
      _showMessage('Error de sincronización');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingInitialData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ventas')),
        body: const _LoadingView(message: 'Cargando ventas...'),
      );
    }

    if (_initialErrorMessage != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ventas')),
        body: _ErrorView(message: _initialErrorMessage!, onRetry: _loadInitialData),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro de Ventas'),
        actions: [
          if (_isOffline) 
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.cloud_off, color: Colors.orange, size: 20),
            ),
          IconButton(
            icon: const Icon(Icons.cloud_download_outlined),
            onPressed: _refreshFromRemote,
            tooltip: 'Actualizar desde Firebase',
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: _syncPendingSales,
            tooltip: 'Sincronizar pendientes',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_isOffline)
            Container(
              width: double.infinity,
              color: Colors.orange.shade100,
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_off, size: 16, color: Colors.orange),
                  SizedBox(width: 8),
                  Text('Sin conexión - Los cambios se sincronizarán al reconectar', style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
          Expanded(
            child: StreamBuilder<List<SalesModel>>(
              stream: widget.repository.watchSales(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const _LoadingView(message: 'Consultando base local...');
                }
                if (snapshot.hasError) {
                  return _ErrorView(message: 'Error cargando ventas', onRetry: _reloadData);
                }
                final sales = snapshot.data ?? [];
                if (sales.isEmpty) {
                  return _EmptyView(
                    message: 'Aún no hay ventas registradas',
                    actionLabel: 'Crear primera venta',
                    onAction: _openCreateSaleDialog,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                  itemCount: sales.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final sale = sales[index];
                    return SalesTile(
                      sale: sale,
                      onDelete: () => _deleteSale(sale),
                      onTogglePaid: () => _togglePaid(sale),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSaleDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Venta'),
      ),
    );
  }

  void _reloadData() {
    setState(() {});
  }
}

class _LoadingView extends StatelessWidget {
  final String message;
  const _LoadingView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _EmptyView({required this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }
}