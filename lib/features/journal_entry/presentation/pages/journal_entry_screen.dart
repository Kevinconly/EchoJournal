import 'package:material_ui/material_ui.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/di/service_locator.dart';
import '../../domain/entities/journal_entry.dart';
import '../../domain/entities/mood.dart';
import '../widgets/journal_text_field.dart';
import '../widgets/mood_selector.dart';
import '../widgets/tags_input.dart';

class JournalEntryScreen extends StatefulWidget {
  final JournalEntryEntity? existingEntry;

  const JournalEntryScreen({
    super.key,
    this.existingEntry,
  });

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  late final TextEditingController _textController;
  Mood? _selectedMood;
  List<String> _tags = [];
  bool _isSaving = false;

  bool get _isEditing => widget.existingEntry != null;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.existingEntry?.text ?? '');
    _selectedMood = widget.existingEntry?.mood;
    _tags = widget.existingEntry?.tags != null ? List<String>.from(widget.existingEntry!.tags) : [];
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      _showSnackBar(AppStrings.pleaseWriteSomething);
      return;
    }

    if (_selectedMood == null) {
      _showSnackBar(AppStrings.pleaseSelectMood);
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final repository = ServiceLocator.journalRepository;
      if (_isEditing) {
        final updatedEntry = widget.existingEntry!.copyWith(
          text: text,
          mood: _selectedMood!,
          tags: _tags,
        );
        await repository.updateEntry(updatedEntry);
        if (mounted) {
          _showSnackBar('Journal entry updated successfully!');
          Navigator.of(context).pop(updatedEntry);
        }
      } else {
        final newEntry = JournalEntryEntity(
          text: text,
          mood: _selectedMood!,
          timestamp: DateTime.now(),
          tags: _tags,
        );
        await repository.saveEntry(newEntry);
        if (mounted) {
          _showSnackBar(AppStrings.entrySaved);
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar('${AppStrings.failedToSave}: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final formattedDate = _isEditing
        ? widget.existingEntry!.formattedDate
        : 'Today, ${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Entry' : AppStrings.newEntry),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _isSaving ? null : _saveEntry,
            icon: const Icon(Icons.check),
            tooltip: 'Save',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Date header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  formattedDate,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Mood selector
              Text(
                AppStrings.howAreYouFeeling,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              MoodSelector(
                selectedMood: _selectedMood,
                onMoodSelected: (mood) {
                  setState(() {
                    _selectedMood = mood;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Text input
              Text(
                AppStrings.whatsOnYourMind,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),

              Expanded(
                child: JournalTextField(
                  controller: _textController,
                ),
              ),
              const SizedBox(height: 12),

              // Tags input
              TagsInput(
                tags: _tags,
                onTagsChanged: (tags) {
                  setState(() {
                    _tags = tags;
                  });
                },
              ),
              const SizedBox(height: 16),

              // Save button
              ElevatedButton(
                onPressed: _isSaving ? null : _saveEntry,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : Text(_isEditing ? 'Update Entry' : AppStrings.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
