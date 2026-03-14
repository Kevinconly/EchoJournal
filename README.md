# EchoJournal

EchoJournal is an **offline-first journaling mobile app** that turns personal thoughts into interactive conversations. Instead of only writing entries, users can reflect on them through a chat-style interface that suggests prompts and helps rediscover similar past memories.

## ✨ Features

* 📝 Private journal entries with mood tracking
* 🤖 AI-powered reflection chat (completely offline)
* 📊 Mood insights with pie charts and statistics
* 🔍 Real-time search with text highlighting
* 💾 Local backup/restore functionality (JSON)
* ⚙️ Settings with dark mode toggle
* 🎨 Beautiful Material 3 design
* 📱 Cross-platform support (iOS, Android, Web, Desktop)
* 🔒 Complete privacy - all data stored locally

## 🛠 Tech Stack

* **Flutter** with Material 3 UI
* **Isar Database** for local storage
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

**Version:** 1.0.0 (Development)
**Status:** Ready for GitHub release
**Note:** Contains 212 analyzer issues that need fixing for production deployment

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
* Emotional trend analysis
* Production deployment after fixing analyzer issues

---

**Built with ❤️ using Flutter**
