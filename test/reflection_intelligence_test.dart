import 'package:flutter_test/flutter_test.dart';
import 'package:echo_journal/features/journal_entry/domain/entities/journal_entry.dart';
import 'package:echo_journal/features/journal_entry/domain/entities/mood.dart';
import 'package:echo_journal/features/reflection/data/providers/rule_based_reflection_provider.dart';
import 'package:echo_journal/features/reflection/domain/entities/reflection_message.dart';
import 'package:echo_journal/features/reflection/domain/services/context_retrieval_service.dart';
import 'package:echo_journal/features/reflection/domain/services/reflection_coordinator.dart';
import 'backup_service_test.dart'; // Reusing FakeJournalRepository

void main() {
  group('Reflection Intelligence & Context Retrieval Tests', () {
    late FakeJournalRepository repository;
    late ContextRetrievalService contextService;
    late RuleBasedReflectionProvider provider;

    setUp(() {
      repository = FakeJournalRepository();
      contextService = ContextRetrievalService(repository);
      provider = RuleBasedReflectionProvider();
    });

    test('ContextRetrievalService extracts tokens and discards stop words', () {
      final current = JournalEntryEntity(
        id: 1,
        text: 'The weather today was really calm and I walked through the park with my thoughts',
        mood: Mood.calm,
        timestamp: DateTime.now(),
      );

      final questions = contextService.generateInitialQuestions(current);
      expect(questions.isNotEmpty, isTrue);
      expect(questions.first, contains('calm'));
    });

    test('ContextRetrievalService finds related memories by common tags and mood', () async {
      await repository.saveEntry(JournalEntryEntity(
        id: 10,
        text: 'Morning meditation and mindfulness session felt grounding',
        mood: Mood.calm,
        timestamp: DateTime(2026, 10, 1),
        tags: const ['mindfulness', 'morning'],
      ));

      await repository.saveEntry(JournalEntryEntity(
        id: 11,
        text: 'Busy workday full of meetings',
        mood: Mood.stressed,
        timestamp: DateTime(2026, 10, 2),
        tags: const ['work'],
      ));

      final current = JournalEntryEntity(
        id: 12,
        text: 'Evening reflection on mindfulness and finding stillness',
        mood: Mood.calm,
        timestamp: DateTime(2026, 11, 23),
        tags: const ['mindfulness'],
      );

      final related = await contextService.findRelatedMemories(current);
      expect(related.isNotEmpty, isTrue);
      expect(related.first.entry.id, 10);
      expect(related.first.commonThemes, contains('mindfulness'));
    });

    test('RuleBasedReflectionProvider responds constructively to distress keywords', () async {
      final entry = JournalEntryEntity(
        id: 1,
        text: 'Everything is overwhelming right now',
        mood: Mood.stressed,
        timestamp: DateTime.now(),
      );

      final reply = await provider.generateResponse(
        currentEntry: entry,
        relatedMemories: [],
        userMessage: 'I feel completely overwhelmed by everything on my plate',
        conversationHistory: [],
      );

      expect(reply, contains('narrow your focus'));
      expect(provider.source, equals(ReflectionSource.deterministicPrompt));
    });

    test('RuleBasedReflectionProvider responds thoughtfully to anger and boundaries', () async {
      final entry = JournalEntryEntity(
        id: 1,
        text: 'Had an argument at work',
        mood: Mood.stressed,
        timestamp: DateTime.now(),
      );

      final reply = await provider.generateResponse(
        currentEntry: entry,
        relatedMemories: [],
        userMessage: 'I am so angry that my time was completely ignored',
        conversationHistory: [],
      );

      expect(reply, contains('boundary'));
    });

    test('ReflectionCoordinator manages session initialization and message history cleanly', () async {
      final current = JournalEntryEntity(
        id: 1,
        text: 'Starting a new project with excitement',
        mood: Mood.excited,
        timestamp: DateTime.now(),
      );

      final coordinator = ReflectionCoordinator(
        currentEntry: current,
        repository: repository,
        provider: provider,
      );

      await coordinator.initializeSession();

      // Session should have initial message and starter questions
      expect(coordinator.messages.length, greaterThanOrEqualTo(2));
      expect(coordinator.messages.first.source, ReflectionSource.deterministicPrompt);
      expect(coordinator.messages.first.text, contains('Excited'));

      // Send user message
      await coordinator.sendUserMessage('I want to make sure I pace myself this time');

      expect(coordinator.messages.any((m) => m.source == ReflectionSource.user), isTrue);
      expect(coordinator.messages.last.source, ReflectionSource.deterministicPrompt);

      coordinator.dispose();
    });

    test('ReflectionMessage never falsely labels deterministic heuristics as AI', () {
      final msg = ReflectionMessage(
        id: '1',
        text: 'A thoughtful prompt',
        source: ReflectionSource.deterministicPrompt,
        timestamp: DateTime.now(),
      );

      expect(msg.sourceLabel, equals('Guided Reflection'));
      expect(msg.sourceLabel, isNot(contains('AI')));
    });
  });
}
