import 'dart:async';
import '../../../journal_entry/domain/entities/journal_entry.dart';
import '../../../journal_entry/domain/repositories/journal_repository.dart';
import '../../data/providers/rule_based_reflection_provider.dart';
import '../entities/reflection_message.dart';
import '../interfaces/reflection_inference_provider.dart';
import 'context_retrieval_service.dart';

class ReflectionCoordinator {
  final JournalEntryEntity currentEntry;
  final JournalRepository repository;
  final ReflectionInferenceProvider provider;
  final ContextRetrievalService _contextService;

  final List<ReflectionMessage> _messages = [];
  List<RelevantMemory> _relatedMemories = [];
  bool _isProcessing = false;

  final _messageStreamController = StreamController<List<ReflectionMessage>>.broadcast();
  final _processingStreamController = StreamController<bool>.broadcast();

  ReflectionCoordinator({
    required this.currentEntry,
    required this.repository,
    ReflectionInferenceProvider? provider,
  })  : provider = provider ?? RuleBasedReflectionProvider(),
        _contextService = ContextRetrievalService(repository);

  Stream<List<ReflectionMessage>> get messagesStream => _messageStreamController.stream;
  Stream<bool> get isProcessingStream => _processingStreamController.stream;
  List<ReflectionMessage> get messages => List.unmodifiable(_messages);
  List<RelevantMemory> get relatedMemories => List.unmodifiable(_relatedMemories);
  bool get isProcessing => _isProcessing;

  /// Start the reflection session with contextual opening, prompts, and past memories
  Future<void> initializeSession() async {
    _setProcessing(true);

    try {
      // 1. Initial grounding message
      final initialOpening = _generateOpening();
      _messages.add(ReflectionMessage(
        id: 'init_${DateTime.now().millisecondsSinceEpoch}',
        text: initialOpening,
        source: ReflectionSource.deterministicPrompt,
        timestamp: DateTime.now(),
      ));
      _emitMessages();

      // 2. Retrieve related past entries from repository
      _relatedMemories = await _contextService.findRelatedMemories(currentEntry);
      if (_relatedMemories.isNotEmpty) {
        final pastEntries = _relatedMemories.map((m) => m.entry).toList();
        final memoryText = _formatMemoriesSummary(_relatedMemories);
        _messages.add(ReflectionMessage(
          id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
          text: memoryText,
          source: ReflectionSource.memoryRetrieval,
          timestamp: DateTime.now(),
          referencedEntries: pastEntries,
        ));
        _emitMessages();
      }

      // 3. Formulate starter follow-up questions
      final questions = _contextService.generateInitialQuestions(currentEntry);
      if (questions.isNotEmpty) {
        _messages.add(ReflectionMessage(
          id: 'q_${DateTime.now().millisecondsSinceEpoch}',
          text: 'Here are a few questions you might explore:',
          source: ReflectionSource.deterministicPrompt,
          timestamp: DateTime.now(),
          suggestedFollowUps: questions,
        ));
        _emitMessages();
      }
    } finally {
      _setProcessing(false);
    }
  }

  /// Process user reflection reply
  Future<void> sendUserMessage(String text) async {
    final clean = text.trim();
    if (clean.isEmpty) return;

    final userMsg = ReflectionMessage(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      text: clean,
      source: ReflectionSource.user,
      timestamp: DateTime.now(),
    );

    _messages.add(userMsg);
    _emitMessages();
    _setProcessing(true);

    try {
      final pastEntries = _relatedMemories.map((m) => m.entry).toList();
      final replyText = await provider.generateResponse(
        currentEntry: currentEntry,
        relatedMemories: pastEntries,
        userMessage: clean,
        conversationHistory: _messages,
      );

      final assistantMsg = ReflectionMessage(
        id: 'reply_${DateTime.now().millisecondsSinceEpoch}',
        text: replyText,
        source: provider.source,
        timestamp: DateTime.now(),
      );

      _messages.add(assistantMsg);
      _emitMessages();
    } catch (e) {
      _messages.add(ReflectionMessage(
        id: 'err_${DateTime.now().millisecondsSinceEpoch}',
        text: 'I could not process this reflection step at this moment. You can still write and preserve your thoughts.',
        source: ReflectionSource.deterministicPrompt,
        timestamp: DateTime.now(),
      ));
      _emitMessages();
    } finally {
      _setProcessing(false);
    }
  }

  String _generateOpening() {
    final mood = currentEntry.mood.label;
    switch (mood.toLowerCase()) {
      case 'happy':
        return 'Welcome to your reflection space. You marked this entry as Happy 😊. Let\'s explore what brought this brightness into your day.';
      case 'calm':
        return 'Welcome to your reflection space. You marked this entry as Calm 😌. Peaceful moments offer wonderful ground for quiet self-reflection.';
      case 'sad':
        return 'Welcome to your reflection space. You marked this entry as Sad 😢. There is no rush to fix or change anything here; your feelings are valid.';
      case 'stressed':
        return 'Welcome to your reflection space. You marked this entry as Stressed 😰. Let us unpack what feels demanding, one piece at a time.';
      case 'excited':
        return 'Welcome to your reflection space. You marked this entry as Excited 🎉. Your enthusiasm is worth celebrating and channeling.';
      default:
        return 'Welcome to your reflection space. Let\'s explore the thoughts and feelings behind this entry.';
    }
  }

  String _formatMemoriesSummary(List<RelevantMemory> memories) {
    final buffer = StringBuffer('From your journal archive, I found past reflections with connected themes:\n');
    for (final mem in memories) {
      final preview = mem.entry.text.length > 70
          ? '${mem.entry.text.substring(0, 70).replaceAll('\n', ' ')}...'
          : mem.entry.text.replaceAll('\n', ' ');
      final themes = mem.commonThemes.isNotEmpty ? ' [${mem.commonThemes.take(2).join(', ')}]' : '';
      buffer.writeln('• ${mem.entry.formattedDate} (${mem.entry.mood.label})$themes: "$preview"');
    }
    return buffer.toString().trim();
  }

  void _emitMessages() {
    if (!_messageStreamController.isClosed) {
      _messageStreamController.add(List.unmodifiable(_messages));
    }
  }

  void _setProcessing(bool processing) {
    _isProcessing = processing;
    if (!_processingStreamController.isClosed) {
      _processingStreamController.add(processing);
    }
  }

  void dispose() {
    _messageStreamController.close();
    _processingStreamController.close();
  }
}
