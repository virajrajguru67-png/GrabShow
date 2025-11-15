import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../models/admin_models.dart';
import '../../repositories/admin_repository.dart';

class MoviesManagerPage extends StatefulWidget {
  const MoviesManagerPage({super.key});

  @override
  State<MoviesManagerPage> createState() => _MoviesManagerPageState();
}

class _MoviesManagerPageState extends State<MoviesManagerPage> {
  late final AdminRepository _repository;
  bool _isLoading = true;
  String? _error;
  List<AdminMovie> _movies = const [];

  @override
  void initState() {
    super.initState();
    _repository = context.read<AdminRepository>();
    _loadMovies();
  }

  Future<void> _loadMovies() async {
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
      final movies = await _repository.fetchMovies(token);
      if (!mounted) return;
      setState(() {
        _movies = movies;
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

  Future<void> _openEditor({AdminMovie? movie}) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => MovieEditorSheet(movie: movie),
    );
    if (saved == true) {
      await _loadMovies();
    }
  }

  Future<void> _deleteMovie(AdminMovie movie) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete movie'),
        content: Text(
          'Are you sure you want to delete "${movie.title}"? Associated showtimes will also be removed.',
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
      await _repository.deleteMovie(token, movie.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${movie.title} deleted')),
      );
      await _loadMovies();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _loadMovies,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_movies.isEmpty) {
      return EmptyState(
        icon: Icons.movie_creation_outlined,
        title: 'No movies yet',
        description:
            'Create your first title to start scheduling showtimes and selling tickets on StreamFlix.',
        actionLabel: 'Add movie',
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
              Text(
                'Movie catalogue',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.refresh),
                    onPressed: _loadMovies,
                    label: const Text('Refresh'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: () => _openEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('Add movie'),
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
                itemCount: _movies.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final movie = _movies[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(movie.title.isNotEmpty
                          ? movie.title[0].toUpperCase()
                          : '?'),
                    ),
                    title: Text(movie.title),
                    subtitle: Text(
                      [
                        if (movie.genres.isNotEmpty) movie.genres.join(', '),
                        if (movie.durationMinutes != null)
                          '${movie.durationMinutes} min',
                        'Status: ${movie.status.name}',
                      ].where((part) => part.isNotEmpty).join(' • '),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          _openEditor(movie: movie);
                        } else if (value == 'delete') {
                          _deleteMovie(movie);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                    onTap: () => _openEditor(movie: movie),
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

class MovieEditorSheet extends StatefulWidget {
  const MovieEditorSheet({super.key, this.movie});

  final AdminMovie? movie;

  @override
  State<MovieEditorSheet> createState() => _MovieEditorSheetState();
}

class _MovieEditorSheetState extends State<MovieEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _slugController;
  late final TextEditingController _genresController;
  late final TextEditingController _languagesController;
  late final TextEditingController _runtimeController;
  late bool _isPublished;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.movie?.title ?? '');
    _slugController = TextEditingController(text: widget.movie?.slug ?? '');
    _genresController = TextEditingController(
      text: widget.movie?.genres.join(', ') ?? '',
    );
    _languagesController = TextEditingController(
      text: widget.movie?.languages.join(', ') ?? '',
    );
    _runtimeController = TextEditingController(
      text: widget.movie?.durationMinutes?.toString() ?? '',
    );
    _isPublished = widget.movie?.status == MovieStatus.published;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _slugController.dispose();
    _genresController.dispose();
    _languagesController.dispose();
    _runtimeController.dispose();
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
    setState(() => _isSaving = true);

    final payload = {
      'title': _titleController.text.trim(),
      'slug': _slugController.text.trim(),
      'genres': _genresController.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(),
      'languages': _languagesController.text
          .split(',')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toList(),
      'durationMinutes': int.tryParse(_runtimeController.text.trim()),
      'status': _isPublished ? 'published' : 'draft',
    };

    try {
      if (widget.movie == null) {
        await repository.createMovie(token, payload);
      } else {
        await repository.updateMovie(token, widget.movie!.id, payload);
      }
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(widget.movie == null ? 'Movie created' : 'Movie updated'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save movie: $error')),
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
                widget.movie == null ? 'Create movie' : 'Edit movie',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
                onChanged: (value) {
                  if (widget.movie != null) return;
                  if (_slugController.text.isEmpty) {
                    _slugController.text =
                        value.toLowerCase().replaceAll(RegExp(r'\s+'), '-');
                  }
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _slugController,
                decoration: const InputDecoration(labelText: 'Slug'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _genresController,
                decoration: const InputDecoration(
                  labelText: 'Genres',
                  helperText: 'Separate with commas',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _languagesController,
                decoration: const InputDecoration(
                  labelText: 'Languages',
                  helperText: 'Separate with commas',
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _runtimeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Duration (minutes)',
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                value: _isPublished,
                onChanged: (value) => setState(() => _isPublished = value),
                title: const Text('Published'),
                subtitle:
                    const Text('Published titles are visible to customers'),
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

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 72, color: theme.colorScheme.primary),
            const SizedBox(height: 20),
            Text(
              title,
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text(
              description,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onAction,
              child: Text(actionLabel),
            ),
          ],
        ),
      ),
    );
  }
}
