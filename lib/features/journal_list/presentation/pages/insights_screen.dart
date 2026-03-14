import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../journal_entry/domain/entities/journal_entry.dart';
import '../../../journal_entry/domain/entities/mood.dart';
import '../../../journal_entry/domain/repositories/journal_repository.dart';
import '../../../journal_entry/domain/services/backup_service.dart';
import '../../../journal_entry/data/repositories/journal_repository_impl.dart';
import '../../../../core/constants/app_constants.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  late JournalRepository _repository;
  List<JournalEntryEntity> _entries = [];
  bool _isLoading = true;
  bool _isExporting = false;
  bool _isImporting = false;
  String? _error;
  String? _lastBackupPath;

  @override
  void initState() {
    super.initState();
    _repository = JournalRepositoryImpl();
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });
      
      final entries = await _repository.getAllEntries();
      setState(() {
        _entries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load entries: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _exportBackup() async {
    try {
      setState(() {
        _isExporting = true;
      });

      final filePath = await BackupService.exportBackup();
      if (filePath == null) {
        // User canceled the save dialog; treat as no-op.
        setState(() {
          _isExporting = false;
        });
        return;
      }

      setState(() {
        _isExporting = false;
        _lastBackupPath = filePath;
      });

      if (mounted) {
        _showSuccessSnackBar('Backup exported successfully!\nSaved to: $filePath');
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
          await _loadEntries(); // Refresh the insights
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
              if (result.errors!.isNotEmpty)
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

  Map<Mood, int> get _moodStatistics {
    final stats = <Mood, int>{};
    
    for (final entry in _entries) {
      stats[entry.mood] = (stats[entry.mood] ?? 0) + 1;
    }
    
    return stats;
  }

  List<PieChartSectionData> get _pieChartData {
    final moodStats = _moodStatistics;
    final totalEntries = _entries.length;
    
    if (totalEntries == 0) return [];
    
    return moodStats.entries.map((entry) {
      final mood = entry.key;
      final count = entry.value;
      final percentage = (count / totalEntries * 100).toStringAsFixed(1);
      
      return PieChartSectionData(
        value: double.parse(percentage),
        title: '${mood.label}\n${double.parse(percentage).toStringAsFixed(1)}%',
        color: _getMoodColor(mood),
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Color _getMoodColor(Mood mood) {
    switch (mood) {
      case Mood.happy:
        return const Color(0xFFFFD54F); // Amber
      case Mood.calm:
        return const Color(0xFF4FC3F7); // Light Blue
      case Mood.sad:
        return const Color(0xFF2196F3); // Blue
      case Mood.stressed:
        return const Color(0xFFFF9800); // Orange
      case Mood.excited:
        return const Color(0xFFE91E63); // Pink
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _error!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _loadEntries,
                child: const Text('Try Again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_entries.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.insights_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No insights yet',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Start journaling to see your mood statistics',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadEntries,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Text(
              'Mood Statistics',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Total entries: ${_entries.length}',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            
            // Pie Chart
            if (_pieChartData.isNotEmpty) ...[
              Container(
                height: 300,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                ),
                child: PieChart(
                  PieChartData(
                    sections: _pieChartData,
                    centerSpaceRadius: 60,
                    centerSpaceColor: Theme.of(context).colorScheme.surface,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
            
            // Mood List
            Text(
              'Mood Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            ..._moodStatistics.entries.map((entry) {
              final mood = entry.key;
              final count = entry.value;
              final percentage = _entries.isNotEmpty 
                ? (count / _entries.length * 100).toStringAsFixed(1)
                : '0.0';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: _getMoodColor(mood),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Row(
                        children: [
                          Text(
                            mood.emoji,
                            style: const TextStyle(fontSize: 20),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            mood.label,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          count.toString(),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$percentage%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }),
            
            const SizedBox(height: 24),
            
            // Backup and Restore Section
            Text(
              'Backup & Restore',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              ),
              child: Column(
                children: [
                  // Export Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isExporting ? null : _exportBackup,
                      icon: _isExporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.download),
                      label: Text(_isExporting ? 'Exporting...' : 'Export Backup'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Import Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isImporting ? null : _importBackup,
                      icon: _isImporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.upload),
                      label: Text(_isImporting ? 'Importing...' : 'Import Backup'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        foregroundColor: Theme.of(context).colorScheme.onSecondary,
                      ),
                    ),
                  ),
                  
                  if (_lastBackupPath != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      'Last backup: ${_lastBackupPath?.split('/').last}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
