import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../controllers/auth_controller.dart';
import '../../models/admin_models.dart';
import '../../repositories/admin_repository.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  late final AdminRepository _repository;
  bool _isLoading = true;
  String? _error;
  List<AdminUser> _users = const [];

  @override
  void initState() {
    super.initState();
    _repository = context.read<AdminRepository>();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
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
      final data = await _repository.fetchAdminUsers(token);
      if (!mounted) return;
      setState(() {
        _users = data;
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

  Future<void> _inviteUser() async {
    final invited = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => const _InviteAdminSheet(),
    );
    if (invited == true) {
      await _loadUsers();
    }
  }

  Future<void> _toggleRole(AdminUser user, AdminRole role) async {
    final token = context.read<AuthController>().accessToken;
    if (token == null) return;
    final roles = user.roles.contains(role)
        ? user.roles.where((existing) => existing != role).toList()
        : [...user.roles, role];
    try {
      await _repository.updateAdminUser(token, user.id, roles: roles);
      await _loadUsers();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update roles: $error')),
      );
    }
  }

  Future<void> _updateStatus(AdminUser user, String status) async {
    final token = context.read<AuthController>().accessToken;
    if (token == null) return;
    try {
      await _repository.updateAdminUser(token, user.id, status: status);
      await _loadUsers();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $error')),
      );
    }
  }

  String _roleLabel(AdminRole role) {
    switch (role) {
      case AdminRole.owner:
        return 'Owner';
      case AdminRole.finance:
        return 'Finance';
      case AdminRole.content:
        return 'Content';
      case AdminRole.operations:
        return 'Operations';
      case AdminRole.support:
        return 'Support';
      case AdminRole.marketing:
        return 'Marketing';
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
                onPressed: _loadUsers, child: const Text('Retry')),
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
              Text('Admin access control',
                  style: theme.textTheme.headlineSmall),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    onPressed: _loadUsers,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh'),
                  ),
                  const SizedBox(width: 12),
                  FilledButton.icon(
                    onPressed: _inviteUser,
                    icon: const Icon(Icons.person_add_alt),
                    label: const Text('Invite admin'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _users.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = _users[index];
                  return ListTile(
                    leading: CircleAvatar(
                      child: Text(user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : '?'),
                    ),
                    title: Text(user.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.email),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            for (final role in AdminRole.values)
                              FilterChip(
                                label: Text(_roleLabel(role)),
                                selected: user.roles.contains(role),
                                onSelected: (_) => _toggleRole(user, role),
                              ),
                          ],
                        ),
                      ],
                    ),
                    trailing: DropdownButton<String>(
                      value: user.status,
                      items: const [
                        DropdownMenuItem(
                            value: 'active', child: Text('Active')),
                        DropdownMenuItem(
                            value: 'invited', child: Text('Invited')),
                        DropdownMenuItem(
                            value: 'disabled', child: Text('Disabled')),
                      ],
                      onChanged: (value) =>
                          _updateStatus(user, value ?? user.status),
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

class _InviteAdminSheet extends StatefulWidget {
  const _InviteAdminSheet();

  @override
  State<_InviteAdminSheet> createState() => _InviteAdminSheetState();
}

class _InviteAdminSheetState extends State<_InviteAdminSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final Set<AdminRole> _selectedRoles = {AdminRole.operations};
  bool _isSaving = false;

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _invite() async {
    if (!_formKey.currentState!.validate()) return;
    final token = context.read<AuthController>().accessToken;
    if (token == null) return;
    final repository = context.read<AdminRepository>();
    setState(() => _isSaving = true);
    try {
      await repository.inviteAdminUser(
        token,
        email: _emailController.text.trim(),
        name: _nameController.text.trim(),
        roles: _selectedRoles.toList(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Invitation sent to ${_emailController.text.trim()}')),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to invite admin: $error')),
      );
    }
  }

  String _roleLabel(AdminRole role) {
    switch (role) {
      case AdminRole.owner:
        return 'Owner';
      case AdminRole.finance:
        return 'Finance';
      case AdminRole.content:
        return 'Content';
      case AdminRole.operations:
        return 'Operations';
      case AdminRole.support:
        return 'Support';
      case AdminRole.marketing:
        return 'Marketing';
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
              Text('Invite admin', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Full name'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: (value) => value == null || !value.contains('@')
                    ? 'Enter a valid email'
                    : null,
              ),
              const SizedBox(height: 12),
              Text('Roles', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: AdminRole.values.map((role) {
                  final selected = _selectedRoles.contains(role);
                  return FilterChip(
                    label: Text(_roleLabel(role)),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedRoles.add(role);
                        } else if (_selectedRoles.length > 1) {
                          _selectedRoles.remove(role);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: _isSaving ? null : _invite,
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Send invite'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
