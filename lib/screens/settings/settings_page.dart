import 'dart:io';

import 'package:expense_tracker/screens/settings/widgets/color_mode_widget.dart';
import 'package:expense_tracker/services/data_io_service.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;

const String _sampleDataAsset = 'assets/sample_data/sample_data.json';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(fontSize: 18);

    Widget settingRow(String label, Widget trailing) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: labelStyle)),
          trailing,
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              settingRow('Color mode', const ColorModeWidget()),
              const Divider(height: 32),
              settingRow(
                'Export to file',
                IconButton(
                  tooltip: 'Export to file',
                  icon: const Icon(Icons.file_upload_outlined),
                  onPressed: () => _exportData(context),
                ),
              ),
              const Divider(height: 32),
              settingRow(
                'Import from file',
                IconButton(
                  tooltip: 'Import from file',
                  icon: const Icon(Icons.file_download_outlined),
                  onPressed: () => _importData(context),
                ),
              ),
              const Divider(height: 32),
              settingRow(
                'Load sample data',
                IconButton(
                  tooltip: 'Load sample data',
                  icon: const Icon(Icons.science_outlined),
                  onPressed: () => _loadSampleData(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final file = await DataIOService.exportToFile();
      final size = await file.length();
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Exported ${(size / 1024).toStringAsFixed(1)} KB to '
            '${p.basename(file.path)}',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Export complete'),
          content: SelectableText(file.path),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Export failed: $e');
    }
  }

  Future<void> _importData(BuildContext context) async {
    final List<File> files;
    try {
      files = await DataIOService.listExportFiles();
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Could not list exports: $e');
      return;
    }
    if (!context.mounted) return;
    if (files.isEmpty) {
      _showError(
        context,
        'No export files found. Use "Export to file" first, or load sample data.',
      );
      return;
    }
    final picked = await showDialog<File>(
      context: context,
      builder: (ctx) => SimpleDialog(
        title: const Text('Pick an export file'),
        children: [
          for (final f in files)
            SimpleDialogOption(
              onPressed: () => Navigator.of(ctx).pop(f),
              child: Text(p.basename(f.path)),
            ),
          SimpleDialogOption(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
    if (picked == null || !context.mounted) return;
    final confirmed = await _confirmReplace(context);
    if (!confirmed || !context.mounted) return;
    try {
      final result = await DataIOService.importFromFile(picked);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Imported ${result.categories} categories, '
            '${result.transactions} transactions.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Import failed: $e');
    }
  }

  Future<void> _loadSampleData(BuildContext context) async {
    final confirmed = await _confirmReplace(context);
    if (!confirmed || !context.mounted) return;
    try {
      final result = await DataIOService.importFromAsset(_sampleDataAsset);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Loaded sample data: ${result.categories} categories, '
            '${result.transactions} transactions.',
          ),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      _showError(context, 'Could not load sample data: $e');
    }
  }

  Future<bool> _confirmReplace(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Replace existing data?'),
        content: const Text(
          'This will delete all current categories and transactions, '
          'then load the file contents. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Replace'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 5),
      ),
    );
  }
}
