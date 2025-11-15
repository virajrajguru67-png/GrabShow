import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../models/admin_models.dart';
import '../../repositories/admin_repository.dart';

class BookingOperationsPage extends StatefulWidget {
  const BookingOperationsPage({super.key});

  @override
  State<BookingOperationsPage> createState() => _BookingOperationsPageState();
}

class _BookingOperationsPageState extends State<BookingOperationsPage> {
  late final AdminRepository _repository;
  bool _isLoading = true;
  String? _error;
  List<AdminBooking> _bookings = const [];
  BookingStatus? _selectedStatus;

  @override
  void initState() {
    super.initState();
    _repository = context.read<AdminRepository>();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
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
      final bookings = await _repository.fetchBookings(token);
      if (!mounted) return;
      setState(() {
        _bookings = bookings;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleAction(AdminBooking booking, String action) async {
    final token = context.read<AuthController>().accessToken;
    if (token == null) return;
    try {
      if (action == 'cancel') {
        await _repository.cancelBooking(token, booking.id);
      } else if (action == 'refund') {
        await _repository.refundBooking(token, booking.id);
      }
      if (!mounted) return;
      await _loadBookings();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Booking ${action == 'refund' ? 'refunded' : 'cancelled'}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update booking: $error')),
      );
    }
  }

  void _openDetails(AdminBooking booking) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => BookingDetailSheet(
        booking: booking,
        onCancel: booking.status == BookingStatus.cancelled ||
                booking.status == BookingStatus.refunded
            ? null
            : () => _handleAction(booking, 'cancel'),
        onRefund: booking.status == BookingStatus.refunded
            ? null
            : () => _handleAction(booking, 'refund'),
      ),
    );
  }

  List<AdminBooking> get _filteredBookings {
    if (_selectedStatus == null) return _bookings;
    return _bookings
        .where((booking) => booking.status == _selectedStatus)
        .toList();
  }

  String _statusLabel(BookingStatus status) {
    return switch (status) {
      BookingStatus.reserved => 'Reserved',
      BookingStatus.confirmed => 'Confirmed',
      BookingStatus.cancelled => 'Cancelled',
      BookingStatus.refunded => 'Refunded',
    };
  }

  Color _statusColor(ThemeData theme, BookingStatus status) {
    switch (status) {
      case BookingStatus.confirmed:
        return theme.colorScheme.primaryContainer;
      case BookingStatus.cancelled:
        return theme.colorScheme.errorContainer;
      case BookingStatus.refunded:
        return theme.colorScheme.secondaryContainer;
      case BookingStatus.reserved:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bookings = _filteredBookings;

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
                onPressed: _loadBookings, child: const Text('Retry')),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Booking operations', style: theme.textTheme.headlineSmall),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadBookings,
                    label: const Text('Refresh'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('All'),
                selected: _selectedStatus == null,
                onSelected: (_) => setState(() => _selectedStatus = null),
              ),
              for (final status in BookingStatus.values)
                ChoiceChip(
                  label: Text(_statusLabel(status)),
                  selected: _selectedStatus == status,
                  onSelected: (_) => setState(() => _selectedStatus = status),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: bookings.isEmpty
                ? const Center(
                    child: Text('No bookings found for the selected filters.'))
                : Card(
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: bookings.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final booking = bookings[index];
                        return ListTile(
                          leading: CircleAvatar(
                            child: Text(booking.purchaserName.isNotEmpty
                                ? booking.purchaserName[0].toUpperCase()
                                : '?'),
                          ),
                          title: Text(booking.movieTitle),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${booking.reference} • ${DateFormat('dd MMM yyyy, hh:mm a').format(booking.purchasedAt)}',
                              ),
                              const SizedBox(height: 4),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  Chip(
                                    label: Text(
                                      '${booking.currency} ${booking.totalAmount.toStringAsFixed(2)}',
                                    ),
                                  ),
                                  Chip(
                                    label: Text(_statusLabel(booking.status)),
                                    backgroundColor:
                                        _statusColor(theme, booking.status),
                                  ),
                                  Chip(
                                    label:
                                        Text('${booking.tickets.length} seats'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          onTap: () => _openDetails(booking),
                          trailing: IconButton(
                            icon: const Icon(Icons.arrow_forward_ios),
                            onPressed: () => _openDetails(booking),
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class BookingDetailSheet extends StatelessWidget {
  const BookingDetailSheet({
    super.key,
    required this.booking,
    this.onCancel,
    this.onRefund,
  });

  final AdminBooking booking;
  final VoidCallback? onCancel;
  final VoidCallback? onRefund;

  String _statusLabel(BookingStatus status) => switch (status) {
        BookingStatus.reserved => 'Reserved',
        BookingStatus.confirmed => 'Confirmed',
        BookingStatus.cancelled => 'Cancelled',
        BookingStatus.refunded => 'Refunded',
      };

  (Color, Color) _statusColors(ThemeData theme, BookingStatus status) =>
      switch (status) {
        BookingStatus.confirmed => (
            theme.colorScheme.primaryContainer,
            theme.colorScheme.onPrimaryContainer
          ),
        BookingStatus.cancelled => (
            theme.colorScheme.errorContainer,
            theme.colorScheme.onErrorContainer
          ),
        BookingStatus.refunded => (
            theme.colorScheme.secondaryContainer,
            theme.colorScheme.onSecondaryContainer
          ),
        BookingStatus.reserved => (
            theme.colorScheme.surfaceContainerHighest,
            theme.colorScheme.onSurface
          ),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (statusBg, statusFg) = _statusColors(theme, booking.status);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text('Booking ${booking.reference}',
                    style: theme.textTheme.headlineSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              booking.movieTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Chip(
              backgroundColor: statusBg,
              label: Text(
                _statusLabel(booking.status),
                style: theme.textTheme.bodySmall?.copyWith(color: statusFg),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Customer', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Text(booking.purchaserName),
                      Text(booking.purchaserEmail),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Payment', style: theme.textTheme.titleSmall),
                      const SizedBox(height: 8),
                      Text(
                          '${booking.currency} ${booking.totalAmount.toStringAsFixed(2)}'),
                      Text(
                        'Purchased ${DateFormat('dd MMM yyyy hh:mm a').format(booking.purchasedAt)}',
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text('Tickets', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: booking.tickets
                  .map(
                    (ticket) => Chip(
                      label: Text(
                          '${ticket.seatLabel} • ${booking.currency} ${ticket.price}'),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            Text('Audit log', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Column(
              children: booking.auditLog
                  .map(
                    (entry) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.bolt_outlined),
                      title: Text(entry.message),
                      subtitle: Text(
                        '${entry.actor} • ${DateFormat('dd MMM yyyy hh:mm a').format(entry.createdAt)}',
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                FilledButton.tonalIcon(
                  onPressed: onCancel,
                  icon: const Icon(Icons.cancel_schedule_send_outlined),
                  label: const Text('Cancel booking'),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onRefund,
                  icon: const Icon(Icons.currency_rupee),
                  label: const Text('Process refund'),
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Close'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
