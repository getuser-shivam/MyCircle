<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Desktop-Windows-0078D4?style=for-the-badge&logo=windows&logoColor=white" />
  <img src="https://img.shields.io/badge/Mobile-Android/iOS-3DDC84?style=for-the-badge&logo=android&logoColor=white" />
  <img src="https://img.shields.io/badge/Web-Chrome/Edge-4285F4?style=for-the-badge&logo=google-chrome&logoColor=white" />
  <img src="https://img.shields.io/badge/Firebase-Backend-FFCA28?style=for-the-badge&logo=firebase&logoColor=black" />
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
| 🖥️ **Desktop Experience** | Native desktop features: multi-window, keyboard shortcuts, system tray, drag & drop |
| ⌨️ **Power User Controls** | Global hotkeys, fullscreen media, advanced search filters, window management |

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

## 🖥️ Desktop Features & Capabilities

MyCircle provides a native desktop experience optimized for Windows, with features that leverage desktop hardware and user expectations.

### 🪟 **Multi-Window Support**
- **Main Application Window** — Primary social discovery and media browsing
- **Media Viewer Window** — Dedicated fullscreen media player with picture-in-picture support
- **Chat Window** — Pop-out chat interface for ongoing conversations
- **Notifications Panel** — Dedicated notification center with quick actions

### ⌨️ **Keyboard Shortcuts & Power User Features**
| Shortcut | Action | Context |
|----------|--------|---------|
| `Ctrl + K` | Quick search | Global |
| `Ctrl + N` | New post/upload | Main window |
| `Ctrl + Shift + M` | Open media viewer | Media content |
| `Ctrl + Shift + C` | Open chat | User profiles |
| `F11` | Toggle fullscreen | Any window |
| `Ctrl + ,` | Open settings | Global |
| `Ctrl + Shift + N` | Notifications panel | Global |
| `Ctrl + R` | Refresh content | Any window |
| `Ctrl + W` | Close current window | Any window |
| `Ctrl + Q` | Quit application | Global |

### 🖱️ **Desktop Interactions**
- **Drag & Drop Upload** — Drag files from desktop directly into upload area
- **Context Menus** — Right-click menus for media, users, and notifications
- **System Tray** — Minimize to tray with notification badges
- **Window Snapping** — Windows snap to screen edges and corners
- **Global Hotkeys** — Quick access even when app is minimized

### � **Desktop-Optimized UI**
- **Split View Layout** — Content and chat side-by-side on large screens
- **Advanced Grid Controls** — Adjustable grid sizes, sorting options
- **Multi-Monitor Support** — Windows can span multiple displays
- **Touchpad Gestures** — Enhanced gesture support for precision touchpads
- **High-DPI Scaling** — Crisp visuals on 4K and high-resolution displays

### 📁 **File System Integration**
- **Save to Downloads** — One-click download of media content
- **Open with Default Apps** — Launch videos/images in system default applications
- **Recent Files** — Quick access to recently viewed/uploaded content
- **File Association** — Open supported media files directly in MyCircle

### 🪟 **Advanced Window Management**
- **Window State Persistence** — Remembers window position, size, and state between sessions
- **Multi-Window Workflows** — Dedicated windows for chat, media viewer, and notifications
- **Window Snapping** — Smart window snapping to screen edges and corners
- **Minimize to Tray** — Hide main window to system tray with notification badges
- **Always on Top** — Keep important windows visible above others

### 🎹 **Advanced Keyboard Navigation**
| Shortcut | Action | Category |
|----------|--------|----------|
| `Ctrl + Shift + Space` | Quick search (global) | Global |
| `Ctrl + Shift + U` | Upload media | Media |
| `Ctrl + Shift + P` | Open profile | User |
| `Ctrl + Shift + S` | Open settings | App |
| `F5` | Refresh current view | Navigation |
| `Alt + Left/Right` | Navigate back/forward | Navigation |
| `Ctrl + Tab` | Switch between tabs | Navigation |
| `Ctrl + Shift + T` | New chat tab | Social |
| `Ctrl + Shift + F` | Toggle fullscreen | Media |
| `Ctrl + Shift + I` | Developer tools | Debug |

### 🖱️ **Enhanced Desktop Interactions**
- **Global Drag & Drop** — Drag files from desktop into any upload area
- **Context Menu Integration** — Right-click menus throughout the app
- **Touchpad Gestures** — Enhanced gesture support for precision touchpads
- **Mouse Wheel Navigation** — Smooth scrolling with momentum
- **Middle-Click Actions** — Open links in new windows, close tabs, etc.

### 🎨 **Desktop Themes & Appearance**
- **System Theme Sync** — Automatically follow Windows light/dark mode
- **Accent Color Integration** — Use Windows accent colors in app theme
- **Custom Window Borders** — Remove default borders for custom UI
- **Transparency Effects** — Acrylic/mica effects on Windows 11
- **High DPI Support** — Crisp visuals on 4K+ displays

### 📱 **Multi-Monitor & Display**
- **Multi-Monitor Support** — Windows span multiple displays seamlessly
- **Display Scaling** — Proper scaling on different DPI displays
- **Secondary Display Mode** — Dedicated media viewer on second screen
- **Presentation Mode** — Clean interface for sharing screen

### 🔧 **System Integration**
- **Windows Taskbar Integration** — Progress indicators and jump lists
- **Start Menu Integration** — Proper app registration and shortcuts
- **File Associations** — Open media files directly in MyCircle
- **Protocol Handlers** — Handle mycircle:// URLs for deep linking
- **Auto-Startup** — Optional start with Windows

### 🎵 **Media & Playback Desktop Features**
- **Hardware Acceleration** — GPU-accelerated video playback
- **Picture-in-Picture** — Continue watching while browsing
- **Media Keys Support** — Control playback with keyboard media keys
- **Subtitle Support** — Load and display subtitles for videos
- **Audio Visualization** — Real-time audio spectrum display

### 🔒 **Desktop Security & Privacy**
- **Windows Hello Integration** — Biometric authentication
- **Secure Credential Storage** — Windows Credential Manager integration
- **App Lock** — Auto-lock after inactivity
- **Private Browsing Mode** — Incognito-like session without saving data

### 📊 **Performance & System Resources**
- **Background Processing** — Upload/download in background
- **Memory Management** — Efficient memory usage for large media libraries
- **Battery Optimization** — Power-saving modes when on battery
- **Network Optimization** — Smart bandwidth management

---

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
│   │   ├── theme_provider.dart   # Theme persistence & management
│   │   └── window_provider.dart  # Desktop window management (Windows)
│   ├── services/
│   │   ├── desktop_services.dart # Desktop-specific services (hotkeys, tray)
│   │   └── notification_service.dart # Native notification handling
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
│   │   │   ├── discover_screen.dart
│   │   │   └── media_viewer_screen.dart    # Fullscreen media viewer (Desktop)
│   │   └── user/
│   │       ├── profile_screen.dart
│   │       ├── notifications_screen.dart
│   │       ├── chat_screen.dart
│   │       └── settings_screen.dart        # Desktop-specific settings
│   └── widgets/
│       ├── social/
│       │   ├── user_card.dart           # Proximity card with pulsars
│       │   ├── swipe_deck.dart          # Tinder-style swipe stack
│       │   └── filter_bottom_sheet.dart # Discovery filter panel
│       ├── media/
│       │   ├── media_card.dart
│       │   ├── media_player.dart
│       │   ├── content_card.dart
│       │   └── desktop_media_controls.dart # Desktop media controls
│       ├── navigation/
│       │   ├── main_wrapper.dart        # Bottom nav + screen management
│       │   └── custom_bottom_nav.dart
│       ├── desktop/
│       │   ├── window_title_bar.dart    # Custom title bar (Windows)
│       │   ├── system_tray.dart         # System tray integration
│       │   └── context_menu.dart        # Right-click menus
│       └── common/
│           ├── connectivity_banner.dart
│           └── keyboard_shortcuts.dart   # Global hotkey handling
│
├── windows/                      # Windows Desktop Platform
│   ├── CMakeLists.txt
│   ├── flutter/
│   │   ├── CMakeLists.txt
│   │   ├── generated_plugin_registrant.cc
│   │   ├── generated_plugin_registrant.h
│   │   └── ephemeral/
│   └── runner/
│       ├── CMakeLists.txt
│       ├── Runner.rc
│       ├── flutter_window.cpp
│       ├── main.cpp
│       ├── resources/
│       ├── utils.cpp
│       ├── utils.h
│       ├── win32_window.cpp
│       └── win32_window.h
│
├── assets/                       # Fonts, images, icons
├── web/                          # Flutter web configuration
├── android/                      # Android platform (google-services.json)
├── ios/                          # iOS platform (GoogleService-Info.plist)
├── macos/                        # macOS platform (future support)
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
| **Window Manager** | Desktop window management |
| **Hotkey Manager** | Global keyboard shortcuts |
| **System Tray** | System tray integration |

### Backend (Firebase)
| Technology | Purpose |
|-----------|---------|
| **Firebase Auth** | Email/password authentication |
| **Cloud Firestore** | Real-time document database |
| **Firebase Storage** | File uploads & media hosting |

### Desktop Platform (Windows)
| Technology | Purpose |
|-----------|---------|
| **Flutter Desktop** | Native Windows application |
| **Win32 API** | Native Windows integration |
| **Windows Notifications** | System notification toasts |
| **File Picker** | Native file dialogs |
| **URL Launcher** | Open links in default browser |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** ≥ 3.10.0
- **Firebase Project** configured at [console.firebase.google.com](https://console.firebase.google.com)
- **Android Studio** / **Xcode** (for mobile development)
- **Visual Studio 2022** (for Windows Desktop)
  - **Edition**: Community (Stable) - *Preview versions are NOT supported*
  - **Workload**: "Desktop development with C++" must be selected during installation
- **Windows SDK** (latest version, included with Visual Studio 2022)

### Desktop-Specific Setup

#### Windows Desktop Development

1. **Enable Desktop Support** in Flutter:
   ```bash
   flutter config --enable-windows-desktop
   ```

2. **Install Visual Studio Dependencies**:
   - Open Visual Studio Installer
   - Modify your Visual Studio installation
   - Select "Desktop development with C++" workload
   - Ensure Windows SDK is installed

3. **Verify Desktop Setup**:
   ```bash
   flutter doctor
   flutter devices  # Should show "Windows (desktop)"
   ```

#### Desktop Dependencies

Add these to your `pubspec.yaml` for enhanced desktop features:

```yaml
dependencies:
  # Desktop-specific packages
  window_manager: ^0.3.0          # Window management
  hotkey_manager: ^0.1.7          # Global hotkeys
  system_tray: ^2.0.3             # System tray integration
  bitsdojo_window: ^0.1.5         # Custom window decorations
  win32: ^5.0.0                   # Windows API access
  url_launcher: ^6.1.0            # Open URLs in default browser
  file_picker: ^5.2.0             # Native file dialogs
```

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

#### Desktop (Windows)
```bash
# Run on Windows Desktop
flutter run -d windows

# Build release version
flutter build windows

# Create distributable .msix package
flutter build windows --release
flutter pub run msix:create
```

#### Mobile & Web
```bash
# Android
flutter run -d android

# iOS (macOS only)
flutter run -d ios

# Web
flutter run -d chrome    # Chrome
flutter run -d edge      # Microsoft Edge

# Connected device
flutter run
```

#### Development Commands
```bash
# Enable desktop for all platforms
flutter config --enable-windows-desktop
flutter config --enable-macos-desktop
flutter config --enable-linux-desktop

# Check all available devices
flutter devices

# Clean and rebuild
flutter clean && flutter pub get && flutter run -d windows
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
