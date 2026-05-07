import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/sales_model.dart';
import 'app_logger.dart';

class SalesRemoteService {
  final CollectionReference<Map<String, dynamic>> _salesRef =
      FirebaseFirestore.instance.collection('sales');

  Future<void> upsertSale(SalesModel sale) async {
    if (sale.id == null) {
      AppLogger.warning('No se puede sincronizar una venta sin id local');
      return;
    }

    AppLogger.debug('Intentando guardar venta en Firebase: ${sale.id}');

    try {
      await _salesRef.doc(sale.id.toString()).set(sale.toFirestore());
      AppLogger.info('Venta guardada en Firebase: ${sale.id}');
    } catch (error, stackTrace) {
      AppLogger.error('Error guardando venta en Firebase', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<List<SalesModel>> fetchSales() async {
    AppLogger.debug('Consultando ventas desde Firebase');

    try {
      final snapshot = await _salesRef.get();
      AppLogger.info('Ventas obtenidas desde Firebase: ${snapshot.docs.length}');

      return snapshot.docs.map((doc) {
        return SalesModel.fromFirestore(doc.data(), id: int.parse(doc.id));
      }).toList();
    } catch (error, stackTrace) {
      AppLogger.error('Error consultando ventas desde Firebase', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  Future<void> deleteSale(int id) async {
    AppLogger.debug('Eliminando venta de Firebase: $id');
    try {
      await _salesRef.doc(id.toString()).delete();
      AppLogger.info('Venta eliminada de Firebase: $id');
    } catch (error, stackTrace) {
      AppLogger.error('Error eliminando venta de Firebase', error: error, stackTrace: stackTrace);
      rethrow;
    }
  }
}