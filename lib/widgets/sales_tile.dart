import 'package:flutter/material.dart';

import '../models/sales_model.dart';

class SalesTile extends StatelessWidget {
  final SalesModel sale;
  final VoidCallback onDelete;
  final VoidCallback onTogglePaid;

  const SalesTile({
    super.key,
    required this.sale,
    required this.onDelete,
    required this.onTogglePaid,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sale.clientName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    sale.product,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '\$${sale.amount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${sale.saleDate.day}/${sale.saleDate.month}/${sale.saleDate.year}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: sale.isPaid
                              ? Colors.green
                              : Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          sale.statusText,
                          style: TextStyle(
                            color: sale.isPaid
                                ? Colors.white
                                : Colors.orange.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        sale.pendingSync
                            ? 'Pendiente por sincronizar'
                            : 'Sincronizado',
                        style: TextStyle(
                          color: sale.pendingSync
                              ? Theme.of(context).colorScheme.error
                              : Colors.green,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              children: [
                IconButton(
                  icon: Icon(
                    sale.isPaid
                        ? Icons.check_circle
                        : Icons.check_circle_outline,
                    color: sale.isPaid ? Colors.green : Colors.grey,
                  ),
                  onPressed: onTogglePaid,
                  tooltip: sale.isPaid
                      ? 'Marcar como pendiente'
                      : 'Marcar como cobrado',
                  visualDensity: VisualDensity.compact,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar venta'),
        content: Text('¿Eliminar venta de ${sale.clientName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              onDelete();
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );
  }
}
