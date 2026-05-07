class SalesModel {
  final int? id;
  final String clientName;
  final String product;
  final double amount;
  final DateTime saleDate;
  final DateTime updatedAt;
  final bool pendingSync;
  final bool isPaid;

  const SalesModel({
    this.id,
    required this.clientName,
    required this.product,
    required this.amount,
    required this.saleDate,
    required this.updatedAt,
    required this.pendingSync,
    this.isPaid = false,
  });

  String get statusText => isPaid ? 'Cobrado' : 'Pendiente por cobrar';

  SalesModel copyWith({
    int? id,
    String? clientName,
    String? product,
    double? amount,
    DateTime? saleDate,
    DateTime? updatedAt,
    bool? pendingSync,
    bool? isPaid,
  }) {
    return SalesModel(
      id: id ?? this.id,
      clientName: clientName ?? this.clientName,
      product: product ?? this.product,
      amount: amount ?? this.amount,
      saleDate: saleDate ?? this.saleDate,
      updatedAt: updatedAt ?? this.updatedAt,
      pendingSync: pendingSync ?? this.pendingSync,
      isPaid: isPaid ?? this.isPaid,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'clientName': clientName,
      'product': product,
      'amount': amount,
      'saleDate': saleDate.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isPaid': isPaid,
    };
  }

  factory SalesModel.fromFirestore(Map<String, dynamic> map, {required int id}) {
    return SalesModel(
      id: id,
      clientName: map['clientName'] as String? ?? '',
      product: map['product'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      saleDate: DateTime.tryParse(map['saleDate'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? '') ?? DateTime.now(),
      pendingSync: false,
      isPaid: map['isPaid'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => toFirestore();

  factory SalesModel.fromJson(Map<String, dynamic> json, {required int id}) {
    return SalesModel.fromFirestore(json, id: id);
  }
}