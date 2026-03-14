import 'package:flutter/material.dart';
import 'models/journal_entry.dart';
import 'services/database_service.dart';

enum Mood {
  happy('😊', 'Happy'),
  sad('😢', 'Sad'),
  anxious('😰', 'Anxious'),
  grateful('🙏', 'Grateful'),
  excited('🎉', 'Excited'),
  calm('😌', 'Calm'),
  angry('😠', 'Angry'),
  neutral('😐', 'Neutral');

  const Mood(this.emoji, this.label);
  final String emoji;
  final String label;
}

class JournalEntryScreen extends StatefulWidget {
  const JournalEntryScreen({super.key});

  @override
  State<JournalEntryScreen> createState() => _JournalEntryScreenState();
}

class _JournalEntryScreenState extends State<JournalEntryScreen> {
  final _textController = TextEditingController();
  Mood? _selectedMood;
  bool _isSaving = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeDatabase();
  }

  Future<void> _initializeDatabase() async {
    try {
      await DatabaseService.init();
      setState(() {
        _isInitialized = true;
      });
    } catch (e) {
      _showSnackBar('Failed to initialize database: $e');
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _saveEntry() async {
    if (!_isInitialized) {
      _showSnackBar('Database not initialized yet');
      return;
    }

    if (_textController.text.trim().isEmpty) {
      _showSnackBar('Please write something before saving');
      return;
    }

    if (_selectedMood == null) {
      _showSnackBar('Please select your mood');
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final entry = JournalEntry.create(
        text: _textController.text.trim(),
        mood: _selectedMood!.label,
      );

      await DatabaseService.saveEntry(entry);
      _showSnackBar('Journal entry saved successfully!');
      _clearForm();
    } catch (e) {
      _showSnackBar('Failed to save entry: $e');
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
        title: const Text('New Journal Entry'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Today, ${DateTime.now().toString().split(' ')[0]}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Mood selector
            Text(
              'How are you feeling?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            Container(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: Mood.values.length,
                itemBuilder: (context, index) {
                  final mood = Mood.values[index];
                  final isSelected = _selectedMood == mood;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedMood = mood;
                      });
                    },
                    child: Container(
                      width: 70,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? Theme.of(context).primaryColor.withOpacity(0.2)
                          : Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected 
                            ? Theme.of(context).primaryColor
                            : Colors.grey[300]!,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            mood.emoji,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            mood.label,
                            style: TextStyle(
                              fontSize: 10,
                              color: isSelected 
                                ? Theme.of(context).primaryColor
                                : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Text input
            Text(
              'What\'s on your mind?',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            
            Expanded(
              child: TextField(
                controller: _textController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: InputDecoration(
                  hintText: 'Write your thoughts here...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                style: const TextStyle(fontSize: 16),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Character count
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                '${_textController.text.length} characters',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Save button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveEntry,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isSaving
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Save Entry',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
