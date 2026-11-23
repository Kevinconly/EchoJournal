import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:echo_journal/core/di/service_locator.dart';
import 'package:echo_journal/features/journal_entry/domain/entities/journal_entry.dart';
import 'package:echo_journal/features/journal_entry/domain/entities/mood.dart';
import 'package:echo_journal/features/journal_list/presentation/pages/home_screen.dart';
import 'package:echo_journal/features/journal_list/presentation/widgets/journal_card.dart';
import 'package:echo_journal/main.dart';
import 'backup_service_test.dart'; // FakeJournalRepository

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test loads MaterialApp and HomeScreen', (WidgetTester tester) async {
    final fakeRepo = FakeJournalRepository();
    ServiceLocator.setJournalRepositoryForTesting(fakeRepo);

    await tester.pumpWidget(const EchoJournalApp());
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('EchoJournal'), findsOneWidget);

    ServiceLocator.reset();
  });

  testWidgets('HomeScreen renders empty state when no entries exist', (WidgetTester tester) async {
    final fakeRepo = FakeJournalRepository();
    ServiceLocator.setJournalRepositoryForTesting(fakeRepo);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your quiet space awaits'), findsOneWidget);
    expect(find.text('Gentle prompts to begin:'), findsOneWidget);

    ServiceLocator.reset();
  });

  testWidgets('HomeScreen renders entries list when entries exist', (WidgetTester tester) async {
    final fakeRepo = FakeJournalRepository();
    await fakeRepo.saveEntry(JournalEntryEntity(
      id: 1,
      text: 'Morning walk in the forest',
      mood: Mood.calm,
      timestamp: DateTime(2026, 11, 23, 8, 30),
      tags: const ['nature', 'morning'],
    ));
    ServiceLocator.setJournalRepositoryForTesting(fakeRepo);

    await tester.pumpWidget(
      const MaterialApp(
        home: HomeScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(JournalCard), findsOneWidget);
    expect(find.text('Calm'), findsOneWidget);
    expect(find.text('#nature'), findsOneWidget);

    ServiceLocator.reset();
  });

  testWidgets('JournalCard renders tags and calls onTap callback', (WidgetTester tester) async {
    bool tapped = false;
    final entry = JournalEntryEntity(
      id: 5,
      text: 'Testing card rendering functionality',
      mood: Mood.happy,
      timestamp: DateTime(2026, 11, 23, 14, 0),
      tags: const ['testing', 'ui'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: JournalCard(
            entry: entry,
            onTap: () => tapped = true,
          ),
        ),
      ),
    );

    expect(find.text('Happy'), findsOneWidget);
    expect(find.text('#testing'), findsOneWidget);

    await tester.tap(find.byType(JournalCard));
    expect(tapped, isTrue);
  });
}
