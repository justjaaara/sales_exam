import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/app_logger.dart';

class SalesFormResult {
  final String clientName;
  final String product;
  final double amount;
  final DateTime saleDate;

  const SalesFormResult({
    required this.clientName,
    required this.product,
    required this.amount,
    required this.saleDate,
  });
}

class SalesFormDialog extends StatefulWidget {
  const SalesFormDialog({super.key});

  @override
  State<SalesFormDialog> createState() => _SalesFormDialogState();
}

class _SalesFormDialogState extends State<SalesFormDialog> {
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _productController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  DateTime _saleDate = DateTime.now();

  String? _clientError;
  String? _productError;
  String? _amountError;

  @override
  void dispose() {
    _clientController.dispose();
    _productController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    final clientName = _clientController.text.trim();
    final product = _productController.text.trim();
    final amountText = _amountController.text.trim();

    AppLogger.debug('Intentando guardar venta');

    bool hasError = false;

    if (clientName.isEmpty) {
      setState(() => _clientError = 'El cliente no puede estar vacío');
      hasError = true;
    } else if (clientName.length > 100) {
      setState(() => _clientError = 'Nombre muy largo (máx 100 caracteres)');
      hasError = true;
    }

    if (product.isEmpty) {
      setState(() => _productError = 'El producto no puede estar vacío');
      hasError = true;
    } else if (product.length > 200) {
      setState(() => _productError = 'Producto muy largo (máx 200 caracteres)');
      hasError = true;
    }

    final amount = double.tryParse(amountText);
    if (amount == null || amount <= 0) {
      setState(() => _amountError = 'Ingrese un monto válido mayor a 0');
      hasError = true;
    } else if (amount > 999999999) {
      setState(() => _amountError = 'Monto demasiado grande');
      hasError = true;
    }

    if (hasError) return;

    Navigator.of(context).pop(SalesFormResult(
      clientName: clientName,
      product: product,
      amount: amount!,
      saleDate: _saleDate,
    ));
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _saleDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _saleDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nueva Venta'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _clientController,
              autofocus: true,
              decoration: InputDecoration(
                labelText: 'Cliente',
                errorText: _clientError,
              ),
              onChanged: (_) {
                if (_clientError != null) setState(() => _clientError = null);
              },
              onSubmitted: (_) => _save(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _productController,
              decoration: InputDecoration(
                labelText: 'Producto',
                errorText: _productError,
              ),
              onChanged: (_) {
                if (_productError != null) setState(() => _productError = null);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
                errorText: _amountError,
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
              ],
              onChanged: (_) {
                if (_amountError != null) setState(() => _amountError = null);
              },
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Fecha de venta'),
              subtitle: Text(
                '${_saleDate.day}/${_saleDate.month}/${_saleDate.year}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: _selectDate,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            AppLogger.debug('Creación de venta cancelada');
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}