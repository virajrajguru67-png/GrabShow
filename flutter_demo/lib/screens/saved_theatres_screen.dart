import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import '../theme/app_colors.dart';
import '../theme/design_tokens.dart';

class SavedTheatresScreen extends StatefulWidget {
  const SavedTheatresScreen({super.key});

  static const route = '/saved-theatres';

  @override
  State<SavedTheatresScreen> createState() => _SavedTheatresScreenState();
}

class _SavedTheatresScreenState extends State<SavedTheatresScreen> {
  final List<Theatre> _savedTheatres = [
    Theatre(
      id: '1',
      name: 'PVR Cinemas',
      address: '123 Main Street, Downtown',
      distance: '2.5 km',
      isDefault: true,
    ),
    Theatre(
      id: '2',
      name: 'INOX Multiplex',
      address: '456 Park Avenue, Midtown',
      distance: '5.1 km',
      isDefault: false,
    ),
    Theatre(
      id: '3',
      name: 'Cinepolis',
      address: '789 Broadway, Uptown',
      distance: '8.3 km',
      isDefault: false,
    ),
  ];

  void _setDefault(String id) {
    setState(() {
      for (var theatre in _savedTheatres) {
        theatre.isDefault = theatre.id == id;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Default theatre updated')),
    );
  }

  void _removeTheatre(String id) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Remove theatre'),
        content: const Text('Are you sure you want to remove this theatre from your saved list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _savedTheatres.removeWhere((t) => t.id == id);
              });
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theatre removed')),
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
        title: const Text('Seved Thearins'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your saved theatres',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 18),
            if (_savedTheatres.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_off_rounded,
                        size: 64,
                        color: AppColors.textMuted,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No saved theatres',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Save your favorite theatres for quick access',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._savedTheatres.map(
                (theatre) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _TheatreCard(
                    theatre: theatre,
                    onSetDefault: () => _setDefault(theatre.id),
                    onRemove: () => _removeTheatre(theatre.id),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            AppButton(
              label: 'Add theatre',
              icon: Icons.add_location_alt_rounded,
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Search theatres to add')),
                );
              },
              fullWidth: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _TheatreCard extends StatelessWidget {
  const _TheatreCard({
    required this.theatre,
    required this.onSetDefault,
    required this.onRemove,
  });

  final Theatre theatre;
  final VoidCallback onSetDefault;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theatre.isDefault
              ? AppColors.accent
              : AppColors.surfaceHighlight,
        ),
        boxShadow: theatre.isDefault ? [DSShadows.sm] : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.accent,
                  size: 24,
                ),
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
                            theatre.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (theatre.isDefault)
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
                    const SizedBox(height: 4),
                    Text(
                      theatre.address,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.navigation_rounded,
                          size: 14,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          theatre.distance,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
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
                  if (!theatre.isDefault)
                    const PopupMenuItem(
                      value: 'default',
                      child: Row(
                        children: [
                          Icon(Icons.star_outline_rounded, size: 20),
                          SizedBox(width: 8),
                          Text('Set as default'),
                        ],
                      ),
                    ),
                  const PopupMenuItem(
                    value: 'remove',
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
                  } else if (value == 'remove') {
                    onRemove();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class Theatre {
  Theatre({
    required this.id,
    required this.name,
    required this.address,
    required this.distance,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String address;
  final String distance;
  bool isDefault;
}

