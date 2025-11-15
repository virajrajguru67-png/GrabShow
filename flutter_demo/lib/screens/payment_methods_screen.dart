import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  static const route = '/payment-methods';

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  final List<SavedPaymentMethod> _paymentMethods = [
    SavedPaymentMethod(
      id: '1',
      type: PaymentMethodType.card,
      label: 'Visa •••• 4242',
      expiryDate: '12/25',
      isDefault: true,
    ),
    SavedPaymentMethod(
      id: '2',
      type: PaymentMethodType.upi,
      label: 'UPI ID: user@paytm',
      isDefault: false,
    ),
    SavedPaymentMethod(
      id: '3',
      type: PaymentMethodType.wallet,
      label: 'Amazon Pay',
      isDefault: false,
    ),
  ];

  void _addPaymentMethod() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _AddPaymentMethodSheet(
        onAdd: (method) {
          setState(() {
            _paymentMethods.add(method);
          });
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Payment method added')),
          );
        },
      ),
    );
  }

  void _setDefault(String id) {
    setState(() {
      for (var method in _paymentMethods) {
        method.isDefault = method.id == id;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default payment method updated')),
    );
  }

  void _deleteMethod(String id) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Remove payment method'),
        content: const Text('Are you sure you want to remove this payment method?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _paymentMethods.removeWhere((m) => m.id == id);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment method removed')),
              );
            },
            child: const Text('Remove', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Payment Methods'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Saved payment methods',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            if (_paymentMethods.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.credit_card_off_rounded,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No payment methods',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add a payment method to get started',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._paymentMethods.map(
                (method) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PaymentMethodCard(
                    method: method,
                    onSetDefault: () => _setDefault(method.id),
                    onDelete: () => _deleteMethod(method.id),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Add payment method',
              icon: Icons.add_rounded,
              onPressed: _addPaymentMethod,
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentMethodCard extends StatelessWidget {
  const _PaymentMethodCard({
    required this.method,
    required this.onSetDefault,
    required this.onDelete,
  });

  final SavedPaymentMethod method;
  final VoidCallback onSetDefault;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: method.isDefault
              ? AppColors.accent
              : AppColors.surfaceHighlight,
        ),
        boxShadow: method.isDefault ? [DSShadows.sm] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                _getIcon(method.type),
                color: AppColors.accent,
                size: 24,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            method.label,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (method.isDefault)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Default',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: AppColors.accent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (method.expiryDate != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Expires ${method.expiryDate}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(
                  Icons.more_vert_rounded,
                  color: AppColors.textSecondary,
                ),
                color: AppColors.surface,
                itemBuilder: (context) => [
                  if (!method.isDefault)
                    PopupMenuItem(
                      value: 'default',
                      child: const Row(
                        children: [
                          Icon(Icons.star_outline_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Set as default'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded,
                            size: 20, color: AppColors.danger),
                        SizedBox(width: 8),
                        Text('Remove', style: TextStyle(color: AppColors.danger)),
                      ],
                    ),
                  ),
                ],
                onSelected: (value) {
                  if (value == 'default') {
                    onSetDefault();
                  } else if (value == 'delete') {
                    onDelete();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  IconData _getIcon(PaymentMethodType type) {
    return switch (type) {
      PaymentMethodType.card => Icons.credit_card_rounded,
      PaymentMethodType.upi => Icons.account_balance_wallet_rounded,
      PaymentMethodType.wallet => Icons.account_balance_rounded,
    };
  }
}

class _AddPaymentMethodSheet extends StatefulWidget {
  const _AddPaymentMethodSheet({required this.onAdd});

  final ValueChanged<SavedPaymentMethod> onAdd;

  @override
  State<_AddPaymentMethodSheet> createState() => _AddPaymentMethodSheetState();
}

class _AddPaymentMethodSheetState extends State<_AddPaymentMethodSheet> {
  PaymentMethodType _selectedType = PaymentMethodType.card;

  void _add() {
    final method = SavedPaymentMethod(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: _selectedType,
      label: switch (_selectedType) {
        PaymentMethodType.card => 'Visa •••• 4242',
        PaymentMethodType.upi => 'UPI ID: user@paytm',
        PaymentMethodType.wallet => 'Amazon Pay',
      },
      expiryDate: _selectedType == PaymentMethodType.card ? '12/25' : null,
      isDefault: false,
    );
    widget.onAdd(method);
  }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Add payment method',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 24),
          _PaymentTypeOption(
            type: PaymentMethodType.card,
            label: 'Credit / Debit card',
            icon: Icons.credit_card_rounded,
            selected: _selectedType == PaymentMethodType.card,
            onTap: () => setState(() => _selectedType = PaymentMethodType.card),
          ),
          const SizedBox(height: 12),
          _PaymentTypeOption(
            type: PaymentMethodType.upi,
            label: 'UPI',
            icon: Icons.account_balance_wallet_rounded,
            selected: _selectedType == PaymentMethodType.upi,
            onTap: () => setState(() => _selectedType = PaymentMethodType.upi),
          ),
          const SizedBox(height: 12),
          _PaymentTypeOption(
            type: PaymentMethodType.wallet,
            label: 'Wallet',
            icon: Icons.account_balance_rounded,
            selected: _selectedType == PaymentMethodType.wallet,
            onTap: () =>
                setState(() => _selectedType = PaymentMethodType.wallet),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Cancel',
                  variant: AppButtonVariant.subtle,
                  onPressed: () => Navigator.of(context).pop(),
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Add',
                  onPressed: _add,
                  fullWidth: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PaymentTypeOption extends StatelessWidget {
  const _PaymentTypeOption({
    required this.type,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final PaymentMethodType type;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.16)
              : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.surfaceHighlight,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.accent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.accent, size: 24),
          ],
        ),
      ),
    );
  }
}

enum PaymentMethodType {
  card,
  upi,
  wallet,
}

class SavedPaymentMethod {
  SavedPaymentMethod({
    required this.id,
    required this.type,
    required this.label,
    this.expiryDate,
    this.isDefault = false,
  });

  final String id;
  final PaymentMethodType type;
  final String label;
  final String? expiryDate;
  bool isDefault;
}

