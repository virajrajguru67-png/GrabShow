import '../services/api_client.dart';

class PaymentAuditApi {
  PaymentAuditApi({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<void> logPayment({
    required String transactionId,
    required String status,
    required String method,
    required double amount,
    required String movieTitle,
    String? showtime,
    List<String>? seats,
  }) async {
    try {
      await _client.post(
        '/payments/audit',
        body: {
          'transactionId': transactionId,
          'status': status,
          'method': method,
          'amount': amount,
          'movieTitle': movieTitle,
          if (showtime != null) 'showtime': showtime,
          if (seats != null) 'seats': seats,
        },
      );
    } catch (error) {
      // Fire-and-forget: this should not block user flow.
    }
  }
}

