import '../entities/journal_entry.dart';
import '../repositories/journal_repository.dart';

class SimilaritySearchService {
  final JournalRepository _repository;

  SimilaritySearchService(this._repository);

  // Common words to exclude from keyword extraction
  static const Set<String> _stopWords = {
    'the', 'is', 'at', 'which', 'on', 'a', 'an', 'and', 'or', 'but',
    'in', 'with', 'to', 'for', 'of', 'as', 'by', 'that', 'this',
    'it', 'from', 'was', 'were', 'been', 'be', 'have', 'has',
    'had', 'do', 'does', 'did', 'will', 'would', 'could', 'should',
    'may', 'might', 'must', 'can', 'shall', 'i', 'you', 'he',
    'she', 'we', 'they', 'me', 'him', 'her', 'us', 'them', 'my',
    'your', 'his', 'our', 'their', 'mine', 'yours',
    'hers', 'ours', 'theirs', 'what', 'when', 'where', 'why',
    'how', 'who', 'whom', 'whose', 'whoever', 'whatever',
    'whichever', 'whenever', 'wherever', 'however',
    'not', 'no', 'nor', 'neither', 'never', 'none', 'nothing',
    'nowhere', 'nobody', 'only', 'very', 'really', 'quite', 'rather',
    'just', 'even', 'still', 'yet', 'already', 'again', 'once',
    'twice', 'three', 'four', 'five', 'six', 'seven', 'eight',
    'nine', 'ten', 'hundred', 'thousand', 'million', 'billion',
    'first', 'second', 'third', 'fourth', 'fifth', 'sixth',
    'seventh', 'eighth', 'ninth', 'tenth', 'last', 'next',
    'previous', 'before', 'after', 'during', 'while', 'until',
    'since', 'through', 'throughout', 'across', 'around', 'about',
    'above', 'below', 'under', 'over', 'up', 'down', 'out',
    'off', 'away', 'back', 'forward', 'backward', 'inside',
    'outside', 'within', 'without', 'beside', 'between', 'among',
    'against', 'along', 'amid', 'amidst', 'amongst', 'atop',
    'onto', 'per', 'plus', 'minus', 'times', 'divide', 'equal',
    'less', 'more', 'most', 'least', 'best', 'worst', 'better',
    'worse', 'good', 'bad', 'big', 'small', 'large', 'little',
    'long', 'short', 'high', 'low', 'hot', 'cold', 'warm',
    'cool', 'new', 'old', 'young', 'fresh', 'stale', 'clean',
    'dirty', 'empty', 'full', 'heavy', 'light', 'strong', 'weak',
    'hard', 'soft', 'rough', 'smooth', 'wet', 'dry', 'dark',
    'bright', 'clear', 'cloudy', 'sunny', 'rainy', 'snowy',
    'windy', 'calm', 'quiet', 'loud', 'silent', 'noisy', 'busy',
    'free', 'lazy', 'active', 'passive', 'positive', 'negative',
    'important', 'necessary', 'useful', 'useless', 'helpful',
    'harmful', 'safe', 'dangerous', 'easy', 'difficult', 'simple',
    'complex', 'cheap', 'expensive', 'rich', 'poor', 'healthy',
    'sick', 'well', 'ill', 'fine', 'okay', 'alright', 'great',
    'terrible', 'awful', 'horrible', 'wonderful', 'amazing',
    'fantastic', 'excellent', 'perfect', 'imperfect', 'flawed',
  };

  // Emotion and mood keywords to give more weight
  static const Map<String, double> _emotionWeights = {
    'stress': 2.0,
    'stressed': 2.0,
    'anxious': 2.0,
    'anxiety': 2.0,
    'worry': 2.0,
    'worried': 2.0,
    'happy': 2.0,
    'joy': 2.0,
    'excited': 2.0,
    'excitement': 2.0,
    'sad': 2.0,
    'sadness': 2.0,
    'depressed': 2.0,
    'angry': 2.0,
    'anger': 2.0,
    'frustrated': 2.0,
    'frustration': 2.0,
    'calm': 2.0,
    'peaceful': 2.0,
    'relaxed': 2.0,
    'tired': 2.0,
    'exhausted': 2.0,
    'fatigued': 2.0,
    'grateful': 2.0,
    'gratitude': 2.0,
    'thankful': 2.0,
    'proud': 2.0,
    'confidence': 2.0,
    'confident': 2.0,
    'lonely': 2.0,
    'overwhelmed': 2.0,
    'confused': 2.0,
    'disappointed': 2.0,
    'love': 2.0,
    'hate': 2.0,
    'fear': 2.0,
    'hope': 2.0,
    'dream': 1.5,
    'goal': 1.5,
    'success': 1.5,
    'failure': 1.5,
    'achieve': 1.5,
    'accomplish': 1.5,
    'work': 1.2,
    'job': 1.2,
    'career': 1.2,
    'family': 1.5,
    'friend': 1.5,
    'relationship': 1.5,
    'health': 1.5,
    'exercise': 1.3,
    'sleep': 1.3,
    'food': 1.2,
    'eat': 1.2,
    'money': 1.3,
    'financial': 1.3,
    'pay': 1.2,
    'bill': 1.2,
    'travel': 1.3,
    'trip': 1.3,
    'vacation': 1.3,
    'holiday': 1.3,
  };

  Future<List<SimilarEntry>> findSimilarEntries(JournalEntryEntity currentEntry) async {
    try {
      // Get all past entries (excluding current)
      final allEntries = await _repository.getAllEntries();
      final pastEntries = allEntries.where((entry) => entry.id != currentEntry.id).toList();

      if (pastEntries.isEmpty) return [];

      // Extract keywords from current entry
      final currentKeywords = _extractKeywords(currentEntry.text);

      // Calculate similarity scores
      final similarEntries = <SimilarEntry>[];
      
      for (final entry in pastEntries) {
        final entryKeywords = _extractKeywords(entry.text);
        final similarityScore = _calculateSimilarity(currentKeywords, entryKeywords);
        
        if (similarityScore > 0) {
          similarEntries.add(SimilarEntry(
            entry: entry,
            similarityScore: similarityScore,
          ));
        }
      }

      // Sort by similarity score and return top 3
      similarEntries.sort((a, b) => b.similarityScore.compareTo(a.similarityScore));
      return similarEntries.take(3).toList();
      
    } catch (e) {
      // Return empty list if search fails
      return [];
    }
  }

  Set<String> _extractKeywords(String text) {
    final words = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), ' ').split(' ');
    final keywords = <String>{};
    
    for (final word in words) {
      if (word.length >= 3 && !_stopWords.contains(word)) {
        keywords.add(word);
      }
    }
    
    return keywords;
  }

  double _calculateSimilarity(Set<String> keywords1, Set<String> keywords2) {
    if (keywords1.isEmpty || keywords2.isEmpty) return 0.0;

    // Find common keywords
    final commonKeywords = keywords1.intersection(keywords2);
    
    if (commonKeywords.isEmpty) return 0.0;

    // Calculate weighted score
    double totalScore = 0.0;

    for (final keyword in commonKeywords) {
      final weight = _emotionWeights[keyword] ?? 1.0;
      totalScore += weight;
    }

    // Normalize by the smaller set to avoid bias
    final normalizationFactor = keywords1.length < keywords2.length ? keywords1.length : keywords2.length;
    
    // Add bonus for multiple common keywords
    final keywordCountBonus = commonKeywords.length > 1 ? commonKeywords.length * 0.1 : 0.0;
    
    return (totalScore / normalizationFactor) + keywordCountBonus;
  }

  String generateSimilarEntriesMessage(List<SimilarEntry> similarEntries) {
    if (similarEntries.isEmpty) return '';

    final message = StringBuffer();
    message.writeln("You wrote something similar before:");
    
    for (int i = 0; i < similarEntries.length; i++) {
      final similarEntry = similarEntries[i];
      final preview = _generatePreview(similarEntry.entry.text);
      final dateStr = similarEntry.entry.formattedDate;
      
      message.writeln("• $dateStr: $preview");
    }
    
    return message.toString().trim();
  }

  String _generatePreview(String text, {int maxLength = 80}) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }
}

class SimilarEntry {
  final JournalEntryEntity entry;
  final double similarityScore;

  SimilarEntry({
    required this.entry,
    required this.similarityScore,
  });
}
