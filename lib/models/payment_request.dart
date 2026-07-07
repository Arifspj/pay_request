class PaymentRequest {
  final int? id;
  final String merchantName;
  final String upiId;
  final double amount;
  final String? invoicePath;
  final String? contactName;
  final String? contactNumber;
  final String status; // Pending, Shared, Paid, Cancelled
  final String? category;
  final String? remarks;
  final DateTime createdAt;

  PaymentRequest({
    this.id,
    required this.merchantName,
    required this.upiId,
    required this.amount,
    this.invoicePath,
    this.contactName,
    this.contactNumber,
    this.status = 'Pending',
    this.category,
    this.remarks,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'merchant_name': merchantName,
      'upi_id': upiId,
      'amount': amount,
      'invoice_path': invoicePath ?? '',
      'contact_name': contactName ?? '',
      'contact_number': contactNumber ?? '',
      'status': status,
      'category': category ?? '',
      'remarks': remarks ?? '',
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory PaymentRequest.fromMap(Map<String, dynamic> map) {
    return PaymentRequest(
      id: map['id'] as int?,
      merchantName: map['merchant_name'] as String,
      upiId: map['upi_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      invoicePath: map['invoice_path'] as String?,
      contactName: map['contact_name'] as String?,
      contactNumber: map['contact_number'] as String?,
      status: map['status'] as String? ?? 'Pending',
      category: map['category'] as String?,
      remarks: map['remarks'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  PaymentRequest copyWith({
    int? id,
    String? merchantName,
    String? upiId,
    double? amount,
    String? invoicePath,
    String? contactName,
    String? contactNumber,
    String? status,
    String? category,
    String? remarks,
    DateTime? createdAt,
  }) {
    return PaymentRequest(
      id: id ?? this.id,
      merchantName: merchantName ?? this.merchantName,
      upiId: upiId ?? this.upiId,
      amount: amount ?? this.amount,
      invoicePath: invoicePath ?? this.invoicePath,
      contactName: contactName ?? this.contactName,
      contactNumber: contactNumber ?? this.contactNumber,
      status: status ?? this.status,
      category: category ?? this.category,
      remarks: remarks ?? this.remarks,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
