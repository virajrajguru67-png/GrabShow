import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../models/admin_models.dart';
import '../../repositories/admin_repository.dart';
import 'movies_manager_page.dart';

class ShowtimeSchedulerPage extends StatefulWidget {
  const ShowtimeSchedulerPage({super.key});

  @override
  State<ShowtimeSchedulerPage> createState() => _ShowtimeSchedulerPageState();
}

class _ShowtimeSchedulerPageState extends State<ShowtimeSchedulerPage> {
  late final AdminRepository _repository;
  bool _isLoading = true;
  String? _error;
  List<AdminShowtime> _showtimes = const [];
  List<AdminMovie> _movies = const [];
  List<AdminAuditorium> _auditoriums = const [];

  @override
  void initState() {
    super.initState();
    _repository = context.read<AdminRepository>();
    _loadAll();
  }

  Future<void> _loadAll() async {
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
      final results = await Future.wait([
        _repository.fetchShowtimes(token),
        _repository.fetchMovies(token),
        _repository.fetchAuditoriums(token),
      ]);
      if (!mounted) return;
      setState(() {
        _showtimes = results[0] as List<AdminShowtime>;
        _movies = results[1] as List<AdminMovie>;
        _auditoriums = results[2] as List<AdminAuditorium>;
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

  Future<void> _openEditor({AdminShowtime? showtime}) async {
    if (_movies.isEmpty || _auditoriums.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Add a movie and auditorium before scheduling showtimes.')),
      );
      return;
    }
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ShowtimeEditorSheet(
        showtime: showtime,
        movies: _movies,
        auditoriums: _auditoriums,
      ),
    );
    if (saved == true) {
      await _loadAll();
    }
  }

  Future<void> _updateStatus(
      AdminShowtime showtime, ShowtimeStatus status) async {
    final token = context.read<AuthController>().accessToken;
    if (token == null) return;
    try {
      await _repository.updateShowtime(token, showtime.id, {
        'status': showtimeStatusToJson(status),
      });
      if (!mounted) return;
      await _loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Showtime marked as ${status.name}')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update showtime: $error')),
      );
    }
  }

  Future<void> _deleteShowtime(AdminShowtime showtime) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete showtime'),
        content: Text(
          'Delete ${showtime.movieTitle} • ${DateFormat('EEE, dd MMM • hh:mm a').format(showtime.startsAt)}?',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirm != true) return;

    final token = context.read<AuthController>().accessToken;
    if (token == null) return;
    try {
      await _repository.deleteShowtime(token, showtime.id);
      if (!mounted) return;
      await _loadAll();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Showtime deleted')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete showtime: $error')),
      );
    }
  }

  Color _statusColor(ShowtimeStatus status, ThemeData theme) {
    switch (status) {
      case ShowtimeStatus.onSale:
        return theme.colorScheme.primaryContainer;
      case ShowtimeStatus.completed:
        return theme.colorScheme.secondaryContainer;
      case ShowtimeStatus.cancelled:
        return theme.colorScheme.errorContainer;
      case ShowtimeStatus.scheduled:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }

  String _statusLabel(ShowtimeStatus status) {
    switch (status) {
      case ShowtimeStatus.onSale:
        return 'On sale';
      case ShowtimeStatus.completed:
        return 'Completed';
      case ShowtimeStatus.cancelled:
        return 'Cancelled';
      case ShowtimeStatus.scheduled:
        return 'Scheduled';
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
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 64),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                  onPressed: _loadAll, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    if (_showtimes.isEmpty) {
      return EmptyState(
        icon: Icons.schedule_outlined,
        title: 'No showtimes yet',
        description:
            'Create schedules by pairing a movie with an auditorium and define pricing tiers per seat type.',
        actionLabel: 'Schedule showtime',
        onAction: () => _openEditor(),
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
              Text('Showtime planning', style: theme.textTheme.headlineSmall),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadAll,
                    label: const Text('Refresh'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _openEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('Schedule'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: ListView.separated(
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                itemCount: _showtimes.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final showtime = _showtimes[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.movie,
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                    title: Text(showtime.movieTitle),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${showtime.auditoriumName} • ${DateFormat('EEE, dd MMM • hh:mm a').format(showtime.startsAt)}',
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Chip(
                              label: Text(_statusLabel(showtime.status)),
                              backgroundColor:
                                  _statusColor(showtime.status, theme),
                            ),
                            Chip(
                              label: Text(
                                  'Base ₹${showtime.basePrice.toStringAsFixed(0)}'),
                            ),
                            Chip(
                              label: Text(
                                  '${showtime.pricingTiers.length} pricing tiers'),
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        switch (value) {
                          case 'edit':
                            _openEditor(showtime: showtime);
                            break;
                          case 'onsale':
                            _updateStatus(showtime, ShowtimeStatus.onSale);
                            break;
                          case 'cancel':
                            _updateStatus(showtime, ShowtimeStatus.cancelled);
                            break;
                          case 'delete':
                            _deleteShowtime(showtime);
                            break;
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                            value: 'edit', child: Text('Edit details')),
                        if (showtime.status != ShowtimeStatus.onSale)
                          const PopupMenuItem(
                              value: 'onsale', child: Text('Mark on sale')),
                        if (showtime.status != ShowtimeStatus.cancelled)
                          const PopupMenuItem(
                              value: 'cancel', child: Text('Cancel show')),
                        const PopupMenuDivider(),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                    onTap: () => _openEditor(showtime: showtime),
                    isThreeLine: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
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

class ShowtimeEditorSheet extends StatefulWidget {
  const ShowtimeEditorSheet({
    super.key,
    this.showtime,
    required this.movies,
    required this.auditoriums,
  });

  final AdminShowtime? showtime;
  final List<AdminMovie> movies;
  final List<AdminAuditorium> auditoriums;

  @override
  State<ShowtimeEditorSheet> createState() => _ShowtimeEditorSheetState();
}

class _ShowtimeEditorSheetState extends State<ShowtimeEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late AdminMovie _selectedMovie;
  late AdminAuditorium _selectedAuditorium;
  late DateTime _startsAt;
  late DateTime _endsAt;
  late double _basePrice;
  late Map<SeatType, TextEditingController> _tierControllers;
  late ShowtimeStatus _status;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedMovie = widget.movies.firstWhere(
      (movie) => movie.id == widget.showtime?.movieId,
      orElse: () => widget.movies.first,
    );
    _selectedAuditorium = widget.auditoriums.firstWhere(
      (aud) => aud.id == widget.showtime?.auditoriumId,
      orElse: () => widget.auditoriums.first,
    );
    _startsAt = widget.showtime?.startsAt ??
        DateTime.now().add(const Duration(hours: 6));
    _endsAt =
        widget.showtime?.endsAt ?? _startsAt.add(const Duration(hours: 2));
    _basePrice = widget.showtime?.basePrice ?? 200;
    _status = widget.showtime?.status ?? ShowtimeStatus.scheduled;

    _tierControllers = {
      for (final type in SeatType.values)
        type: TextEditingController(
          text: (() {
            PricingTier? existing;
            if (widget.showtime != null) {
              try {
                existing = widget.showtime!.pricingTiers
                    .firstWhere((tier) => tier.seatTypes.contains(type));
              } catch (_) {
                existing = null;
              }
            }
            return (existing?.price ?? _defaultPriceForType(type))
                .toStringAsFixed(0);
          })(),
        ),
    };
  }

  double _defaultPriceForType(SeatType type) {
    switch (type) {
      case SeatType.accessible:
        return 150;
      case SeatType.standard:
        return 200;
      case SeatType.premium:
        return 320;
      case SeatType.vip:
        return 420;
      case SeatType.couple:
        return 500;
    }
  }

  @override
  void dispose() {
    for (final controller in _tierControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDateTime({
    required bool isStart,
  }) async {
    final initial = isStart ? _startsAt : _endsAt;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;
    final result =
        DateTime(date.year, date.month, date.day, time.hour, time.minute);
    setState(() {
      if (isStart) {
        _startsAt = result;
        if (!_endsAt.isAfter(_startsAt)) {
          _endsAt = _startsAt.add(const Duration(hours: 2));
        }
      } else {
        _endsAt = result;
      }
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final token = context.read<AuthController>().accessToken;
    if (token == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session expired. Please sign in again.')),
      );
      return;
    }

    final repository = context.read<AdminRepository>();
    setState(() => _isSaving = true);

    final pricingTiers = SeatType.values.map((type) {
      final price = double.tryParse(_tierControllers[type]!.text.trim()) ??
          _defaultPriceForType(type);
      return {
        'label': type.name.toUpperCase(),
        'price': price,
        'seatTypes': [type.name],
      };
    }).toList();

    final payload = {
      'movieId': _selectedMovie.id,
      'auditoriumId': _selectedAuditorium.id,
      'startsAt': _startsAt.toIso8601String(),
      'endsAt': _endsAt.toIso8601String(),
      'basePrice': _basePrice,
      'status': showtimeStatusToJson(_status),
      'pricingTiers': pricingTiers,
    };

    try {
      if (widget.showtime == null) {
        await repository.createShowtime(token, payload);
      } else {
        await repository.updateShowtime(token, widget.showtime!.id, payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save showtime: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 28,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.showtime == null ? 'Schedule showtime' : 'Edit showtime',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              DropdownButtonFormField<AdminMovie>(
                key: ValueKey(_selectedMovie.id),
                initialValue: _selectedMovie,
                items: [
                  for (final movie in widget.movies)
                    DropdownMenuItem(value: movie, child: Text(movie.title)),
                ],
                onChanged: (movie) =>
                    setState(() => _selectedMovie = movie ?? _selectedMovie),
                decoration: const InputDecoration(labelText: 'Movie'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AdminAuditorium>(
                key: ValueKey(_selectedAuditorium.id),
                initialValue: _selectedAuditorium,
                items: [
                  for (final auditorium in widget.auditoriums)
                    DropdownMenuItem(
                      value: auditorium,
                      child:
                          Text('${auditorium.name} • ${auditorium.cinemaName}'),
                    ),
                ],
                onChanged: (auditorium) => setState(() =>
                    _selectedAuditorium = auditorium ?? _selectedAuditorium),
                decoration: const InputDecoration(labelText: 'Auditorium'),
              ),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Starts at'),
                subtitle: Text(
                    DateFormat('EEE, dd MMM yyyy • hh:mm a').format(_startsAt)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_calendar_outlined),
                  onPressed: () => _pickDateTime(isStart: true),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ends at'),
                subtitle: Text(
                    DateFormat('EEE, dd MMM yyyy • hh:mm a').format(_endsAt)),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_calendar_outlined),
                  onPressed: () => _pickDateTime(isStart: false),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                initialValue: _basePrice.toStringAsFixed(0),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Base price (INR)',
                ),
                onChanged: (value) =>
                    _basePrice = double.tryParse(value) ?? _basePrice,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<ShowtimeStatus>(
                key: ValueKey(_status),
                initialValue: _status,
                items: ShowtimeStatus.values
                    .map(
                      (status) => DropdownMenuItem(
                        value: status,
                        child: Text(_statusLabel(status)),
                      ),
                    )
                    .toList(),
                onChanged: (status) =>
                    setState(() => _status = status ?? _status),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
              const SizedBox(height: 20),
              Text(
                'Pricing tiers',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 16,
                runSpacing: 12,
                children: [
                  for (final entry in _tierControllers.entries)
                    SizedBox(
                      width: 150,
                      child: TextFormField(
                        controller: entry.value,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: '${entry.key.name.toUpperCase()} (₹)',
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save showtime'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusLabel(ShowtimeStatus status) {
    switch (status) {
      case ShowtimeStatus.onSale:
        return 'On sale';
      case ShowtimeStatus.completed:
        return 'Completed';
      case ShowtimeStatus.cancelled:
        return 'Cancelled';
      case ShowtimeStatus.scheduled:
        return 'Scheduled';
    }
  }
}
