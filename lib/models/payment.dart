/// Méthode de paiement
enum PaymentMethod {
  none,
  lumicash, // ou "lunclass" dans la doc
  lightning,
}

extension PaymentMethodX on PaymentMethod {
  String get apiValue {
    switch (this) {
      case PaymentMethod.lumicash:
        return 'lunclass';
      case PaymentMethod.lightning:
        return 'lightning';
      case PaymentMethod.none:
        return 'none';
    }
  }

  String get label {
    switch (this) {
      case PaymentMethod.lumicash:
        return 'Lumicash';
      case PaymentMethod.lightning:
        return 'Lightning ⚡';
      case PaymentMethod.none:
        return 'Aucun';
    }
  }
}

/// Statut de paiement
enum PaymentStatus {
  unpaid,
  pending,
  paid,
  failed,
}

extension PaymentStatusX on PaymentStatus {
  static PaymentStatus fromString(String? s) {
    switch (s) {
      case 'paid':
        return PaymentStatus.paid;
      case 'pending':
        return PaymentStatus.pending;
      case 'failed':
        return PaymentStatus.failed;
      default:
        return PaymentStatus.unpaid;
    }
  }

  String get label {
    switch (this) {
      case PaymentStatus.paid:
        return 'Payé';
      case PaymentStatus.pending:
        return 'En attente';
      case PaymentStatus.failed:
        return 'Échec';
      case PaymentStatus.unpaid:
        return 'Non payé';
    }
  }
}

/// Réponse d'une demande OTP
class OtpRequestResponse {
  final String orderId;
  final String gateway;

  OtpRequestResponse({required this.orderId, required this.gateway});

  factory OtpRequestResponse.fromJson(Map<String, dynamic> json) {
    return OtpRequestResponse(
      orderId: json['order_id']?.toString() ?? '',
      gateway: json['gateway']?.toString() ?? '',
    );
  }
}

/// Facture Lightning
class LightningInvoice {
  final String paymentRequest; // 👈 le bolt11 à afficher en QR
  final int? amountSats;
  final String? paymentHash;

  LightningInvoice({
    required this.paymentRequest,
    this.amountSats,
    this.paymentHash,
  });

  factory LightningInvoice.fromJson(Map<String, dynamic> json) {
    return LightningInvoice(
      paymentRequest: json['payment_request']?.toString() ??
          json['invoice']?.toString() ??
          '',
      amountSats: json['amount_sats'] is int
          ? json['amount_sats']
          : int.tryParse('${json['amount_sats']}'),
      paymentHash: json['payment_hash']?.toString(),
    );
  }
}

/// Réponse d'un paiement Lightning (avec facture)
class LightningResponse {
  final String orderId;
  final LightningInvoice invoice;

  LightningResponse({required this.orderId, required this.invoice});

  factory LightningResponse.fromJson(Map<String, dynamic> json) {
    return LightningResponse(
      orderId: json['order_id']?.toString() ?? '',
      invoice: LightningInvoice.fromJson(
          Map<String, dynamic>.from(json['invoice'] ?? {})),
    );
  }
}

/// Réponse du polling de statut
class OrderStatusResponse {
  final String status; // 'pending' | 'paid' | 'failed' | ...
  final String? managerStatus;
  final String? gateway;

  OrderStatusResponse({
    required this.status,
    this.managerStatus,
    this.gateway,
  });

  bool get isPaid => status == 'paid';
  bool get isPending => status == 'pending';
  bool get isFailed => status == 'failed';

  factory OrderStatusResponse.fromJson(Map<String, dynamic> json) {
    return OrderStatusResponse(
      status: json['status']?.toString() ?? 'pending',
      managerStatus: json['manager_status']?.toString(),
      gateway: json['gateway']?.toString(),
    );
  }
}