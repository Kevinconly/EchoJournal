import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../journal_entry/domain/services/backup_service.dart';
import '../../../journal_entry/domain/repositories/journal_repository.dart';
import '../../../journal_entry/data/repositories/journal_repository_impl.dart';
import '../../../journal_entry/data/datasources/local/database_service.dart';
import '../../../../core/constants/app_constants.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late JournalRepository _repository;
  bool _isDarkMode = false;
  bool _isExporting = false;
  bool _isImporting = false;
  bool _isClearing = false;
  String? _lastBackupPath;

  @override
  void initState() {
    super.initState();
    _repository = JournalRepositoryImpl(DatabaseService());
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _isDarkMode = prefs.getBool('dark_mode') ?? false;
        _lastBackupPath = prefs.getString('last_backup_path');
      });
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
  }

  Future<void> _saveDarkMode(bool isDark) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('dark_mode', isDark);
      setState(() {
        _isDarkMode = isDark;
      });
    } catch (e) {
      _showErrorSnackBar('Failed to save theme preference');
    }
  }

  Future<void> _exportBackup() async {
    try {
      setState(() {
        _isExporting = true;
      });

      final filePath = await BackupService.exportBackup();
      
      // Save last backup path
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('last_backup_path', filePath);
      
      setState(() {
        _isExporting = false;
        _lastBackupPath = filePath;
      });

      if (mounted) {
        _showSuccessSnackBar('Backup exported successfully!\nSaved to: ${filePath.split('/').last}');
      }
    } catch (e) {
      setState(() {
        _isExporting = false;
      });

      if (mounted) {
        _showErrorSnackBar('Export failed: $e');
      }
    }
  }

  Future<void> _importBackup() async {
    try {
      setState(() {
        _isImporting = true;
      });

      final result = await BackupService.importBackup();
      
      setState(() {
        _isImporting = false;
      });

      if (mounted) {
        if (result.success) {
          _showImportSuccessDialog(result);
        } else {
          _showErrorSnackBar(result.error ?? 'Import failed');
        }
      }
    } catch (e) {
      setState(() {
        _isImporting = false;
      });

      if (mounted) {
        _showErrorSnackBar('Import failed: $e');
      }
    }
  }

  Future<void> _clearAllEntries() async {
    final confirmed = await _showClearConfirmationDialog();
    if (!confirmed) return;

    try {
      setState(() {
        _isClearing = true;
      });

      await _repository.deleteAllEntries();
      
      // Clear last backup path
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('last_backup_path');
      
      setState(() {
        _isClearing = false;
        _lastBackupPath = null;
      });

      if (mounted) {
        _showSuccessSnackBar('All entries cleared successfully');
      }
    } catch (e) {
      setState(() {
        _isClearing = false;
      });

      if (mounted) {
        _showErrorSnackBar('Failed to clear entries: $e');
      }
    }
  }

  Future<bool> _showClearConfirmationDialog() async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Entries'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Are you sure you want to delete all journal entries?'),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone.',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
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
    ) ?? false;
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
            Text('Successfully imported ${result.importedCount} of ${result.totalEntries} entries.'),
            if (result.hasErrors) ...[
              const SizedBox(height: 16),
              const Text('Some entries had errors:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...result.errors!.take(5).map((error) => Text(
                '• $error',
                style: const TextStyle(fontSize: 12, color: Colors.red),
              )),
              if (result.errors!.length > 5)
                Text('... and ${result.errors!.length - 5} more errors'),
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: const Duration(seconds: 3),
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
          _buildDarkModeTile(),
          const SizedBox(height: 24),
          
          // Data Management Section
          _buildSectionHeader('Data Management'),
          _buildExportTile(),
          _buildImportTile(),
          _buildClearTile(),
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
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDarkModeTile() {
    return ListTile(
      leading: Icon(
        _isDarkMode ? Icons.dark_mode : Icons.light_mode,
        color: Theme.of(context).colorScheme.primary,
      ),
      title: const Text('Dark Mode'),
      subtitle: Text(_isDarkMode ? 'Currently enabled' : 'Currently disabled'),
      trailing: Switch(
        value: _isDarkMode,
        onChanged: _saveDarkMode,
        activeThumbColor: Theme.of(context).colorScheme.primary,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
    );
  }

  Widget _buildExportTile() {
    return ListTile(
      leading: const Icon(Icons.download),
      title: const Text('Export Backup'),
      subtitle: _lastBackupPath != null 
          ? Text('Last: ${_lastBackupPath!.split('/').last}')
          : const Text('Export all entries to JSON file'),
      trailing: _isExporting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _isExporting ? null : _exportBackup,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
    );
  }

  Widget _buildImportTile() {
    return ListTile(
      leading: const Icon(Icons.upload),
      title: const Text('Import Backup'),
      subtitle: const Text('Import entries from JSON file'),
      trailing: _isImporting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : null,
      onTap: _isImporting ? null : _importBackup,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
    );
  }

  Widget _buildClearTile() {
    return ListTile(
      leading: Icon(
        Icons.delete_forever,
        color: Theme.of(context).colorScheme.error,
      ),
      title: const Text('Clear All Entries'),
      subtitle: const Text('Delete all journal entries permanently'),
      trailing: _isClearing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
              ),
            )
          : null,
      onTap: _isClearing ? null : _clearAllEntries,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
    );
  }

  Widget _buildAboutTile() {
    return ListTile(
      leading: const Icon(Icons.info_outline),
      title: const Text('About EchoJournal'),
      subtitle: const Text('Version 1.0.0'),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        showAboutDialog(
          context: context,
          applicationName: AppConstants.appName,
          applicationVersion: '1.0.0',
          applicationIcon: const Icon(Icons.book),
          children: [
            const Text('A private, offline-first journaling app'),
            const SizedBox(height: 16),
            const Text('Built with Flutter and Material Design'),
            const SizedBox(height: 16),
            const Text('© 2024 EchoJournal'),
          ],
        );
      },
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
    );
  }
}
