import '../../../journal_entry/domain/entities/journal_entry.dart';
import '../../../journal_entry/domain/repositories/journal_repository.dart';

class RelevantMemory {
  final JournalEntryEntity entry;
  final double score;
  final List<String> commonThemes;

  const RelevantMemory({
    required this.entry,
    required this.score,
    required this.commonThemes,
  });
}

class ContextRetrievalService {
  final JournalRepository _repository;

  static const Set<String> _stopWords = {
    'the', 'is', 'at', 'which', 'on', 'a', 'an', 'and', 'or', 'but',
    'in', 'with', 'to', 'for', 'of', 'as', 'by', 'that', 'this',
    'it', 'from', 'was', 'were', 'been', 'be', 'have', 'has',
    'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should',
    'may', 'might', 'must', 'can', 'shall', 'i', 'you', 'he',
    'she', 'we', 'they', 'me', 'him', 'her', 'us', 'them', 'my',
    'your', 'his', 'our', 'their', 'what', 'when', 'where', 'why',
    'how', 'not', 'no', 'just', 'very', 'really', 'today', 'felt',
  };

  ContextRetrievalService(this._repository);

  /// Find past entries connected by themes, tags, or mood.
  Future<List<RelevantMemory>> findRelatedMemories(
    JournalEntryEntity currentEntry, {
    int limit = 3,
  }) async {
    try {
      final allEntries = await _repository.getAllEntries();
      final pastEntries = allEntries.where((e) => e.id != currentEntry.id).toList();

      if (pastEntries.isEmpty) return [];

      final currentTokens = _extractTokens(currentEntry.text);
      final currentTags = currentEntry.tags.map((t) => t.toLowerCase()).toSet();

      final results = <RelevantMemory>[];

      for (final past in pastEntries) {
        final pastTokens = _extractTokens(past.text);
        final pastTags = past.tags.map((t) => t.toLowerCase()).toSet();

        // Common tags
        final commonTags = currentTags.intersection(pastTags);

        // Common tokens
        final commonTokens = currentTokens.intersection(pastTokens);

        final commonThemes = {...commonTags, ...commonTokens}.toList();

        // Calculate relevance score
        double score = 0.0;
        score += commonTags.length * 3.0; // Higher weight for user-specified tags
        score += commonTokens.length * 1.0;

        if (past.mood == currentEntry.mood) {
          score += 1.5; // Mood coherence bonus
        }

        if (score > 1.0) {
          results.add(RelevantMemory(
            entry: past,
            score: score,
            commonThemes: commonThemes,
          ));
        }
      }

      results.sort((a, b) => b.score.compareTo(a.score));
      return results.take(limit).toList();
    } catch (_) {
      return [];
    }
  }

  /// Suggest initial reflection prompts based on entry mood and content
  List<String> generateInitialQuestions(JournalEntryEntity entry) {
    final questions = <String>[];
    final text = entry.text.toLowerCase();

    switch (entry.mood.label.toLowerCase()) {
      case 'happy':
        questions.add('What was the highlight or spark behind this happy feeling?');
        questions.add('How might you carry even a piece of this energy into tomorrow?');
        break;
      case 'calm':
        questions.add('What conditions or choices helped you reach this state of calm?');
        questions.add('How can you protect your peace when busier moments return?');
        break;
      case 'sad':
        questions.add('What is the core feeling or need beneath this sadness?');
        questions.add('What is one gentle act of self-care you can offer yourself right now?');
        break;
      case 'stressed':
        questions.add('Which responsibility or thought is draining the most of your energy?');
        questions.add('What is one thing on your list that can be deferred or let go?');
        break;
      case 'excited':
        questions.add('What future possibility are you most looking forward to exploring?');
        questions.add('How can you channel this excitement into intentional progress?');
        break;
      default:
        questions.add('What feels most central about what you wrote today?');
    }

    if (text.contains('work') || text.contains('job') || text.contains('career')) {
      questions.add('How is your work life aligning with your personal boundaries lately?');
    } else if (text.contains('friend') || text.contains('family') || text.contains('relationship')) {
      questions.add('How supported do you feel by the people around you in this moment?');
    }

    return questions.take(3).toList();
  }

  Set<String> _extractTokens(String text) {
    final words = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ').split(RegExp(r'\s+'));
    final tokens = <String>{};
    for (final w in words) {
      if (w.length >= 3 && !_stopWords.contains(w)) {
        tokens.add(w);
      }
    }
    return tokens;
  }
}
