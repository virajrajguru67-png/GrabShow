import 'package:flutter/material.dart';

import '../data/mock_movies.dart';
import '../design_system/design_system.dart';
import '../services/payment_audit_api.dart';
import '../services/payment_service.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';
import 'booking_confirmation_screen.dart';

class CheckoutArguments {
  const CheckoutArguments({
    required this.movie,
    required this.selectedSeats,
    required this.totalPrice,
    this.showtime,
  });

  final Movie movie;
  final Map<String, SeatType> selectedSeats;
  final double totalPrice;
  final String? showtime;
}

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  static const route = '/checkout';

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  late final CheckoutArguments _args;
  final _promoController = TextEditingController();
  PaymentMethod _selectedMethod = PaymentMethod.upi;
  bool _promoApplied = false;
  bool _isProcessing = false;
  final PaymentService _paymentService = PaymentService();
  final PaymentAuditApi _auditApi = PaymentAuditApi();

  @override
  void dispose() {
    _promoController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final settings = ModalRoute.of(context)?.settings;
    final arguments = settings?.arguments;
    assert(
      arguments is CheckoutArguments,
      'CheckoutScreen requires CheckoutArguments.',
    );
    _args = arguments as CheckoutArguments;
  }

  double get _serviceFee => (_args.totalPrice * 0.05).clamp(1, 12);
  double get _discount => _promoApplied ? (_args.totalPrice * 0.1) : 0;
  double get _grandTotal =>
      (_args.totalPrice + _serviceFee - _discount).clamp(0, double.infinity);

  void _applyPromo() {
    final code = _promoController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a promo code to apply.')),
      );
      return;
    }
    setState(() {
      _promoApplied = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Promo “$code” applied. Enjoy the savings!')),
    );
  }

  Future<void> _continue() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    final navigator = Navigator.of(context, rootNavigator: true);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ProcessingDialog(),
    );

    final result = await _paymentService.process(
      PaymentIntent(
        method: _selectedMethod,
        amount: _grandTotal,
        metadata: {
          'movie': _args.movie.title,
          'seats': _args.selectedSeats.keys.toList(),
          'showtime': _args.showtime,
        },
      ),
    );

    if (!mounted) return;

    navigator.pop(); // close processing dialog

    setState(() => _isProcessing = false);

    if (!mounted) return;

    final seats = _args.selectedSeats.keys.toList()..sort();
    await _auditApi.logPayment(
      transactionId: result.transactionId,
      status: result.isSuccess ? 'success' : 'failure',
      method: switch (_selectedMethod) {
        PaymentMethod.upi => 'upi',
        PaymentMethod.card => 'card',
        PaymentMethod.wallet => 'wallet',
      },
      amount: _grandTotal,
      movieTitle: _args.movie.title,
      showtime: _args.showtime,
      seats: seats,
    );

    if (!mounted) return;

    if (result.isSuccess) {
      await Navigator.of(context).pushReplacementNamed(
        BookingConfirmationScreen.route,
        arguments: BookingConfirmationArguments(
          movie: _args.movie,
          seats: seats,
          transactionId: result.transactionId,
          amountPaid: _grandTotal,
          showtime: _args.showtime,
          paymentMethodLabel: _methodLabel(_selectedMethod),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result.message)),
    );
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _PaymentResultSheet(
        result: result,
        amount: _grandTotal,
        method: _selectedMethod,
        onClose: () => Navigator.of(context).pop(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seatEntries = _args.selectedSeats.entries.toList()
      ..sort(
        (a, b) => a.key.compareTo(b.key),
      );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle(title: 'Booking summary'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            _args.movie.posterUrl,
                            height: 80,
                            width: 60,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 80,
                              width: 60,
                              color: AppColors.surfaceVariant,
                              child: const Icon(Icons.movie,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _args.movie.title,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _args.showtime ?? 'Showtime to be confirmed',
                                style: theme.textTheme.bodyMedium
                                    ?.copyWith(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '${seatEntries.length} seat${seatEntries.length == 1 ? '' : 's'} selected',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: seatEntries
                          .map(
                            (entry) => Chip(
                              label:
                                  Text('${entry.key} • ${entry.value.label}'),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Payment method'),
            Card(
              child: Column(
                children: [
                  _PaymentOptionTile(
                    method: PaymentMethod.upi,
                    groupValue: _selectedMethod,
                    title: 'UPI apps',
                    subtitle: 'Google Pay, PhonePe, Paytm and more',
                    icon: Icons.account_balance_wallet_outlined,
                    onSelected: (value) =>
                        setState(() => _selectedMethod = value),
                  ),
                  const Divider(height: 0),
                  _PaymentOptionTile(
                    method: PaymentMethod.card,
                    groupValue: _selectedMethod,
                    title: 'Credit / Debit card',
                    subtitle: 'Visa, Mastercard, Rupay, Amex',
                    icon: Icons.credit_card,
                    onSelected: (value) =>
                        setState(() => _selectedMethod = value),
                  ),
                  const Divider(height: 0),
                  _PaymentOptionTile(
                    method: PaymentMethod.wallet,
                    groupValue: _selectedMethod,
                    title: 'Wallets',
                    subtitle: 'Amazon Pay, Mobikwik, Freecharge',
                    icon: Icons.account_balance_outlined,
                    onSelected: (value) =>
                        setState(() => _selectedMethod = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Have a promo code?'),
            AppCard(
              child: ResponsiveStack(
                breakpoint: DSBreakpoints.md,
                spacing: DSSpacing.md,
                children: [
                  AppInput(
                    controller: _promoController,
                    hintText: 'Enter promo code',
                    variant: AppInputVariant.outline,
                    enabled: !_promoApplied,
                  ),
                  AppButton(
                    label: _promoApplied ? 'Applied' : 'Apply',
                    variant: AppButtonVariant.tonal,
                    onPressed: _promoApplied ? null : _applyPromo,
                    fullWidth: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const _SectionTitle(title: 'Price breakdown'),
            AppCard(
              title: 'Price breakdown',
              child: Column(
                children: [
                  _PriceRow(label: 'Ticket total', amount: _args.totalPrice),
                  _PriceRow(label: 'Convenience fee', amount: _serviceFee),
                  if (_promoApplied)
                    _PriceRow(label: 'Promo discount', amount: -_discount),
                  const Divider(height: 24),
                  _PriceRow(
                    label: 'Amount payable',
                    amount: _grandTotal,
                    emphasize: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'By continuing, you agree to StreamFlix Terms of Use, Cancellation and Privacy policies.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: AppButton(
          label: _isProcessing
              ? 'Processing…'
              : 'Pay \$${_grandTotal.toStringAsFixed(2)}',
          icon: Icons.lock,
          onPressed: _isProcessing ? null : _continue,
          fullWidth: true,
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge,
    );
  }
}

class _PaymentOptionTile extends StatelessWidget {
  const _PaymentOptionTile({
    required this.method,
    required this.groupValue,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onSelected,
  });

  final PaymentMethod method;
  final PaymentMethod groupValue;
  final String title;
  final String subtitle;
  final IconData icon;
  final ValueChanged<PaymentMethod> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = method == groupValue;
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: () => onSelected(method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.surfaceVariant.withValues(alpha: 0.3)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon,
                color: selected ? AppColors.accent : AppColors.textSecondary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium
                        ?.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 22,
              width: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.accent : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: selected ? AppColors.accent : Colors.transparent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessingDialog extends StatelessWidget {
  const _ProcessingDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: AppColors.surface,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            Text(
              'Securing your payment…',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Do not close the app or press the back button.',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentResultSheet extends StatelessWidget {
  const _PaymentResultSheet({
    required this.result,
    required this.amount,
    required this.method,
    required this.onClose,
  });

  final PaymentResult result;
  final double amount;
  final PaymentMethod method;
  final VoidCallback onClose;

  IconData get _icon => Icons.error;

  Color get _iconColor => AppColors.accent;

  String get _methodLabel => switch (method) {
        PaymentMethod.upi => 'UPI',
        PaymentMethod.card => 'Card',
        PaymentMethod.wallet => 'Wallet',
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 28,
        bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(_icon, size: 52, color: _iconColor),
          const SizedBox(height: 16),
          Text(
            'Payment failed',
            style: theme.textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            result.message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          _PriceRow(
              label: 'Attempted amount ($_methodLabel)',
              amount: amount,
              emphasize: true),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Transaction ID',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 4),
                SelectableText(
                  result.transactionId,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    letterSpacing: 0.6,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onClose,
              child: const Text('Try another method'),
            ),
          ),
        ],
      ),
    );
  }
}

String _methodLabel(PaymentMethod method) {
  return switch (method) {
    PaymentMethod.upi => 'UPI',
    PaymentMethod.card => 'Card',
    PaymentMethod.wallet => 'Wallet',
  };
}

class _PriceRow extends StatelessWidget {
  const _PriceRow({
    required this.label,
    required this.amount,
    this.emphasize = false,
  });

  final String label;
  final double amount;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final style = emphasize
        ? textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)
        : textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            '${amount < 0 ? '-' : ''}\$${amount.abs().toStringAsFixed(2)}',
            style: style,
          ),
        ],
      ),
    );
  }
}
