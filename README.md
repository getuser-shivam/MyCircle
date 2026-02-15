<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
  <img src="https://img.shields.io/badge/Firestore-Database-FF6F00?style=for-the-badge&logo=firebase&logoColor=white" />
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" />
</p>

# 🔵 MyCircle — Social Discovery & Media Platform

> A premium, enterprise-grade social discovery and media-sharing platform built with Flutter & Firebase. Inspired by **Skout**, **Tagged**, and **Tinder** — featuring real-time social discovery, Tinder-style swiping, proximity-based user grids, and a glassmorphic UI.

---

## ✨ Key Highlights

| Feature | Description |
|---------|-------------|
| 🧭 **Meet Me Grid** | High-density proximity grid showing nearby users with live status pulsars |
| 💘 **Swipe Discovery** | Tinder-style swipeable card deck with gesture-driven like/nope actions |
| 👤 **Social Profiles** | Full-screen user profiles with hero images, bios, interests, and action buttons |
| 🎬 **Media Hub** | Video/image/GIF browsing with staggered grids and infinite scroll |
| 🔔 **Real-Time Notifications** | Firestore-powered notification system with bell badges |
| 🎨 **Premium UI** | Glassmorphism, dynamic gradients, micro-animations, and DM Sans typography |
| 🌗 **Dark/Light Themes** | Persistent theme switching with Material 3 design tokens |
| 🔐 **Firebase Auth** | Email/password authentication with registration, login, and profile management |

---

## 📱 Screens & Features

### 🏠 Discovery Home
- **Ultimate Home Screen** — Curated media feed with trending, recent, and popular tabs
- Category chips for quick content filtering
- Pull-to-refresh and infinite scroll pagination
- Glassmorphic app bar with premium branding

### 🧭 Social Discovery (Meet Me)
- **Proximity Grid** — High-density user cards with online/live/away status pulsars
- **Swipe Deck** — Tinder-style gesture swiping with animated card rotations
- **Mode Toggle** — Seamlessly switch between Grid and Swipe discovery modes
- **Live Now Section** — Highlighted section for users currently streaming
- **Filter System** — Age range, gender, and distance filtering via bottom sheet

### 👤 Social Profiles
- Full-screen hero image with gradient overlay
- Real-time status badges (Online, Live, Away)
- Bio, interests, age, location, and gender info
- Interactive action buttons: Like ❤️, Message 💬, Close ✕

### 🔍 Advanced Search
- Real-time search with debouncing
- Search history and trending suggestions
- Multi-filter: category, media type, tags
- Responsive result grid

### 📤 Media Upload
- Camera and gallery integration
- Upload to Firebase Storage with progress indication
- Title, description, category, and tag metadata
- Privacy toggle (public/private)
- File validation and size limits (100MB max)

### 🔔 Notifications
- Real-time via Firestore listeners
- Notification categories: likes, comments, follows, system
- Mark as read/unread, bulk actions
- Badge count on navigation bar

### 👤 User Profile
- Avatar, stats (posts, followers, following)
- Tabbed content: Posts, Liked, Saved
- Profile editing and settings
- Dark mode toggle, logout

---

## 🏗️ Architecture

```
MyCircle/
├── lib/                          # Flutter App
│   ├── main.dart                 # App entry + Firebase init + MultiProvider
│   ├── firebase_options.dart     # Firebase configuration (auto-generated)
│   ├── models/
│   │   ├── media_item.dart       # Media data model (Firestore mapping)
│   │   └── social_user.dart      # Social user model (Firestore mapping)
│   ├── providers/
│   │   ├── auth_provider.dart    # FirebaseAuth authentication state
│   │   ├── media_provider.dart   # Firestore media feed & pagination
│   │   ├── notification_provider.dart  # Firestore real-time notifications
│   │   ├── social_provider.dart  # Firestore social discovery & nearby users
│   │   └── theme_provider.dart   # Theme persistence & management
│   ├── screens/
│   │   ├── home/
│   │   │   ├── home_screen.dart
│   │   │   └── ultimate_home_screen.dart
│   │   ├── social/
│   │   │   ├── meet_me_screen.dart        # Dual-mode discovery hub
│   │   │   └── social_profile_screen.dart # Detailed user profiles
│   │   ├── search/
│   │   │   ├── search_screen.dart
│   │   │   └── advanced_search_screen.dart
│   │   ├── media/
│   │   │   ├── upload_screen.dart          # Firebase Storage uploads
│   │   │   └── discover_screen.dart
│   │   └── user/
│   │       ├── profile_screen.dart
│   │       ├── notifications_screen.dart
│   │       └── chat_screen.dart
│   └── widgets/
│       ├── social/
│       │   ├── user_card.dart           # Proximity card with pulsars
│       │   ├── swipe_deck.dart          # Tinder-style swipe stack
│       │   └── filter_bottom_sheet.dart # Discovery filter panel
│       ├── media/
│       │   ├── media_card.dart
│       │   ├── media_player.dart
│       │   └── content_card.dart
│       ├── navigation/
│       │   ├── main_wrapper.dart        # Bottom nav + screen management
│       │   └── custom_bottom_nav.dart
│       └── common/
│           └── connectivity_banner.dart
│
├── assets/                       # Fonts, images, icons
├── web/                          # Flutter web configuration
├── android/                      # Android platform (google-services.json)
├── ios/                          # iOS platform (GoogleService-Info.plist)
└── pubspec.yaml                  # Flutter dependencies
```

---

## 🎨 Design System

| Element | Implementation |
|---------|---------------|
| **Typography** | DM Sans (Regular, Medium, Bold, Black) |
| **Color Palette** | HSL-tuned vibrant primaries with dark mode variants |
| **Components** | Glassmorphic cards, pulsating status rings, gradient overlays |
| **Animations** | Gesture-driven swipes, shimmer loading, smooth page transitions |
| **Layout** | Responsive grids, staggered masonry, slivers |

---

## 🛠️ Tech Stack

### Frontend
| Technology | Purpose |
|-----------|---------|
| **Flutter 3.10+** | Cross-platform UI framework |
| **Provider** | State management |
| **CachedNetworkImage** | Optimized image loading & caching |
| **Video Player + Chewie** | Native video playback |
| **Connectivity Plus** | Network status monitoring |
| **Shimmer** | Premium loading skeletons |

### Backend (Firebase)
| Technology | Purpose |
|-----------|---------|
| **Firebase Auth** | Email/password authentication |
| **Cloud Firestore** | Real-time document database |
| **Firebase Storage** | File uploads & media hosting |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** ≥ 3.10.0
- **Firebase Project** configured at [console.firebase.google.com](https://console.firebase.google.com)
- **Android Studio** / **Xcode** (for mobile)
- **Visual Studio 2022** (for Windows Desktop)
  - **Edition**: Community (Stable) - *Preview versions are NOT supported*
  - **Workload**: "Desktop development with C++" must be selected during installation

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/getuser-shivam/MyCircle.git
cd MyCircle

# 2. Install Flutter dependencies
flutter pub get

# 3. Configure Firebase (if not already done)
# - Place google-services.json in android/app/
# - Place GoogleService-Info.plist in ios/Runner/
# - Ensure firebase_options.dart matches your project
```

### Running

```bash
flutter run -d chrome    # Web
flutter run -d edge      # Edge
flutter run               # Connected device
```

### Firebase Collections

| Collection | Purpose |
|-----------|---------|
| `users` | User profiles, preferences, social data |
| `media` | Uploaded media metadata (title, URL, tags, stats) |
| `notifications` | In-app notifications (likes, follows, system) |

---

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'feat: Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

---

## 📄 License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.

---

<p align="center">
  Built with ❤️ by <a href="https://github.com/getuser-shivam">Shivam</a>
</p>
