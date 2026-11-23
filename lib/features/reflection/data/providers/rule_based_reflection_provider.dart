import '../../../journal_entry/domain/entities/journal_entry.dart';
import '../../domain/entities/reflection_message.dart';
import '../../domain/interfaces/reflection_inference_provider.dart';

/// Deterministic, offline psychological reflection provider.
/// Generates thoughtful, grounded questions without misrepresenting itself as generative AI.
class RuleBasedReflectionProvider implements ReflectionInferenceProvider {
  @override
  String get name => 'Guided Reflection Engine';

  @override
  ReflectionSource get source => ReflectionSource.deterministicPrompt;

  @override
  bool get isAvailable => true;

  @override
  bool get isLocal => true;

  @override
  Future<String> generateResponse({
    required JournalEntryEntity currentEntry,
    required List<JournalEntryEntity> relatedMemories,
    required String userMessage,
    required List<ReflectionMessage> conversationHistory,
  }) async {
    final lower = userMessage.toLowerCase().trim();

    // Check for expressions of distress or need for coping strategies
    if (lower.contains('overwhelm') || lower.contains('stress') || lower.contains('too much') || lower.contains('cannot handle')) {
      return 'When everything feels like too much, it helps to narrow your focus to the single next step. '
          'Looking at what you wrote, what is one small thing within your direct control right now?';
    }

    if (lower.contains('help') || lower.contains('advice') || lower.contains('what should i do')) {
      return 'While I cannot tell you what decisions to make, your own past writings often hold your deepest values. '
          'If a close friend came to you with this exact situation, what kind words or perspective would you offer them?';
    }

    if (lower.contains('sad') || lower.contains('cry') || lower.contains('hurt') || lower.contains('pain') || lower.contains('lonely')) {
      return 'It takes genuine courage to sit with heavy emotions without rushing to dismiss them. '
          'Where in your body do you feel this sadness most strongly, and what kind of comfort feels most needed right now?';
    }

    if (lower.contains('angry') || lower.contains('frustrat') || lower.contains('mad') || lower.contains('annoy')) {
      return 'Anger is frequently a signal that an important boundary or core value was crossed. '
          'What boundary felt compromised, and what would it look like to honor that boundary going forward?';
    }

    if (lower.contains('happy') || lower.contains('joy') || lower.contains('excite') || lower.contains('grateful') || lower.contains('proud')) {
      return 'It is deeply restorative to linger in moments of joy and accomplishment. '
          'What specific choice or quality in yourself contributed to this positive outcome?';
    }

    if (lower.contains('why') || lower.contains('reason') || lower.contains('understand')) {
      return 'Searching for the "why" can bring clarity, but sometimes understanding arrives only after we accept the feeling as it is. '
          'What is one assumption you might be making about this situation that could be gently questioned?';
    }

    if (lower.contains('future') || lower.contains('worry') || lower.contains('anxious') || lower.contains('fear')) {
      return 'Anxiety often tries to solve tomorrow’s problems with today’s energy. '
          'What is one grounding reality of your immediate physical surroundings that you can lean into right now?';
    }

    // Reference related memories if present
    if (relatedMemories.isNotEmpty) {
      final memory = relatedMemories.first;
      return 'As you reflect on this, consider that on ${memory.formattedDate} you explored similar themes around ${memory.mood.label.toLowerCase()} moments. '
          'How does your perspective today differ from how you saw things back then?';
    }

    // Default open-ended contemplative response
    return 'Thank you for exploring that thought. Reflection is not about having instant answers, but giving yourself permission to look honestly at your experience. '
        'What feels most meaningful or unspoken beneath these thoughts?';
  }
}
