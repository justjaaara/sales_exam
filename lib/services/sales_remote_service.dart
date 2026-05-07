import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sales_model.dart';
import 'app_logger.dart';

enum RemoteFailure {
  none,
  permissionDenied,
  network,
  unexpected,
}

class SalesRemoteService {
  final CollectionReference<Map<String, dynamic>> _salesRef =
      FirebaseFirestore.instance.collection('sales');

  RemoteFailure _nextFailure = RemoteFailure.none;

  void simulatePermissionDeniedOnce() {
    _nextFailure = RemoteFailure.permissionDenied;
  }

  void simulateNetworkErrorOnce() {
    _nextFailure = RemoteFailure.network;
  }

  void simulateUnexpectedErrorOnce() {
    _nextFailure = RemoteFailure.unexpected;
  }

  void _throwFailureIfNeeded() {
    final failure = _nextFailure;
    _nextFailure = RemoteFailure.none;

    if (failure == RemoteFailure.permissionDenied) {
      throw FirebaseException(
        plugin: 'cloud_firestore',
        code: 'permission-denied',
        message: 'Missing or insufficient permissions.',
      );
    }

    if (failure == RemoteFailure.network) {
      throw const SocketException(
        'Simulación: sin conexión a internet.',
      );
    }

    if (failure == RemoteFailure.unexpected) {
      throw StateError(
        'Simulación: error inesperado en el servicio remoto.',
      );
    }
  }

  Future<void> upsertSale(SalesModel sale) async {
    if (sale.id == null) {
      AppLogger.warning('No se puede sincronizar una venta sin id local');
      return;
    }

    AppLogger.debug('Intentando guardar venta en Firebase: ${sale.id}');

    _throwFailureIfNeeded();

    try {
      await _salesRef.doc(sale.id.toString()).set(sale.toFirestore());
      AppLogger.info('Venta guardada en Firebase: ${sale.id}');
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error('FirebaseException guardando venta', error: error, stackTrace: stackTrace);
      rethrow;
    } on SocketException catch (error, stackTrace) {
      AppLogger.error('Error de red guardando venta', error: error, stackTrace: stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('Error inesperado guardando venta', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<SalesModel>> fetchSales() async {
    AppLogger.debug('Consultando ventas desde Firebase');

    _throwFailureIfNeeded();

    try {
      final snapshot = await _salesRef.get();
      AppLogger.info('Ventas obtenidas desde Firebase: ${snapshot.docs.length}');

      return snapshot.docs.map((doc) {
        return SalesModel.fromFirestore(doc.data(), id: int.parse(doc.id));
      }).toList();
    } on FirebaseException catch (error, stackTrace) {
      AppLogger.error('FirebaseException consultando ventas', error: error, stackTrace: stackTrace);
      rethrow;
    } on SocketException catch (error, stackTrace) {
      AppLogger.error('Error de red consultando ventas', error: error, stackTrace: stackTrace);
      rethrow;
    } catch (error, stackTrace) {
      AppLogger.error('Error inesperado consultando ventas', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deleteSale(int id) async {
    AppLogger.debug('Eliminando venta de Firebase: $id');
    _throwFailureIfNeeded();
    try {
      await _salesRef.doc(id.toString()).delete();
      AppLogger.info('Venta eliminada de Firebase: $id');
    } catch (error, stackTrace) {
      AppLogger.error('Error eliminando venta de Firebase', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }
}