import 'package:flutter/foundation.dart';
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
  String? _initialErrorMessage;

  @override
  void initState() {
    super.initState();
    AppLogger.info('SalesPage abierta');
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _loadingInitialData = true;
      _initialErrorMessage = null;
    });

    try {
      await widget.repository.loadInitialData();
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
      await widget.repository.addSale(
        clientName: result.clientName,
        product: result.product,
        amount: result.amount,
        saleDate: result.saleDate,
      );
      _showMessage('Venta creada correctamente');
    } catch (error, stackTrace) {
      AppLogger.error('Error creando venta', error: error, stackTrace: stackTrace);
      _showMessage('No se pudo crear la venta');
    }
  }

  Future<void> _deleteSale(SalesModel sale) async {
    try {
      await widget.repository.deleteSale(sale);
      _showMessage('Venta eliminada');
    } catch (error, stackTrace) {
      AppLogger.error('Error eliminando venta', error: error, stackTrace: stackTrace);
      _showMessage('No se pudo eliminar la venta');
    }
  }

  Future<void> _refreshFromRemote() async {
    try {
      await widget.repository.refreshFromRemote();
      _showMessage('Datos actualizados');
    } catch (error, stackTrace) {
      AppLogger.error('Error actualizando', error: error, stackTrace: stackTrace);
      _showMessage('Sin conexión a Firebase');
    }
  }

  Future<void> _syncPendingSales() async {
    try {
      await widget.repository.syncPendingSales();
      _showMessage('Sincronización completada');
    } catch (error, stackTrace) {
      AppLogger.error('Error sincronizando', error: error, stackTrace: stackTrace);
      _showMessage('Error de sincronización');
    }
  }

  void _runQaAction(String action, Future<void> Function() fn) async {
    try {
      await fn();
      _showMessage('Acción QA: $action');
    } catch (error, stackTrace) {
      AppLogger.error('Error en acción QA', error: error, stackTrace: stackTrace);
      _showMessage('Acción QA completada');
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _buildQaMenu() {
    if (!kDebugMode) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: 'Herramientas QA',
      icon: const Icon(Icons.bug_report_outlined),
      onSelected: (value) {
        switch (value) {
          case 'permission_denied':
            _runQaAction('permission denied', () async {
              widget.repository.simulatePermissionDenied();
              await widget.repository.addSale(clientName: 'QA Test', product: 'Test', amount: 100, saleDate: DateTime.now());
            });
          case 'network_error':
            _runQaAction('network error', () async {
              widget.repository.simulateNetworkError();
              await widget.repository.addSale(clientName: 'QA Test', product: 'Test', amount: 100, saleDate: DateTime.now());
            });
          case 'refresh_remote':
            _refreshFromRemote();
          case 'sync_pending':
            _syncPendingSales();
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'permission_denied', child: Text('QA: simular permission denied')),
        PopupMenuItem(value: 'network_error', child: Text('QA: simular error de red')),
        PopupMenuDivider(),
        PopupMenuItem(value: 'refresh_remote', child: Text('Actualizar desde Firebase')),
        PopupMenuItem(value: 'sync_pending', child: Text('Sincronizar pendientes')),
      ],
    );
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
          _buildQaMenu(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateSaleDialog,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Venta'),
      ),
      body: StreamBuilder<List<SalesModel>>(
        stream: widget.repository.watchSales(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingView(message: 'Consultando base local...');
          }

          if (snapshot.hasError) {
            AppLogger.error('Error en StreamBuilder', error: snapshot.error, stackTrace: snapshot.stackTrace);
            return _ErrorView(message: 'Error al cargar ventas', onRetry: _loadInitialData);
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
              return SalesTile(sale: sale, onDelete: () => _deleteSale(sale));
            },
          );
        },
      ),
    );
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
              FilledButton.icon(onPressed: onAction, icon: const Icon(Icons.add), label: Text(actionLabel!)),
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
            FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('Reintentar')),
          ],
        ),
      ),
    );
  }
}