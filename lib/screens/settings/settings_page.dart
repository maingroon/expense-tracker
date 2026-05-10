import 'dart:io';

import 'package:expense_tracker/screens/settings/widgets/color_mode_widget.dart';
import 'package:expense_tracker/services/data_io_service.dart';
import 'package:expense_tracker/services/forecast_repository.dart';
import 'package:expense_tracker/services/forecast_settings_notifier.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:provider/provider.dart';

const String _sampleDataAsset = 'assets/sample_data/sample_data.json';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final forecastSettings = context.watch<ForecastSettingsNotifier>();
    final repo = context.read<ForecastRepository>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SizedBox(
        width: double.infinity,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Color mode',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18),
                  ),
                  const ColorModeWidget(),
                ],
              ),
              const Divider(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Show forecast tab',
                    style: theme.textTheme.bodyMedium?.copyWith(fontSize: 18),
                  ),
                  Switch(
                    value: forecastSettings.showTab,
                    onChanged: forecastSettings.setShowTab,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonal(
                  onPressed: () async {
                    await repo.deleteOlderThan(Duration.zero);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Cached forecasts cleared.')),
                      );
                    }
                  },
                  child: const Text('Clear cached forecasts'),
                ),
              ),
              const Divider(height: 32),
              Text(
                'Data',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.file_upload_outlined),
                    label: const Text('Export to file'),
                    onPressed: () => _exportData(context),
                  ),
                  FilledButton.tonalIcon(
                    icon: const Icon(Icons.file_download_outlined),
                    label: const Text('Import from file'),
                    onPressed: () => _importData(context),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.science_outlined),
                    label: const Text('Load sample data'),
                    onPressed: () => _loadSampleData(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Export writes a JSON snapshot of categories and transactions. '
                'Import replaces all existing data with the file contents. '
                'Sample data provides ~130 days of transactions to enable forecasting.',
                style: theme.textTheme.bodySmall,
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
