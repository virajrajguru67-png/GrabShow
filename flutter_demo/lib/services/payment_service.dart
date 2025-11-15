import 'dart:math';

enum PaymentMethod {
  upi,
  card,
  wallet,
}

enum PaymentStatus {
  success,
  failure,
}

class PaymentResult {
  const PaymentResult({
    required this.status,
    required this.transactionId,
    required this.message,
  });

  final PaymentStatus status;
  final String transactionId;
  final String message;

  bool get isSuccess => status == PaymentStatus.success;
}

class PaymentIntent {
  const PaymentIntent({
    required this.method,
    required this.amount,
    this.currency = 'USD',
    this.metadata = const {},
  });

  final PaymentMethod method;
  final double amount;
  final String currency;
  final Map<String, dynamic> metadata;
}

class PaymentService {
  PaymentService({Random? random}) : _random = random ?? Random();

  final Random _random;

  Future<PaymentResult> process(PaymentIntent intent) async {
    await Future<void>.delayed(const Duration(seconds: 2));

    // Simple success probability based on amount and payment method.
    final successChance = switch (intent.method) {
      PaymentMethod.upi => 0.9,
      PaymentMethod.card => 0.85,
      PaymentMethod.wallet => 0.8,
    };

    final didSucceed = _random.nextDouble() <= successChance;
    final txnId = _generateTransactionId(intent.method);

    if (didSucceed) {
      return PaymentResult(
        status: PaymentStatus.success,
        transactionId: txnId,
        message: 'Payment completed successfully.',
      );
    }

    return PaymentResult(
      status: PaymentStatus.failure,
      transactionId: txnId,
      message: _failureMessage(intent.method),
    );
  }

  String _generateTransactionId(PaymentMethod method) {
    final prefix = switch (method) {
      PaymentMethod.upi => 'UPI',
      PaymentMethod.card => 'CRD',
      PaymentMethod.wallet => 'WLT',
    };
    final suffix = _random.nextInt(999999).toString().padLeft(6, '0');
    return '$prefix-$suffix';
  }

  String _failureMessage(PaymentMethod method) {
    return switch (method) {
      PaymentMethod.upi => 'UPI app declined the request. Please try another UPI ID or method.',
      PaymentMethod.card => 'Card transaction failed. Verify card details or contact your bank.',
      PaymentMethod.wallet => 'Wallet balance seems low. Try topping up or switching payment method.',
    };
  }
}

