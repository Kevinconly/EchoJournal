import '../../../journal_entry/domain/entities/journal_entry.dart';
import '../entities/reflection_message.dart';

/// Pluggable interface for reflection intelligence providers.
/// Allows swapping between local compact models, rule-based heuristics, and remote models.
abstract class ReflectionInferenceProvider {
  String get name;
  ReflectionSource get source;
  bool get isAvailable;
  bool get isLocal;

  Future<String> generateResponse({
    required JournalEntryEntity currentEntry,
    required List<JournalEntryEntity> relatedMemories,
    required String userMessage,
    required List<ReflectionMessage> conversationHistory,
  });
}
