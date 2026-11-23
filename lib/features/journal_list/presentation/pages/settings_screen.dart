import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../journal_entry/domain/services/backup_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isClearing = false;
  String? _lastBackupPath;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _lastBackupPath = prefs.getString('last_backup_path');
        });
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _exportBackup() async {
    setState(() {
      _isExporting = true;
    });

    try {
      final filePath = await BackupService.exportBackup();
      if (filePath == null) {
        // User canceled file picker
        if (mounted) {
          setState(() {
            _isExporting = false;
          });
        }
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_backup_path', filePath);

      if (mounted) {
        setState(() {
          _isExporting = false;
          _lastBackupPath = filePath;
        });
        _showSuccessSnackBar('Backup exported successfully!\nFile: ${BackupService.getFileName(filePath)}');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isExporting = false;
        });
        _showErrorSnackBar('Export failed: $e');
      }
    }
  }

  Future<void> _importBackup() async {
    final mode = await _showImportModeDialog();
    if (mode == null) return; // User canceled mode selection

    setState(() {
      _isImporting = true;
    });

    try {
      final result = await BackupService.importBackup(mode: mode);

      if (mounted) {
        setState(() {
          _isImporting = false;
        });

        if (result.isCancelled) {
          // Clean cancellation, no error shown
          return;
        }

        if (result.success) {
          _showImportSuccessDialog(result);
        } else {
          _showErrorSnackBar(result.error ?? 'Import failed');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isImporting = false;
        });
        _showErrorSnackBar('Import failed: $e');
      }
    }
  }

  Future<ImportMode?> _showImportModeDialog() async {
    return showDialog<ImportMode>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Backup'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('How would you like to restore your entries?'),
            SizedBox(height: 12),
            Text(
              '• Merge: Adds new entries and skips duplicates safely.\n'
              '• Replace: Replaces all existing entries with backup contents.',
              style: TextStyle(fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(null),
            child: const Text('Cancel'),
          ),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(ImportMode.replace),
            style: OutlinedButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Replace All'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(ImportMode.merge),
            child: const Text('Merge (Safe)'),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllEntries() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Entries'),
        content: const Text(
          'Are you sure you want to delete all journal entries? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() {
      _isClearing = true;
    });

    try {
      await ServiceLocator.journalRepository.deleteAllEntries();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_backup_path');

      if (mounted) {
        setState(() {
          _isClearing = false;
          _lastBackupPath = null;
        });
        _showSuccessSnackBar('All entries cleared successfully');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isClearing = false;
        });
        _showErrorSnackBar('Failed to clear entries: $e');
      }
    }
  }

  void _showImportSuccessDialog(ImportResult result) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Successful'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Successfully imported ${result.importedCount} entries.'),
            if (result.skippedDuplicates > 0) ...[
              const SizedBox(height: 6),
              Text(
                'Skipped ${result.skippedDuplicates} duplicate entries.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (result.hasErrors) ...[
              const SizedBox(height: 12),
              const Text('Errors encountered:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              ...result.errors.take(3).map((err) => Text('• $err', style: const TextStyle(fontSize: 12, color: Colors.red))),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.primary,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        children: [
          // Appearance Section
          _buildSectionHeader('Appearance'),
          _buildThemeSelector(),
          const SizedBox(height: 24),

          // Data Management Section
          _buildSectionHeader('Data Management'),
          _buildExportTile(),
          _buildImportTile(),
          _buildClearTile(),
          const SizedBox(height: 24),

          // Privacy & Storage Section
          _buildSectionHeader('Privacy & Storage'),
          _buildPrivacyTile(),
          const SizedBox(height: 24),

          // About Section
          _buildSectionHeader('About'),
          _buildAboutTile(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildThemeSelector() {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: ThemeController.themeModeNotifier,
      builder: (context, currentMode, _) {
        return Card(
          elevation: 0,
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      currentMode == ThemeMode.dark ? Icons.dark_mode : Icons.light_mode,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Theme Mode',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: Text('System'),
                      icon: Icon(Icons.brightness_auto, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: Text('Light'),
                      icon: Icon(Icons.light_mode, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: Text('Dark'),
                      icon: Icon(Icons.dark_mode, size: 18),
                    ),
                  ],
                  selected: {currentMode},
                  onSelectionChanged: (selected) {
                    if (selected.isNotEmpty) {
                      ThemeController.setThemeMode(selected.first);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportTile() {
    return ListTile(
      leading: Icon(
        Icons.download_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Export Backup'),
      subtitle: Text(
        _lastBackupPath != null
            ? 'Last backup: ${BackupService.getFileName(_lastBackupPath!)}'
            : 'Save your entries to a JSON backup file',
      ),
      trailing: _isExporting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _isExporting ? null : _exportBackup,
    );
  }

  Widget _buildImportTile() {
    return ListTile(
      leading: Icon(
        Icons.upload_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Import Backup'),
      subtitle: const Text('Restore or merge entries from a JSON backup'),
      trailing: _isImporting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _isImporting ? null : _importBackup,
    );
  }

  Widget _buildClearTile() {
    return ListTile(
      leading: Icon(
        Icons.delete_sweep_outlined,
        color: Theme.of(context).colorScheme.error,
      ),
      title: Text(
        'Clear All Entries',
        style: TextStyle(color: Theme.of(context).colorScheme.error),
      ),
      subtitle: const Text('Permanently delete all journal entries'),
      trailing: _isClearing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.chevron_right),
      onTap: _isClearing ? null : _clearAllEntries,
    );
  }

  Widget _buildPrivacyTile() {
    return ListTile(
      leading: Icon(
        Icons.security_outlined,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('100% Offline Storage'),
      subtitle: const Text('Your entries never leave your device. No cloud sync, no tracking.'),
    );
  }

  Widget _buildAboutTile() {
    return ListTile(
      leading: Icon(
        Icons.info_outline,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('EchoJournal'),
      subtitle: const Text('Version 1.0.3 • Thoughtful offline journaling'),
    );
  }
}
