# EchoJournal

EchoJournal is a private, offline-first personal reflection and journaling application built with Flutter. It helps users capture their thoughts, trace emotional patterns, and introspect through an honest, grounded reflection experience and contextual memory retrieval.

> **Current release: v1.0.3** — Modular offline reflection engine, reactive theme system, centralized dependency injection, hardened backup validation, and the official EchoJournal app identity across all platforms.

---

## 🌟 Core Philosophy

- **Absolute Privacy by Default:** All journal entries, reflections, and mood data are stored strictly on-device in local storage. No network connection is ever required, and no private thoughts are transmitted to remote servers.
- **Genuine Intelligence & Honest Attribution:** The app clearly distinguishes between guided psychological prompts, memory retrieval from past entries, and automated heuristics. Deterministic reflection is never deceptively labeled as generative AI.
- **Data Integrity & Safety:** Safe backup and restore with full pre-validation, atomic import verification, and duplicate prevention. User entries are never silently overwritten or discarded.
- **Thoughtful, Calming Design:** Warm parchment tones, deep forest cedar accents, restrained typography, and a refined interface that honors the vulnerability and focus required for journaling.

---

## 🛠 Tech Stack

- **Flutter 3.50+ / Dart 3.14+** (Material 3 modular architecture)
- **Local Persistence:** Hive (TypeAdapter 0 with zero external daemon requirements)
- **Settings & Theme Synchronization:** `SharedPreferences` with reactive `ThemeController` (`ValueNotifier<ThemeMode>`)
- **Data Visualizations:** `fl_chart` (mood breakdowns and thematic tag analytics)
- **Backup & File Handling:** `file_picker` and `path_provider` (safe JSON import/export with cross-platform path resolution)

---

## 🏗 Architecture & Code Structure

The project follows Clean Architecture principles with clear domain, data, and presentation boundaries:

```
lib/
├── core/
│   ├── constants/        # Centralized app constants, strings, and radii
│   ├── di/               # Centralized ServiceLocator ensuring shared repository cache
│   └── theme/            # Semantic color tokens, light/dark themes, and ThemeController
├── features/
│   ├── journal_entry/
│   │   ├── data/repositories/  # JournalRepositoryImpl backed by Hive
│   │   ├── domain/
│   │   │   ├── entities/       # JournalEntryEntity, Mood enum
│   │   │   ├── repositories/   # JournalRepository contract
│   │   │   ├── services/       # CachedRepository with auto-invalidation, BackupService
│   │   │   └── usecases/       # SaveJournalEntryUseCase
│   │   └── presentation/       # JournalEntryScreen (create & edit), input widgets
│   ├── journal_list/
│   │   └── presentation/       # HomeScreen, EntryDetailsScreen, InsightsScreen, SettingsScreen
│   └── reflection/
│       ├── data/providers/     # RuleBasedReflectionProvider
│       ├── domain/
│       │   ├── entities/       # ReflectionMessage with explicit ReflectionSource
│       │   ├── interfaces/     # ReflectionInferenceProvider interface
│       │   └── services/       # ContextRetrievalService, ReflectionCoordinator
│       └── presentation/       # ReflectionChatScreen
├── models/                     # Hive TypeAdapter data models
└── shared/
    ├── utils/                  # AppErrorHandler and dialog helpers
    └── widgets/                # AnimatedFAB, HighlightedText, LoadingOverlay
```

---

## 🤖 Offline Reflection & Memory Retrieval Architecture

EchoJournal's reflection system is decoupled into four modular layers:

1. **Context & Memory Retrieval (`ContextRetrievalService`):**
   - Scans the user's historical entries using tokenization and stop-word filtering.
   - Computes semantic relevance by matching common themes, user-assigned tags, and mood coherence.
   - Highlights connected memories without ever sending text over a network.

2. **Inference Provider Interface (`ReflectionInferenceProvider`):**
   - Pluggable interface supporting deterministic heuristic providers, compact on-device models, or future extensions without rewriting the application.
   - Default provider: `RuleBasedReflectionProvider`, delivering psychologically grounded prompts (cognitive reframing, boundary inquiries, mindfulness anchors).

3. **Session Coordination (`ReflectionCoordinator`):**
   - Manages message streams and async lifecycles, eliminating memory leaks and unmanaged timers.
   - Dynamically formulates initial grounding questions and offers interactive follow-up prompt chips.

4. **Transparent Message Attribution:**
   - Every message displays its genuine origin: `You`, `Guided Reflection`, `Memory Rediscovery`, or `On-Device AI`.
   - Never misleads users by claiming deterministic heuristics are generative AI.

---

## 💾 Safe Backup & Restore Specification

EchoJournal implements a non-destructive, strictly validated backup format.

### Supported Schema (`v1.0` and `v1.1`)

```json
{
  "version": "1.1",
  "appName": "EchoJournal",
  "exportDate": "2026-11-23T17:30:00.000Z",
  "totalEntries": 2,
  "entries": [
    {
      "id": 1,
      "content": "Morning walk in the forest",
      "mood": "Calm",
      "createdAt": "2026-11-23T08:30:00.000Z",
      "tags": ["nature", "mindfulness"]
    }
  ]
}
```

### Safety Guarantees:
- **Pre-Validation:** The entire JSON document and every single entry are validated in memory before any database write occurs. Malformed fields trigger actionable error reports rather than unhandled crashes.
- **De-Duplication (`Merge` Mode):** Duplicate signatures (`timestamp + text`) prevent duplicate entries if a backup is restored multiple times.
- **Replace Option:** Destructive overwrite is only performed when explicitly selected by the user via confirmation.
- **Cancellation:** Dismissing the file picker returns a clean cancellation state without presenting false error notifications.

---

## 🎨 Visual Identity & Theme System

- **Warm Neutrals:** Base surfaces built on warm parchment (`#FAF8F5`) in light mode and deep espresso charcoal (`#141312`) in dark mode to prevent eye strain during nocturnal journaling.
- **Primary Accent:** Forest cedar sage (`#28544C` / `#82B8AB`) symbolizing tranquility and mental clarity.
- **Secondary Accent:** Terracotta clay (`#855843` / `#D69C82`) bringing warmth and human connection.
- **Reactive Theme Controller:** Seamless instant switching between **System Default**, **Light Mode**, and **Dark Mode** via `ThemeController.themeModeNotifier`.
- **Refined Shapes:** 14px card corners and 12px button corners providing a clean, contemporary editorial feel.

---

## 🧪 Testing & Verification

EchoJournal includes comprehensive test suites covering unit domain logic, cache synchronization, backup schema validation, offline reflection, theme persistence, and widget flows.

### Running Tests:
```bash
# Run unit and widget tests
flutter test

# Run static analysis
flutter analyze

# Verify compilation
flutter build apk --debug
```

### Verified Test Coverage:
- **`test/backup_service_test.dart`**: Schema v1.0/v1.1 validation, version rejection, malformed entry handling, signature deduplication, path normalization, JSON serialization.
- **`test/repository_and_cache_test.dart`**: Cache hits, cache invalidation on save/update/delete, full storage purge.
- **`test/reflection_intelligence_test.dart`**: Stop-word filtering, memory relevance scoring, distress coping responses, coordinator lifecycle, non-AI honest attribution.
- **`test/theme_controller_test.dart`**: Cold-start loading, reactive state emission, persistence, legacy key migration.
- **`test/journal_entry_test.dart` & `test/unit_test.dart`**: Entity instantiation, `copyWith`, date formatting, Mood enum mappings.
- **`test/widget_test.dart`**: Smoke test, empty state with prompt suggestions, journal card rendering and tap interactions.

---

## 🚀 Getting Started

1. **Prerequisites:**
   - Flutter SDK 3.50+ installed and on your PATH
   - Dart 3.14+

2. **Clone & Setup:**
   ```bash
   git clone https://github.com/Kevinconly/EchoJournal.git
   cd EchoJournal
   flutter pub get
   ```

3. **Run Application:**
   ```bash
   flutter run
   ```

---

## 📄 License

EchoJournal is licensed under the MIT License.
