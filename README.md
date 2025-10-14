# 📱 Sakshaat Savita (સાક્ષાત્ સવિતા)

> A comprehensive digital spiritual reading companion for the complete Sakshaat Savita collection

[![Flutter](https://img.shields.io/badge/Flutter-3.7.2+-blue.svg)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-orange.svg)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-Private-red.svg)]()
[![Version](https://img.shields.io/badge/Version-2.0.0-green.svg)]()

## 🌟 Overview

Sakshaat Savita is a modern Flutter application that provides a complete digital reading experience for the spiritual text collection. The app combines traditional spiritual content with cutting-edge technology to offer personalized reading, progress tracking, and community features.

## ✨ Key Features

### 📚 **Core Reading Experience**
- **Complete Digital Library**: Access all 5 parts of Sakshaat Savita with full content
- **Advanced Search**: Multi-word intelligent search with relevance scoring
- **Reading Progress**: Automatic progress tracking with timers and completion percentages
- **Personalized Notes**: Rich text editor with Quill integration for detailed annotations
- **Favorites & Bookmarks**: Mark favorite Kirans and bookmark reading positions
- **Offline Reading**: Full content available without internet connection

### 🎨 **Content Creation**
- **Quote Generator**: Create beautiful shareable images from book content
- **Custom Templates**: Multiple design templates with geometric and floral patterns
- **Font Customization**: Personalize appearance with various fonts and gradients
- **Social Sharing**: Direct sharing to social media or save to gallery

### 📊 **Analytics & Insights**
- **Reading Statistics**: Track total reading time, sessions, and progress
- **Daily Streaks**: Monitor consistent reading habits
- **Historical Analysis**: Long-term reading pattern insights
- **Goal Tracking**: Reading plan milestones and achievements

### ☁️ **Cloud Features**
- **Firebase Integration**: Real-time data synchronization
- **Google Sign-In**: Secure authentication
- **Cross-Device Sync**: Access your data on any device
- **Automatic Backup**: Never lose your reading progress

### 🔧 **Advanced Tools**
- **Legacy Migration**: Seamless data transfer from older versions
- **Reading Plans**: Create personalized daily reading goals with reminders
- **Multi-language Support**: Full English and Gujarati interface
- **Customizable Themes**: Light/dark mode with multiple color schemes

## 🏗️ Architecture

### Tech Stack
- **Frontend**: Flutter 3.7.2+
- **Backend**: Firebase (Firestore, Authentication, Cloud Functions)
- **State Management**: Provider pattern with ValueNotifiers
- **Local Storage**: SharedPreferences for settings and cache
- **Authentication**: Firebase Auth with Google Sign-In
- **Cloud Storage**: Firebase Storage for user data backup

### Project Structure
```
lib/
├── auth/                    # Authentication pages and logic
├── components/              # Reusable UI components
├── helpers/                 # Helper classes and utilities
├── l10n/                   # Localization files (English & Gujarati)
├── models/                 # Data models and entities
├── pages/                  # UI screens and pages
├── services/               # Business logic and data services
└── main.dart              # Application entry point

assets/
├── book/                   # Book content and data
├── jsons/                  # Configuration and metadata
└── res/                    # Images and resources
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
   - Create a new Firebase project
   - Add Android/iOS apps to Firebase
   - Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
   - Place configuration files in respective platform directories
   - Enable Authentication and Firestore in Firebase Console

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

### Authentication System
- Secure Google Sign-In integration
- Anonymous reading mode available
- User profile management
- Privacy-focused data handling

### Reading Experience
- **Smart Search**: Advanced search with multi-word support and relevance scoring
- **Progress Tracking**: Automatic session tracking with reading analytics
- **Note System**: Rich text notes with Quill editor integration
- **Bookmarking**: Quick access to favorite content and reading positions

### Data Migration
- **Legacy Support**: Seamless migration from older app versions
- **Firebase Migration**: Comprehensive tools for data structure updates
- **Progress Preservation**: Ensures no data loss during upgrades

### Customization Options
- **Theme System**: Material 3 design with light/dark modes
- **Typography**: Adjustable font sizes and reading preferences
- **Language Support**: Bilingual interface (English/Gujarati)
- **Reading Settings**: Customizable reading speed and display options

## 🔧 Configuration

### Firebase Setup
1. Create Firebase project at [Firebase Console](https://console.firebase.google.com)
2. Enable the following services:
   - Authentication (Google provider)
   - Firestore Database
   - Cloud Storage
3. Configure security rules for Firestore:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /users/{userId}/{document=**} {
         allow read, write: if request.auth != null && request.auth.uid == userId;
       }
     }
   }
   ```

### Environment Variables
Create a `.env` file in the project root:
```env
FIREBASE_PROJECT_ID=your_project_id
GOOGLE_SIGN_IN_CLIENT_ID=your_client_id
```

## 📖 Usage

### Basic Usage
1. **First Launch**: Choose to sign in with Google or continue as guest
2. **Browse Content**: Navigate through the 5 parts of Sakshaat Savita
3. **Reading**: Tap any Kiran to start reading with automatic progress tracking
4. **Search**: Use the search feature to find specific content across all parts
5. **Notes**: Add personal notes while reading for future reference

### Advanced Features
- **Reading Plans**: Create custom reading schedules with daily goals
- **Quote Generator**: Create beautiful images from your favorite passages
- **Data Migration**: Use migration tools if upgrading from older versions
- **Backup**: Enable cloud sync to protect your reading data

## 🤝 Contributing

We welcome contributions to improve Sakshaat Savita! Please follow these guidelines:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Flutter best practices and conventions
- Write meaningful commit messages
- Add comments for complex logic
- Test on both Android and iOS platforms
- Ensure accessibility compliance

## 📄 License

This project is private and proprietary. All rights reserved.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Firebase for robust backend services
- The spiritual community for inspiration and feedback
- Contributors and testers who helped improve the app

## 📞 Support

For support, feature requests, or bug reports:
- Create an issue in this repository
- Contact: [Your Contact Information]

## 🔄 Version History

### Version 2.0.0 (Current)
- Complete UI redesign with Material 3
- Enhanced search with multi-word support
- Comprehensive migration tools
- Advanced note editor with rich text
- Improved performance and accessibility
- Better Firebase integration

### Version 1.x
- Initial release with basic reading features
- Simple note-taking functionality
- Basic Firebase integration

---

**Built with ❤️ using Flutter**

*Bringing spiritual wisdom to the digital age*
