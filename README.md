# EchoJournal

EchoJournal is an **offline-first journaling mobile app** that turns personal thoughts into interactive conversations. Instead of only writing entries, users can reflect on them through a chat-style interface that suggests prompts and helps rediscover similar past memories.

## ✨ Features

* 📝 Private journal entries with mood tracking and tags
* 🤖 AI-powered reflection chat (completely offline)
* 📊 Mood insights with pie charts and statistics
* 🔍 Real-time search with text highlighting
* 💾 Local backup/restore functionality (JSON) - cross-platform reliable
* ⚙️ Settings with dark mode toggle
* 🎨 Beautiful Material 3 design
* 📱 Cross-platform support (iOS, Android, Web, Desktop)
* 🔒 Complete privacy - all data stored locally

## 🛠 Tech Stack

* **Flutter** with Material 3 UI
* **Hive Database** for local storage (switched from Isar due to build compatibility)
* **FL Chart** for mood visualizations
* **File Picker** for backup/restore
* **Shared Preferences** for settings
* **Clean Architecture** pattern

## 🏗 Architecture

* **Domain Layer** - Business logic and entities
* **Data Layer** - Repository pattern with caching
* **Presentation Layer** - UI components and screens
* **Offline-First Design** - No internet required
* **Production-Ready Error Handling**

## 🚀 Current Status

**Version:** 1.0.2 (Latest)
**Status:** Production Ready ✅
**Code Quality:** Clean analysis with no warnings/errors
**Last Update:** March 14, 2026 - Database migration and backup fixes

### 🔧 v1.0.2 Database & Backup Improvements
- ✅ **Switched to Hive Database**: Replaced Isar with Hive for better build compatibility and reliability
- ✅ **Enhanced Backup/Export**: Cross-platform export with proper cancellation handling and fallback to app documents
- ✅ **Fixed Import Functionality**: Reliable JSON import with error handling and duplicate prevention
- ✅ **Added Tags Support**: Journal entries now support tags for better organization
- ✅ **Improved Data Persistence**: Fixed entry count sync and real-time updates without app restart
- ✅ **Code Cleanup**: Removed unused Isar code, fixed analyzer warnings, and optimized imports
- ✅ **All tests passing**: Unit tests, widget tests, and integration verified
- ✅ **Production-ready**: No runtime errors, stable backup/import across all platforms

### 🔧 v1.0.1 Final Improvements (Previous)
- ✅ MASSIVE 86% code quality improvement (195 → 27 issues)
- ✅ Resolved major structural issues in insights_screen.dart
- ✅ Fixed PieChartSectionData compatibility with fl_chart
- ✅ Fixed DatabaseService constructor calls throughout codebase
- ✅ Fixed BorderRadius parameter handling
- ✅ Updated all deprecated API usage
- ✅ **All tests now passing:**
  - Unit tests: 6/6 ✅
  - Widget tests: 1/1 ✅
  - App smoke test: ✅
- ✅ Core functionality verified and working
- ✅ Production-ready with minimal remaining issues

## 📋 Installation

1. Clone the repository
2. Run `flutter pub get`
3. Run `flutter run`

## 🔒 Privacy

All journal data is stored **locally on the device**. No internet connection or cloud storage is required. Your thoughts remain completely private.

## 📌 Goal

EchoJournal aims to make journaling more engaging by allowing users to **chat with their past thoughts** and better understand their emotions over time.

## 🛣 Future Plans

* Optional cloud sync
* Advanced AI insights
* Cross-device journaling
* Emotional trend analysis with enhanced tag analytics
* Mobile app store deployment (iOS/Android)

---

**Built with ❤️ using Flutter**
