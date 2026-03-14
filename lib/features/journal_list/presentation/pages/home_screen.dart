import 'package:flutter/material.dart';
import '../../../journal_entry/domain/entities/journal_entry.dart';
import '../../../journal_entry/domain/repositories/journal_repository.dart';
import '../../../journal_entry/data/repositories/journal_repository_impl.dart';
import '../../../journal_entry/data/datasources/local/database_service.dart';
import '../../../journal_entry/domain/services/cached_repository.dart';
import '../widgets/empty_state_widget.dart';
import '../widgets/journal_card.dart';
import 'entry_details_screen.dart';
import 'insights_screen.dart';
import 'settings_screen.dart';
import '../../../journal_entry/presentation/pages/journal_entry_screen.dart';
import '../../../../shared/widgets/animated_fab.dart';
import '../../../../shared/utils/error_handler.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late JournalRepository _repository;
  List<JournalEntryEntity> _entries = [];
  List<JournalEntryEntity> _filteredEntries = [];
  bool _isLoading = true;
  String? _error;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _repository = CachedRepository(JournalRepositoryImpl(DatabaseService()));
    _loadEntries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
        _filteredEntries = entries;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load entries';
        _isLoading = false;
      });
      
      AppErrorHandler.showErrorDialog(
        context,
        'Loading Error',
        'Unable to load your journal entries. Please check your device storage and try again.',
        onRetry: _loadEntries,
      );
    }
  }

  void _navigateToEntryDetails(JournalEntryEntity entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => EntryDetailsScreen(entry: entry),
      ),
    );
  }

  void _filterEntries(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredEntries = _entries;
      } else {
        _filteredEntries = _entries.where((entry) {
          return entry.text.toLowerCase().contains(query.toLowerCase()) ||
                 entry.mood.label.toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppConstants.appName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const InsightsScreen(),
                ),
              );
            },
            icon: const Icon(Icons.insights_outlined),
            tooltip: 'Insights',
          ),
          if (_filteredEntries.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${_filteredEntries.length} ${_filteredEntries.length == 1 ? 'entry' : 'entries'}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search entries...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        onPressed: () {
                          _searchController.clear();
                          _filterEntries('');
                        },
                        icon: const Icon(Icons.clear),
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant,
              ),
              onChanged: _filterEntries,
            ),
          ),
          
          // Content
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadEntries,
              child: _buildBody(),
            ),
          ),
        ],
      ),
      floatingActionButton: AnimatedFAB(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const JournalEntryScreen(),
            ).then((_) => _loadEntries()), // Refresh entries when coming back
          );
        },
        icon: Icons.add,
        tooltip: 'Create new entry',
      ),
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

    if (_filteredEntries.isEmpty) {
      return _buildEmptyState();
    }

    return Padding(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: ListView.builder(
        itemCount: _filteredEntries.length,
        itemBuilder: (context, index) {
          final entry = _filteredEntries[index];
          return JournalCard(
            entry: entry,
            searchQuery: _searchController.text,
            onTap: () => _navigateToEntryDetails(entry),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    if (_searchController.text.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: 16),
              Text(
                'No entries found',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Try searching with different keywords',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const EmptyStateWidget();
  }
}
