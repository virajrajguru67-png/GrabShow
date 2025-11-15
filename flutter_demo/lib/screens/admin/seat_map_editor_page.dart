import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../models/admin_models.dart';
import '../../repositories/admin_repository.dart';
import 'theatre_manager_page.dart';

class SeatMapEditorPage extends StatefulWidget {
  const SeatMapEditorPage({super.key});

  @override
  State<SeatMapEditorPage> createState() => _SeatMapEditorPageState();
}

class _SeatMapEditorPageState extends State<SeatMapEditorPage> {
  late final AdminRepository _repository;
  bool _isLoading = true;
  String? _error;
  List<AdminAuditorium> _auditoriums = const [];
  AdminAuditorium? _selectedAuditorium;
  SeatType _selectedSeatType = SeatType.standard;
  bool _blockMode = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _repository = context.read<AdminRepository>();
    _loadAuditoriums();
  }

  Future<void> _loadAuditoriums() async {
    final token = context.read<AuthController>().accessToken;
    if (token == null) {
      setState(() {
        _error = 'Session expired. Please sign in again.';
        _isLoading = false;
      });
      return;
    }
    final previousId = _selectedAuditorium?.id;
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auditoriums = await _repository.fetchAuditoriums(token);
      if (!mounted) return;
      setState(() {
        _auditoriums = auditoriums;
        _selectedAuditorium =
            auditoriums.firstWhereOrNull((item) => item.id == previousId) ??
                (auditoriums.isNotEmpty ? auditoriums.first : null);
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

  void _updateSeat(SeatRow row, SeatDefinition seat,
      {SeatDefinition? replacement}) {
    if (_selectedAuditorium == null) return;
    final currentLayout = _selectedAuditorium!.layout;
    final SeatDefinition updatedSeat = replacement ??
        (_blockMode
            ? seat.copyWith(blocked: !seat.blocked)
            : seat.copyWith(type: _selectedSeatType, blocked: false));
    final updatedRows = currentLayout.rows.map((existingRow) {
      if (existingRow.rowLabel != row.rowLabel) return existingRow;
      return existingRow.copyWith(
        seats: existingRow.seats.map((existingSeat) {
          if (existingSeat.seatId != seat.seatId) return existingSeat;
          return updatedSeat;
        }).toList(),
      );
    }).toList();

    setState(() {
      final updatedLayout = currentLayout.copyWith(rows: updatedRows);
      _selectedAuditorium =
          _selectedAuditorium!.copyWith(layout: updatedLayout);
      _auditoriums = _auditoriums
          .map((auditorium) => auditorium.id == _selectedAuditorium!.id
              ? auditorium.copyWith(layout: updatedLayout)
              : auditorium)
          .toList();
    });
  }

  Future<void> _saveLayout() async {
    final token = context.read<AuthController>().accessToken;
    final auditorium = _selectedAuditorium;
    if (token == null || auditorium == null) return;
    setState(() => _isSaving = true);
    try {
      final updatedLayout = auditorium.layout.copyWith(
        version: auditorium.layout.version + 1,
      );
      await _repository.updateSeatLayout(token, auditorium.id, updatedLayout);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Layout saved for ${auditorium.name}')),
      );
      setState(() => _isSaving = false);
      await _loadAuditoriums();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save layout: $error')),
      );
    }
  }

  Future<void> _openAuditoriumEditor({AdminAuditorium? auditorium}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => AuditoriumEditorSheet(auditorium: auditorium),
    );
    if (saved == true) {
      await _loadAuditoriums();
    }
  }

  Color _colorForSeat(SeatDefinition seat, ThemeData theme) {
    if (seat.blocked) {
      return theme.colorScheme.errorContainer;
    }
    switch (seat.type) {
      case SeatType.standard:
        return theme.colorScheme.primaryContainer;
      case SeatType.premium:
        return theme.colorScheme.secondaryContainer;
      case SeatType.vip:
        return theme.colorScheme.tertiaryContainer;
      case SeatType.accessible:
        return theme.colorScheme.surfaceContainerHighest;
      case SeatType.couple:
        return theme.colorScheme.inversePrimary;
    }
  }

  IconData _iconForSeat(SeatDefinition seat) {
    if (seat.blocked) return Icons.close;
    switch (seat.type) {
      case SeatType.standard:
        return Icons.event_seat_outlined;
      case SeatType.premium:
        return Icons.chair_alt_outlined;
      case SeatType.vip:
        return Icons.weekend_outlined;
      case SeatType.accessible:
        return Icons.wheelchair_pickup;
      case SeatType.couple:
        return Icons.favorite_border;
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
            const SizedBox(height: 16),
            Text(_error!, style: theme.textTheme.titleMedium),
            const SizedBox(height: 16),
            FilledButton.tonal(
                onPressed: _loadAuditoriums, child: const Text('Retry')),
          ],
        ),
      );
    }

    if (_selectedAuditorium == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.theaters_outlined, size: 72),
              const SizedBox(height: 16),
              Text(
                'Create an auditorium to begin editing seat layouts.',
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () => _openAuditoriumEditor(),
                icon: const Icon(Icons.add),
                label: const Text('Create auditorium'),
              ),
            ],
          ),
        ),
      );
    }

    final layout = _selectedAuditorium!.layout;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<AdminAuditorium>(
                  initialValue: _selectedAuditorium,
                  items: _auditoriums
                      .map(
                        (auditorium) => DropdownMenuItem(
                          value: auditorium,
                          child: Text(
                              '${auditorium.name} • ${auditorium.cinemaName}'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _selectedAuditorium = value),
                  decoration:
                      const InputDecoration(labelText: 'Select auditorium'),
                ),
              ),
              const SizedBox(width: 16),
              FilledButton.tonalIcon(
                onPressed: _loadAuditoriums,
                icon: const Icon(Icons.refresh),
                label: const Text('Reload'),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: () => _openAuditoriumEditor(),
                icon: const Icon(Icons.add_business_outlined),
                label: const Text('New auditorium'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          children: SeatType.values.map((type) {
                            return ChoiceChip(
                              label: Text(type.name.toUpperCase()),
                              selected:
                                  !_blockMode && _selectedSeatType == type,
                              onSelected: (_) {
                                setState(() {
                                  _blockMode = false;
                                  _selectedSeatType = type;
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      FilterChip(
                        label: const Text('Block seats'),
                        selected: _blockMode,
                        onSelected: (value) =>
                            setState(() => _blockMode = value),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        for (final row in layout.rows) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 32,
                                  child: Text(
                                    row.rowLabel,
                                    style: theme.textTheme.titleSmall,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: row.seats.map((seat) {
                                    final color = _colorForSeat(seat, theme);
                                    return GestureDetector(
                                      onTap: () => _updateSeat(row, seat),
                                      onLongPress: () => _updateSeat(
                                        row,
                                        seat,
                                        replacement: seat.copyWith(
                                            isAisle: !seat.isAisle),
                                      ),
                                      child: AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 150),
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: color,
                                          borderRadius: BorderRadius.circular(
                                              seat.isAisle ? 4 : 12),
                                          border: Border.all(
                                            color: seat.isAisle
                                                ? theme.colorScheme.outline
                                                : theme.colorScheme.surface,
                                          ),
                                        ),
                                        child: Icon(
                                          _iconForSeat(seat),
                                          color: seat.blocked
                                              ? theme
                                                  .colorScheme.onErrorContainer
                                              : theme.colorScheme
                                                  .onPrimaryContainer,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Text('Layout v${layout.version}',
                          style: theme.textTheme.bodyMedium),
                      const Spacer(),
                      FilledButton(
                        onPressed: _isSaving ? null : _saveLayout,
                        child: _isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Save layout'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
