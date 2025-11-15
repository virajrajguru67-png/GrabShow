import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../models/admin_models.dart';
import '../../repositories/admin_repository.dart';
import 'movies_manager_page.dart';

class TheatreManagerPage extends StatefulWidget {
  const TheatreManagerPage({super.key});

  @override
  State<TheatreManagerPage> createState() => _TheatreManagerPageState();
}

class _TheatreManagerPageState extends State<TheatreManagerPage> {
  late final AdminRepository _repository;
  bool _isLoading = true;
  String? _error;
  List<AdminAuditorium> _auditoriums = const [];

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
        _error = 'Your admin session expired. Please sign in again.';
        _isLoading = false;
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final auditoriums = await _repository.fetchAuditoriums(token);
      if (!mounted) return;
      setState(() {
        _auditoriums = auditoriums;
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

  Future<void> _openEditor({AdminAuditorium? auditorium}) async {
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
                onPressed: _loadAuditoriums,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_auditoriums.isEmpty) {
      return EmptyState(
        icon: Icons.theaters_outlined,
        title: 'No auditoriums yet',
        description:
            'Create auditoriums to organise screens across your theatres, then design seat layouts.',
        actionLabel: 'Create auditorium',
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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theatre inventory',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  Text(
                    'Manage auditoriums, capacities, and cinema metadata.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadAuditoriums,
                    label: const Text('Refresh'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _openEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add auditorium'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              clipBehavior: Clip.antiAlias,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _auditoriums.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final auditorium = _auditoriums[index];
                  final stats = auditorium.stats;
                  final updatedAt = DateFormat('d MMM • h:mm a')
                      .format(auditorium.layout.updatedAt);
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(auditorium.name.isNotEmpty
                          ? auditorium.name[0].toUpperCase()
                          : '?'),
                    ),
                    title: Text(auditorium.name),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                              '${auditorium.cinemaName} • Screen ID ${auditorium.cinemaId}'),
                          const SizedBox(height: 4),
                          Text(
                              'Capacity ${auditorium.capacity} • Layout v${auditorium.layout.version} • Updated $updatedAt'),
                          if (stats != null) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                Chip(
                                  avatar: const Icon(Icons.event_seat_outlined,
                                      size: 16),
                                  label:
                                      Text('${stats.availableSeats} available'),
                                ),
                                Chip(
                                  avatar: const Icon(Icons.block_outlined,
                                      size: 16),
                                  label: Text('${stats.blockedSeats} blocked'),
                                ),
                              ],
                            ),
                          ],
                          if (stats == null) ...[
                            const SizedBox(height: 6),
                            Text(
                              'No layout metrics yet. Design the seat map to populate stats.',
                              style: theme.textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    trailing: IconButton(
                      tooltip: 'Edit auditorium',
                      icon: const Icon(Icons.edit_outlined),
                      onPressed: () => _openEditor(auditorium: auditorium),
                    ),
                    onTap: () => _openEditor(auditorium: auditorium),
                    isThreeLine: true,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
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

class AuditoriumEditorSheet extends StatefulWidget {
  const AuditoriumEditorSheet({super.key, this.auditorium});

  final AdminAuditorium? auditorium;

  @override
  State<AuditoriumEditorSheet> createState() => _AuditoriumEditorSheetState();
}

class _AuditoriumEditorSheetState extends State<AuditoriumEditorSheet> {
  late final TextEditingController _cinemaIdController;
  late final TextEditingController _cinemaNameController;
  late final TextEditingController _nameController;
  late final TextEditingController _capacityController;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _cinemaIdController =
        TextEditingController(text: widget.auditorium?.cinemaId ?? '');
    _cinemaNameController =
        TextEditingController(text: widget.auditorium?.cinemaName ?? '');
    _nameController =
        TextEditingController(text: widget.auditorium?.name ?? '');
    _capacityController = TextEditingController(
        text: widget.auditorium?.capacity.toString() ?? '');
  }

  @override
  void dispose() {
    _cinemaIdController.dispose();
    _cinemaNameController.dispose();
    _nameController.dispose();
    _capacityController.dispose();
    super.dispose();
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
    final capacity = int.tryParse(_capacityController.text.trim());
    if (capacity == null || capacity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capacity must be a positive number.')),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      if (widget.auditorium == null) {
        await repository.createAuditorium(
          token,
          cinemaId: _cinemaIdController.text.trim(),
          cinemaName: _cinemaNameController.text.trim(),
          name: _nameController.text.trim(),
          capacity: capacity,
        );
      } else {
        await repository.updateAuditorium(
          token,
          widget.auditorium!.id,
          cinemaId: _cinemaIdController.text.trim(),
          cinemaName: _cinemaNameController.text.trim(),
          name: _nameController.text.trim(),
          capacity: capacity,
        );
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.auditorium == null
              ? 'Auditorium created. Design the layout from the Seat maps tab.'
              : 'Auditorium updated'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save auditorium: $error')),
      );
      setState(() => _isSaving = false);
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
                widget.auditorium == null
                    ? 'Create auditorium'
                    : 'Edit auditorium',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _cinemaNameController,
                decoration: const InputDecoration(
                  labelText: 'Cinema name',
                  helperText: 'e.g. StreamFlix Downtown',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cinemaIdController,
                decoration: const InputDecoration(
                  labelText: 'Cinema ID',
                  helperText: 'Reference ID used for reporting (e.g. SFD-001)',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Auditorium name',
                  helperText: 'e.g. Screen 1 or IMAX Experience',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _capacityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Seating capacity',
                  helperText:
                      'Used for occupancy stats; seat layout can override this later.',
                ),
                validator: (value) => value == null || value.isEmpty
                    ? 'Required'
                    : (int.tryParse(value) == null ? 'Enter a number' : null),
              ),
              const SizedBox(height: 16),
              Text(
                'After saving, switch to the Seat maps tab to upload or design the seating layout.',
                style: theme.textTheme.bodySmall,
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
                    : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
