import '../../../journal_entry/domain/entities/journal_entry.dart';

/// Explicit classification of the message origin to guarantee transparency and honesty.
enum ReflectionSource {
  user,
  deterministicPrompt,  // Guided psychological prompts and questions
  memoryRetrieval,      // Semantic search results from past entries
  localModel,           // On-device ML/compact LLM inference
  remoteModel,          // Optional remote LLM (requires user consent)
}

class ReflectionMessage {
  final String id;
  final String text;
  final ReflectionSource source;
  final DateTime timestamp;
  final List<JournalEntryEntity> referencedEntries;
  final List<String> suggestedFollowUps;

  const ReflectionMessage({
    required this.id,
    required this.text,
    required this.source,
    required this.timestamp,
    this.referencedEntries = const [],
    this.suggestedFollowUps = const [],
  });

  bool get isUser => source == ReflectionSource.user;

  String get sourceLabel {
    switch (source) {
      case ReflectionSource.user:
        return 'You';
      case ReflectionSource.deterministicPrompt:
        return 'Guided Reflection';
      case ReflectionSource.memoryRetrieval:
        return 'Memory Rediscovery';
      case ReflectionSource.localModel:
        return 'On-Device AI';
      case ReflectionSource.remoteModel:
        return 'AI Assistant';
    }
  }
}
