import 'package:material_ui/material_ui.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../journal_entry/domain/entities/journal_entry.dart';
import '../../../journal_entry/presentation/pages/journal_entry_screen.dart';
import 'reflection_chat_screen.dart';

class EntryDetailsScreen extends StatefulWidget {
  final JournalEntryEntity entry;

  const EntryDetailsScreen({
    super.key,
    required this.entry,
  });

  @override
  State<EntryDetailsScreen> createState() => _EntryDetailsScreenState();
}

class _EntryDetailsScreenState extends State<EntryDetailsScreen> {
  late JournalEntryEntity _entry;

  @override
  void initState() {
    super.initState();
    _entry = widget.entry;
  }

  int get _wordCount {
    final text = _entry.text.trim();
    return text.isEmpty ? 0 : text.split(RegExp(r'\s+')).length;
  }

  Future<void> _handleEdit() async {
    final updated = await Navigator.of(context).push<dynamic>(
      MaterialPageRoute(
        builder: (context) => JournalEntryScreen(existingEntry: _entry),
      ),
    );

    if (updated is JournalEntryEntity && mounted) {
      setState(() {
        _entry = updated;
      });
    }
  }

  Future<void> _handleDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Entry'),
        content: const Text(
          'Are you sure you want to delete this journal entry? This action cannot be undone.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      if (_entry.id != null) {
        try {
          await ServiceLocator.journalRepository.deleteEntry(_entry.id!);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Entry deleted successfully')),
            );
            Navigator.of(context).pop(true);
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to delete entry: $e')),
            );
          }
        }
      } else {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final moodColor = AppTheme.getMoodColor(_entry.mood.label);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Journal Entry'),
        backgroundColor: theme.colorScheme.surface,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _handleEdit,
            icon: const Icon(Icons.edit_outlined),
            tooltip: 'Edit entry',
          ),
          IconButton(
            onPressed: _handleDelete,
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete entry',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with mood pill, date and stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
                border: Border.all(color: theme.colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: moodColor.withValues(alpha: 0.16),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _entry.mood.emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _entry.mood.label,
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: moodColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '$_wordCount words',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _entry.formattedDateTime,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Content card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                border: Border.all(
                  color: theme.colorScheme.outlineVariant,
                ),
                borderRadius: BorderRadius.circular(AppConstants.cardRadius),
              ),
              child: Text(
                _entry.text,
                style: theme.textTheme.bodyLarge?.copyWith(
                  height: 1.7,
                  fontSize: 16,
                  letterSpacing: 0.15,
                ),
              ),
            ),

            // Tags section (if available)
            if (_entry.tags.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Tags',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _entry.tags.map((tag) {
                  return Chip(
                    label: Text('#$tag'),
                    backgroundColor: theme.colorScheme.surfaceContainerLow,
                    side: BorderSide(color: theme.colorScheme.outlineVariant),
                    labelStyle: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 36),

            // Reflect button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ReflectionChatScreen(entry: _entry),
                    ),
                  );
                },
                icon: const Icon(Icons.psychology_outlined),
                label: const Text('Reflect on this entry'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
