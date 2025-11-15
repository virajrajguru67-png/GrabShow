import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../models/admin_models.dart';
import '../../repositories/admin_repository.dart';

class NotificationBroadcastPage extends StatefulWidget {
  const NotificationBroadcastPage({super.key});

  @override
  State<NotificationBroadcastPage> createState() =>
      _NotificationBroadcastPageState();
}

class _NotificationBroadcastPageState extends State<NotificationBroadcastPage> {
  late final AdminRepository _repository;
  bool _isLoading = true;
  String? _error;
  List<NotificationCampaign> _campaigns = const [];
  List<CampaignSegment> _segments = const [];

  @override
  void initState() {
    super.initState();
    _repository = context.read<AdminRepository>();
    _loadData();
  }

  Future<void> _loadData() async {
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
        _repository.fetchCampaigns(token),
        _repository.fetchSegments(token),
      ]);
      if (!mounted) return;
      setState(() {
        _campaigns = results[0] as List<NotificationCampaign>;
        _segments = results[1] as List<CampaignSegment>;
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

  Future<void> _composeCampaign() async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => ComposeCampaignSheet(segments: _segments),
    );
    if (saved == true) {
      await _loadData();
    }
  }

  Color _statusColor(NotificationCampaign campaign, ThemeData theme) {
    switch (campaign.status) {
      case CampaignStatus.draft:
        return theme.colorScheme.surfaceVariant;
      case CampaignStatus.scheduled:
        return theme.colorScheme.secondaryContainer;
      case CampaignStatus.inFlight:
        return theme.colorScheme.primaryContainer;
      case CampaignStatus.completed:
        return theme.colorScheme.tertiaryContainer;
    }
  }

  String _statusLabel(NotificationCampaign campaign) {
    switch (campaign.status) {
      case CampaignStatus.draft:
        return 'Draft';
      case CampaignStatus.scheduled:
        return 'Scheduled';
      case CampaignStatus.inFlight:
        return 'In flight';
      case CampaignStatus.completed:
        return 'Completed';
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
                onPressed: _loadData, child: const Text('Retry')),
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
              Text('Notification broadcasts',
                  style: theme.textTheme.headlineSmall),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadData,
                    label: const Text('Reload'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _segments.isEmpty ? null : _composeCampaign,
                    icon: const Icon(Icons.campaign_outlined),
                    label: const Text('Compose campaign'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _campaigns.isEmpty
                ? const Center(
                    child: Text(
                        'No campaigns scheduled yet. Compose your first broadcast.'))
                : ListView.separated(
                    itemCount: _campaigns.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final campaign = _campaigns[index];
                      final segment = _segments.firstWhere(
                          (segment) => segment.id == campaign.segmentId,
                          orElse: () => _segments.first);
                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      campaign.name,
                                      style: theme.textTheme.titleMedium,
                                    ),
                                  ),
                                  Chip(
                                    label: Text(_statusLabel(campaign)),
                                    backgroundColor:
                                        _statusColor(campaign, theme),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(campaign.subject),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 8,
                                runSpacing: 4,
                                children: [
                                  for (final channel in campaign.channels)
                                    Chip(
                                      avatar: const Icon(Icons.send_outlined,
                                          size: 16),
                                      label: Text(channel.name.toUpperCase()),
                                    ),
                                  Chip(
                                    avatar: const Icon(Icons.people_outline,
                                        size: 16),
                                    label: Text(segment.name),
                                  ),
                                  Chip(
                                    avatar: const Icon(Icons.bar_chart_outlined,
                                        size: 16),
                                    label: Text(
                                        'Sent ${campaign.sent} • Open ${campaign.opened} • Click ${campaign.clicked}'),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                campaign.scheduledAt != null
                                    ? 'Scheduled ${DateFormat('dd MMM yyyy, hh:mm a').format(campaign.scheduledAt!)}'
                                    : 'Created ${DateFormat('dd MMM yyyy, hh:mm a').format(campaign.createdAt)}',
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class ComposeCampaignSheet extends StatefulWidget {
  const ComposeCampaignSheet({super.key, required this.segments});

  final List<CampaignSegment> segments;

  @override
  State<ComposeCampaignSheet> createState() => _ComposeCampaignSheetState();
}

class _ComposeCampaignSheetState extends State<ComposeCampaignSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subjectController = TextEditingController();
  final Set<CampaignChannel> _channels = {CampaignChannel.email};
  CampaignSegment? _selectedSegment;
  DateTime? _scheduledAt;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _selectedSegment =
        widget.segments.isNotEmpty ? widget.segments.first : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _pickSchedule() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null) return;
    setState(() {
      _scheduledAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final token = context.read<AuthController>().accessToken;
    final segment = _selectedSegment;
    if (token == null || segment == null) return;
    final repository = context.read<AdminRepository>();
    setState(() => _isSaving = true);
    try {
      await repository.createCampaign(
        token,
        name: _nameController.text.trim(),
        subject: _subjectController.text.trim(),
        channels: _channels.toList(),
        segmentId: segment.id,
        scheduledAt: _scheduledAt,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Campaign scheduled')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to schedule campaign: $error')),
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
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Compose campaign', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Campaign name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _subjectController,
                decoration: const InputDecoration(labelText: 'Subject / title'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              Text('Channels', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: CampaignChannel.values.map((channel) {
                  return FilterChip(
                    label: Text(channel.name.toUpperCase()),
                    selected: _channels.contains(channel),
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _channels.add(channel);
                        } else if (_channels.length > 1) {
                          _channels.remove(channel);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<CampaignSegment>(
                value: _selectedSegment,
                decoration: const InputDecoration(labelText: 'Target segment'),
                items: widget.segments
                    .map((segment) => DropdownMenuItem(
                          value: segment,
                          child: Text(segment.name),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedSegment = value),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Schedule'),
                subtitle: Text(
                  _scheduledAt != null
                      ? DateFormat('dd MMM yyyy, hh:mm a').format(_scheduledAt!)
                      : 'Send immediately',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_calendar_outlined),
                  onPressed: _pickSchedule,
                ),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Schedule campaign'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
