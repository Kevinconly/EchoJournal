import 'package:flutter/material.dart';
import '../../../domain/entities/journal_entry.dart';
import '../../../domain/entities/mood.dart';
import '../../../domain/usecases/save_journal_entry_usecase.dart';
import '../../../data/repositories/journal_repository_impl.dart';
import '../../../data/datasources/local/database_service.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/theme/app_theme.dart';
import '../widgets/mood_selector.dart';
import '../widgets/journal_text_field.dart';
import '../widgets/tags_input.dart';

class JournalEntryScreen extends StatefulWidget {
  const JournalEntryScreen({super.key});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final _textController = TextEditingController();
  Mood? _selectedMood;
  List<String> _tags = [];
  bool _isSaving = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry(SaveJournalEntryUseCase saveUseCase) async {
    if (_textController.text.trim().isEmpty) {
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
      final entry = JournalEntryEntity(
        text: _textController.text.trim(),
        mood: _selectedMood!,
        timestamp: DateTime.now(),
      );

      await saveUseCase(entry);
      _showSnackBar(AppStrings.entrySaved);
      _clearForm();
      Navigator.of(context).pop();
    } catch (e) {
      _showSnackBar('${AppStrings.failedToSave}: $e');
    } finally {
      setState(() {
        _isSaving = false;
      });
    }
  }

  void _clearForm() {
    _textController.clear();
    setState(() {
      _selectedMood = null;
      _tags = [];
    });
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.newEntry),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Today, ${DateTime.now().toString().split(' ')[0]}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Mood selector
            Text(
              AppStrings.howAreYouFeeling,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            MoodSelector(
              selectedMood: _selectedMood,
              onMoodSelected: (mood) {
                setState(() {
                  _selectedMood = mood;
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Text input
            Text(
              AppStrings.whatsOnYourMind,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            Expanded(
              child: JournalTextField(
                controller: _textController,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Tags input
            TagsInput(
              tags: _tags,
              onTagsChanged: (tags) {
                setState(() {
                  _tags = tags;
                });
              },
            ),
            
            const SizedBox(height: 24),
            
            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : () async {
                try {
                  // For now, we'll use a simple implementation
                  // In a real app, this would be properly injected
                  final repository = JournalRepositoryImpl(DatabaseService());
                  final saveUseCase = SaveJournalEntryUseCase(repository);
                  await _saveEntry(saveUseCase);
                } catch (e) {
                  _showSnackBar('${AppStrings.failedToSave}: $e');
                }
              },
              child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                : const Text(AppStrings.save),
            ),
          ],
        ),
      ),
    );
  }
}
