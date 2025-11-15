import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../models/admin_models.dart';
import '../../repositories/admin_repository.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  late final AdminRepository _repository;
  bool _isLoading = true;
  String? _error;
  PlatformSettings? _settings;
  bool _isSaving = false;

  late final TextEditingController _razorpayController;
  late final TextEditingController _stripeController;
  late final TextEditingController _settlementController;
  late final TextEditingController _cgstController;
  late final TextEditingController _sgstController;
  late final TextEditingController _feeController;
  late final TextEditingController _theatreNameController;
  late final TextEditingController _supportEmailController;
  late final TextEditingController _contactNumberController;
  late final TextEditingController _addressController;
  late final TextEditingController _termsController;
  late final TextEditingController _privacyController;
  late final TextEditingController _refundController;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _repository = context.read<AdminRepository>();
    _razorpayController = TextEditingController();
    _stripeController = TextEditingController();
    _settlementController = TextEditingController();
    _cgstController = TextEditingController();
    _sgstController = TextEditingController();
    _feeController = TextEditingController();
    _theatreNameController = TextEditingController();
    _supportEmailController = TextEditingController();
    _contactNumberController = TextEditingController();
    _addressController = TextEditingController();
    _termsController = TextEditingController();
    _privacyController = TextEditingController();
    _refundController = TextEditingController();
    _loadSettings();
  }

  @override
  void dispose() {
    _razorpayController.dispose();
    _stripeController.dispose();
    _settlementController.dispose();
    _cgstController.dispose();
    _sgstController.dispose();
    _feeController.dispose();
    _theatreNameController.dispose();
    _supportEmailController.dispose();
    _contactNumberController.dispose();
    _addressController.dispose();
    _termsController.dispose();
    _privacyController.dispose();
    _refundController.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final token = context.read<AuthController>().accessToken;
    if (token == null) {
      setState(() {
        _error = 'Session expired. Please sign in again.';
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final settings = await _repository.fetchSettings(token);
      if (!mounted) return;
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
      _razorpayController.text = settings.razorpayKey;
      _stripeController.text = settings.stripeKey;
      _settlementController.text = settings.settlementDays.toString();
      _cgstController.text = settings.cgst.toString();
      _sgstController.text = settings.sgst.toString();
      _feeController.text = settings.convenienceFee.toString();
      _theatreNameController.text = settings.theatreName;
      _supportEmailController.text = settings.supportEmail;
      _contactNumberController.text = settings.contactNumber;
      _addressController.text = settings.address;
      _termsController.text = settings.termsUrl;
      _privacyController.text = settings.privacyUrl;
      _refundController.text = settings.refundWindowHours.toString();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final token = context.read<AuthController>().accessToken;
    final settings = _settings;
    if (token == null || settings == null) return;
    setState(() => _isSaving = true);
    final updated = PlatformSettings(
      razorpayKey: _razorpayController.text.trim(),
      stripeKey: _stripeController.text.trim(),
      settlementDays: int.tryParse(_settlementController.text.trim()) ??
          settings.settlementDays,
      cgst: double.tryParse(_cgstController.text.trim()) ?? settings.cgst,
      sgst: double.tryParse(_sgstController.text.trim()) ?? settings.sgst,
      convenienceFee: double.tryParse(_feeController.text.trim()) ??
          settings.convenienceFee,
      theatreName: _theatreNameController.text.trim(),
      supportEmail: _supportEmailController.text.trim(),
      contactNumber: _contactNumberController.text.trim(),
      address: _addressController.text.trim(),
      termsUrl: _termsController.text.trim(),
      privacyUrl: _privacyController.text.trim(),
      refundWindowHours: int.tryParse(_refundController.text.trim()) ??
          settings.refundWindowHours,
      updatedAt: DateTime.now(),
    );
    try {
      await _repository.updateSettings(token, updated);
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _settings = updated;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Settings saved')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save settings: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 12),
            Text(_error!, style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            FilledButton.tonal(
                onPressed: _loadSettings, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Text('Platform configuration',
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            Text('Payment gateways', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _razorpayController,
              decoration: const InputDecoration(labelText: 'Razorpay key'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _stripeController,
              decoration:
                  const InputDecoration(labelText: 'Stripe publishable key'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _settlementController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Settlement SLA (days)'),
              validator: (value) {
                final parsed = int.tryParse(value ?? '');
                if (parsed == null || parsed < 0 || parsed > 30) {
                  return '0-30 days allowed';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            Text('Tax configuration', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cgstController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'CGST %'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _sgstController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'SGST %'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _feeController,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Convenience fee %'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text('Theatre profile', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _theatreNameController,
              decoration: const InputDecoration(labelText: 'Business name'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _supportEmailController,
              decoration: const InputDecoration(labelText: 'Support email'),
              validator: (value) => value == null || !value.contains('@')
                  ? 'Enter valid email'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactNumberController,
              decoration: const InputDecoration(labelText: 'Contact number'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(labelText: 'Address'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            Text('Policies', style: theme.textTheme.titleMedium),
            const SizedBox(height: 12),
            TextFormField(
              controller: _termsController,
              decoration: const InputDecoration(labelText: 'Terms URL'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _privacyController,
              decoration:
                  const InputDecoration(labelText: 'Privacy policy URL'),
              validator: (value) =>
                  value == null || value.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _refundController,
              keyboardType: TextInputType.number,
              decoration:
                  const InputDecoration(labelText: 'Refund window (hours)'),
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save changes'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
