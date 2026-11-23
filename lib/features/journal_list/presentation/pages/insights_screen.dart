import 'package:material_ui/material_ui.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../journal_entry/domain/entities/journal_entry.dart';
import '../../../journal_entry/domain/entities/mood.dart';
import '../../../journal_entry/domain/repositories/journal_repository.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});

  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  late final JournalRepository _repository;
  List<JournalEntryEntity> _entries = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _repository = ServiceLocator.journalRepository;
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      final entries = await _repository.getAllEntries();
      if (mounted) {
        setState(() {
          _entries = entries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to load entries: $e';
          _isLoading = false;
        });
      }
    }
  }

  Map<Mood, int> get _moodStatistics {
    final stats = <Mood, int>{};
    for (final entry in _entries) {
      stats[entry.mood] = (stats[entry.mood] ?? 0) + 1;
    }
    return stats;
  }

  Map<String, int> get _topTags {
    final tagCounts = <String, int>{};
    for (final entry in _entries) {
      for (final tag in entry.tags) {
        final clean = tag.trim().toLowerCase();
        if (clean.isNotEmpty) {
          tagCounts[clean] = (tagCounts[clean] ?? 0) + 1;
        }
      }
    }
    final sorted = tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return Map.fromEntries(sorted.take(6));
  }

  int get _thisWeekCount {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final threshold = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    return _entries.where((e) => e.timestamp.isAfter(threshold)).length;
  }

  List<PieChartSectionData> get _pieChartData {
    final moodStats = _moodStatistics;
    final totalEntries = _entries.length;

    if (totalEntries == 0) return [];

    return moodStats.entries.map((entry) {
      final mood = entry.key;
      final count = entry.value;
      final percentage = (count / totalEntries * 100);

      return PieChartSectionData(
        value: percentage,
        title: '${percentage.toStringAsFixed(0)}%',
        color: _getMoodColor(mood),
        radius: 54,
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
        return const Color(0xFFD4A373); // Warm honey
      case Mood.calm:
        return const Color(0xFF6B9080); // Sage green
      case Mood.sad:
        return const Color(0xFF6C7A89); // Slate blue
      case Mood.stressed:
        return const Color(0xFFC97A63); // Muted terracotta
      case Mood.excited:
        return const Color(0xFF9C6644); // Warm amber
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Patterns'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
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
                'Start journaling to discover your emotional patterns and recurring themes.',
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
            // Overview summary cards
            Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    title: 'Total Entries',
                    value: '${_entries.length}',
                    icon: Icons.book_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    title: 'This Week',
                    value: '$_thisWeekCount',
                    icon: Icons.calendar_today_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Mood Distribution
            Text(
              'Mood Distribution',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            if (_pieChartData.isNotEmpty) ...[
              Container(
                height: 260,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                ),
                child: PieChart(
                  PieChartData(
                    sections: _pieChartData,
                    centerSpaceRadius: 50,
                    centerSpaceColor: Theme.of(context).colorScheme.surface,
                    sectionsSpace: 2,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Mood Breakdown List
            ..._moodStatistics.entries.map((entry) {
              final mood = entry.key;
              final count = entry.value;
              final percentage = _entries.isNotEmpty
                  ? (count / _entries.length * 100).toStringAsFixed(1)
                  : '0.0';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
                  ),
                  borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getMoodColor(mood),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      mood.emoji,
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      mood.label,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const Spacer(),
                    Text(
                      '$count entries ($percentage%)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }),

            const SizedBox(height: 24),

            // Top Tags / Themes
            if (_topTags.isNotEmpty) ...[
              Text(
                'Frequent Themes & Tags',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _topTags.entries.map((entry) {
                  return Chip(
                    label: Text('#${entry.key} (${entry.value})'),
                    backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppConstants.cardRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 10),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
