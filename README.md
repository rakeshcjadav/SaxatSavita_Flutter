# 📱 Sakshat Savita (સાક્ષાત્ સવિતા)

> A digital reading companion for the complete Sakshat Savita collection

**Language:** **English** | [ગુજરાતી](README_gu.md)

[![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-blue.svg)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Private-red.svg)]()
[![Version](https://img.shields.io/badge/Version-2.49.0-green.svg)]()

## 🌟 Overview

Sakshat Savita is a Flutter app for reading the granth offline, with English and Gujarati UI. Kiran text stays in Gujarati. Beside reading, it covers progress, notes, search, people in the sittings, maps of vicharan, daily teaching quizzes, and kiran quizzes after you finish a sitting.

## ✨ Key Features

### 📚 **Reading**
- **Complete library**: All 5 parts and 697 kirans, available offline
- **Kiran info**: Gujarati date, village and venue, teaching (moral), summary, and history from a sheet on the read page and kiran list
- **Village filter**: Narrow lists and the calendar by place
- **Calendar and chronology**: Browse kirans by tithi/date and in time order
- **Search**: Multi-word search across titles and text, with haribhakt name matches
- **Favorites and bookmarks**: Mark kirans and jump back to a position
- **Listen**: Text-to-speech (voice and rate in Settings), plus recorded audio when a kiran has it
- **Reading comfort**: Reading text size, app UI text size, line height, keep-screen-on, optional edge navigation, light/dark themes and color schemes

### 🧭 **Places and people**
- **Haribhakts**: Browse hosts, readers, people who asked questions, and those mentioned; search by name; sort by kiran count
- **In the kiran**: Names are highlighted; tap a chip to find that person in the text, long-press to open their profile and questions
- **Vicharan map**: OpenStreetMap of trips, with Piplana Dikshadham as home, inbound routes, and sitting details
- **Place map**: See villages and open a kiran from the map

### 🧠 **Quizzes (પ્રશ્નોત્તર)**
- **Today's teaching (આજનો ઉપદેશ)**: Five questions drawn from the whole granth (not one kiran). Options are shuffled; the source kiran is shown after you answer
- **Home and dashboard**: Shortcut on Home until today's quiz is done; dashboard card with score and an embedded leaderboard
- **Daily and weekly leaderboards**: Rank number on each row; gold, silver, and bronze trophies for the top three
- **Streak and reminder**: Daily quiz streak, plus an optional local reminder at a time you choose
- **Kiran quiz**: After you have read a kiran, three random scored questions, then optional extra practice. One scored attempt per kiran; points sync when you are signed in
- **Offline-friendly**: Banks load from Firebase when reachable, with a local/bundled fallback

### 🏠 **Home, dashboard, and navigation**
- **Dashboard**: Time-based greeting, reading streaks, statistics, active plan, recent activity, daily quiz, and quick actions
- **Bottom bar**: Dashboard, book (Home), Notes, Reading history, Profile — selected tab is highlighted
- **Welcome tour**: First-run walkthrough of the main surfaces
- **Home screen widgets** (Android and iOS): Daily reading time, kirans read, streak, and a progress bar

### 📝 **Notes, plans, and quotes**
- **Notes**: Rich text (Quill) tied to kirans
- **Reading plans**: Daily goals (time or kirans), reminders, and milestone tracking
- **Reading history**: Sessions, timers, and completion
- **Quote images**: Templates, fonts, gradients, stickers, save to gallery, and share

### 🙏 **Aashirvachan and information**
- **Aashirvachan**: Blessings collection
- **Information**: Preface and other book front matter

### ☁️ **Accounts and sync**
- **Sign in**: Google and Sign in with Apple, or continue as a guest (some items stay in the signed-in drawer only)
- **Profile**: Name and place, used on the dashboard greeting
- **Cloud sync**: Notes, progress, plans, quiz results, and rewards across devices when signed in
- **Play Store updates**: In-app update prompt with store fallback
- **Remote Config**: Feature flags (for example daily quiz) without a store wait

## 🏗️ Architecture

### Tech Stack
- **Frontend**: Flutter 3.7.2+
- **Backend**: Firebase (Auth, Firestore, Remote Config, Analytics)
- **Local storage**: SharedPreferences for settings, cache, and offline quiz/results
- **Authentication**: Firebase Auth with Google and Apple
- **Maps**: OpenStreetMap via flutter_map
- **Speech**: flutter_tts and just_audio
- **Widgets**: home_widget (Android + iOS)
- **Notifications**: flutter_local_notifications (plans and daily quiz reminder)

### Project Structure
```
lib/
├── auth/                    # Sign-in pages
├── components/              # Drawer, app bar, shared chrome
├── helpers/                 # Navigation helpers
├── l10n/                    # English and Gujarati ARB + generated l10n
├── models/                  # Book, user, quiz, map, and profile models
├── pages/                   # Screens
├── services/                # Book, Firebase, quiz, map, TTS, widgets
├── widgets/                 # Leaderboard tiles, kiran meta, quiz UI
└── main.dart

assets/
├── book/                    # Kirans, quizzes, haribhakt and map data
├── jsons/                   # Extra metadata
├── res/                     # Images
└── stickers/                # Quote-generator stickers
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.7.2 or higher)
- Android Studio / VS Code
- Firebase project setup
- Android/iOS development environment

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/rakeshcjadav/SaxatSavita_Flutter.git
   cd SaxatSavita_Flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Firebase Setup**
   - Create a Firebase project
   - Add Android/iOS apps
   - Place `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the platform folders
   - Enable Authentication (Google, Apple), Firestore, Analytics, and Remote Config
   - Deploy rules from `firestore.rules` (do not use a hand-written subset)

4. **Run the application**
   ```bash
   flutter run
   ```

### Build for Release

**Android APK:**
```bash
flutter build apk --release
```

**Android App Bundle:**
```bash
flutter build appbundle --release
```

**iOS:**
```bash
flutter build ios --release
```

## 📱 Features Deep Dive

### Reading a kiran
- Open a part, filter by village or favorites, then read with automatic session timing
- Kiran info sheet: date, place path, teaching, summary, and related history
- Haribhakt chips in the sitting; tap to jump in the text
- After at least one read, take the kiran quiz (પ્રશ્નોત્તર)

### Today's teaching
- Five scored questions from across the granth
- After each answer, see the source kiran and open it
- Complete once per day for the leaderboard; you can still review
- Optional local reminder from Settings

### Maps
- Calendar days link into place context
- Vicharan trips plot the route with Piplana Dikshadham as home
- Tap a stop to open that kiran

### Customization
- Separate **reading** and **app UI** font sizes
- Material 3 light/dark, seed color, variant, and contrast
- English or Gujarati interface (kiran body remains Gujarati)

## 🔧 Configuration

### Firebase
1. Create a project at [Firebase Console](https://console.firebase.google.com)
2. Enable Authentication, Firestore, Analytics, and Remote Config
3. Use the repository `firestore.rules` and deploy them with the project deploy scripts

### Home widgets
- **iOS**: App Group `group.com.saxatsavita.flutter.widgets`, URL scheme `saxatsavita://` — see `docs/IOS_WIDGET_SETUP.md`
- **Android**: `ReadingProgressWidget` in the app module

## 📖 Usage

1. **First launch**: Welcome tour, then sign in (Google or Apple) or continue as guest
2. **Dashboard**: Greeting, streak, today's teaching, and shortcuts
3. **Book**: Five parts → kiran list → read, listen, notes, info, quiz
4. **Search / haribhakts**: Find a teaching or a person
5. **Map and calendar**: Follow vicharan or “on this day”
6. **Plans and history**: Set a daily goal and review sessions
7. **Quotes**: Build a shareable image with templates and stickers

## 🤝 Contributing

We welcome contributions to improve Sakshat Savita. Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter best practices and conventions
- Write meaningful commit messages
- Add comments for complex logic
- Test on both Android and iOS
- Keep kiran quizzes and summaries grounded in the book; do not invent doctrine
- Ensure accessibility compliance

## 📄 License

This project is private and proprietary. All rights reserved.

## 🙏 Acknowledgments

- Flutter team for the framework
- Firebase for backend services
- The spiritual community for inspiration and feedback
- Contributors and testers who helped improve the app

## 📞 Support

For support, feature requests, or bug reports, create an issue in this repository.

## 🔄 Version History

### Version 2.49.0 (Current)
- **Dashboard and chrome**: Outlined dashboard cards, tighter drawer header, highlighted bottom-nav tab
- **Today's teaching**: Whole-granth daily quiz, reminder, Home CTA until done, daily/weekly leaderboards with numbered ranks and medals
- **Kiran quiz**: Firestore-backed bank for all kirans; three scored questions then optional practice; synced points
- **Haribhakts**: Hosts, readers, questioners, and mentions; name highlighting in kiran text
- **Kiran meta**: Date, village, teaching, and summary on the read page and lists
- **Maps**: OpenStreetMap vicharan with Piplana Dikshadham as home
- **Reading aids**: Separate app vs reading font size, TTS, home-screen reading-progress widgets
- **Accounts**: Sign in with Apple alongside Google; Play in-app updates
- Material 3 UI, English/Gujarati interface, offline library

### Version 2.0.0
- Material 3 redesign, multi-word search, migration tools, rich notes, Firebase sync

### Version 1.x
- Initial reading, basic notes, early Firebase integration

---

**Built with ❤️ using Flutter**

*Bringing spiritual wisdom to the digital age*
