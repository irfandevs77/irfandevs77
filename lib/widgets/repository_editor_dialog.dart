import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/repository.dart';
import '../services/firebase_service.dart';
import '../theme/app_theme.dart';

class RepositoryEditorDialog extends StatefulWidget {
  const RepositoryEditorDialog({super.key, this.repository});

  final Repository? repository;

  @override
  State<RepositoryEditorDialog> createState() => _RepositoryEditorDialogState();
}

class _RepositoryEditorDialogState extends State<RepositoryEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _language;
  late final TextEditingController _id;
  late bool _isPublic;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final repository = widget.repository;
    _name = TextEditingController(text: repository?.name ?? '');
    _description = TextEditingController(text: repository?.description ?? '');
    _language = TextEditingController(text: repository?.language ?? '');
    _id = TextEditingController(text: repository?.id ?? '');
    _isPublic = repository?.isPublic ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _language.dispose();
    _id.dispose();
    super.dispose();
  }

  String _makeId(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9-]+'), '-')
      .replaceAll(RegExp(r'-+'), '-')
      .replaceAll(RegExp(r'^-|-$'), '');

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final id = widget.repository == null
        ? _makeId(_id.text)
        : widget.repository!.id;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final repository = Repository(
        id: id,
        name: _name.text.trim(),
        description: _description.text.trim(),
        language: _language.text.trim(),
        isPublic: _isPublic,
        updatedAt: 'Updated just now',
      );
      if (widget.repository == null) {
        await FirebaseService.createRepository(repository);
      } else {
        await FirebaseService.saveRepository(repository);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on RepositoryAlreadyExistsException catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } on FirebaseException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message ?? 'Could not save this repository.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.repository == null ? 'New repository' : 'Edit repository',
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _Field(
                  controller: _name,
                  label: 'Repository name',
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter a repository name.'
                      : null,
                  onChanged: (value) {
                    if (widget.repository == null) {
                      _id.text = _makeId(value);
                    }
                  },
                ),
                if (widget.repository == null) ...[
                  const SizedBox(height: 13),
                  _Field(
                    controller: _id,
                    label: 'URL slug',
                    validator: (value) =>
                        value == null || _makeId(value).isEmpty
                        ? 'Enter a valid slug.'
                        : null,
                  ),
                ],
                const SizedBox(height: 13),
                _Field(
                  controller: _description,
                  label: 'Description',
                  maxLines: 3,
                ),
                const SizedBox(height: 13),
                _Field(controller: _language, label: 'Language'),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Public repository'),
                  value: _isPublic,
                  activeTrackColor: AppTheme.green,
                  onChanged: (value) => setState(() => _isPublic = value),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          style: FilledButton.styleFrom(backgroundColor: AppTheme.green),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.validator,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final FormFieldValidator<String>? validator;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: controller,
    maxLines: maxLines,
    onChanged: onChanged,
    decoration: InputDecoration(labelText: label),
    validator: validator,
  );
}
