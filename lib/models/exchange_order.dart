class ExchangeOrder {
  final String orderId;
  final String gateway;
  final int amountBif;

  ExchangeOrder({
    required this.orderId,
    required this.gateway,
    required this.amountBif,
  });

  factory ExchangeOrder.fromJson(Map<String, dynamic> json) {
    return ExchangeOrder(
      orderId: json['order_id']?.toString() ?? '',
      gateway: json['gateway']?.toString() ?? '',
      amountBif: json['amount'] is int
          ? json['amount']
          : int.tryParse('${json['amount']}') ?? 0,
    );
  }
}

/// Élément d'historique
class HistoryItem {
  final String kind; // 'reservation' | 'abonnement' | 'exchange'
  final int id;
  final String label;
  final int amountBif;
  final String method;
  final String status;
  final String orderId;
  final String date;

  HistoryItem({
    required this.kind,
    required this.id,
    required this.label,
    required this.amountBif,
    required this.method,
    required this.status,
    required this.orderId,
    required this.date,
  });

  factory HistoryItem.fromJson(Map<String, dynamic> json) {
    return HistoryItem(
      kind: json['kind']?.toString() ?? '',
      id: json['id'] is int ? json['id'] : int.tryParse('${json['id']}') ?? 0,
      label: json['label']?.toString() ?? '',
      amountBif: json['amount_bif'] is int
          ? json['amount_bif']
          : int.tryParse('${json['amount_bif']}') ?? 0,
      method: json['method']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      date: json['date']?.toString() ?? '',
    );
  }
}

class HistoryResponse {
  final int count;
  final int totalPaidBif;
  final List<HistoryItem> items;

  HistoryResponse({
    required this.count,
    required this.totalPaidBif,
    required this.items,
  });

  factory HistoryResponse.fromJson(Map<String, dynamic> json) {
    List<HistoryItem> items = [];
    final raw = json['items'];
    if (raw is List) {
      items = raw
          .whereType<Map>()
          .map((j) => HistoryItem.fromJson(Map<String, dynamic>.from(j)))
          .toList();
    }
    return HistoryResponse(
      count: json['count'] is int
          ? json['count']
          : int.tryParse('${json['count']}') ?? 0,
      totalPaidBif: json['total_paid_bif'] is int
          ? json['total_paid_bif']
          : int.tryParse('${json['total_paid_bif']}') ?? 0,
      items: items,
    );
  }
}