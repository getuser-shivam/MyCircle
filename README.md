# MyCircle - Modern Social Media Platform

A modern Flutter application featuring media browsing, uploading, and social interactions.

## Features

### 🎬 Media Browsing
- **Grid Layout**: Staggered grid view for optimal media display
- **Infinite Scroll**: Paginated loading for smooth browsing
- **Multiple Views**: Trending, Recent, and Popular tabs
- **Categories**: Filter content by categories
- **Search**: Advanced search with filters and suggestions

### 📱 Media Player
- **Video Playback**: Native video player with controls
- **GIF Support**: Optimized GIF display
- **Full Screen**: Immersive viewing experience
- **Social Features**: Like, comment, share, and save

### 👤 User Features
- **Authentication**: Login and registration system
- **Profile Management**: User profiles with stats
- **Upload**: Media upload with metadata
- **Privacy**: Private/public content options

### 🎨 UI/UX
- **Dark/Light Theme**: Toggle between themes
- **Responsive Design**: Optimized for all screen sizes
- **Modern UI**: Clean, intuitive interface
- **Smooth Animations**: Fluid transitions and interactions

## Screens

1. **Home Screen**: Browse trending, recent, and popular content
2. **Search Screen**: Advanced search with filters and suggestions
3. **Upload Screen**: Upload media with metadata and privacy settings
4. **Profile Screen**: User profile with posts, liked, and saved content
5. **Media Player**: Full-screen media viewer with social features

## Tech Stack

- **Flutter**: Cross-platform mobile development
- **Provider**: State management
- **HTTP**: Network requests
- **Cached Network Image**: Optimized image loading
- **Video Player**: Native video playback
- **Image Picker**: Camera and gallery access
- **Shared Preferences**: Local storage
- **Google Fonts**: Custom typography

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── providers/                # State management
│   ├── auth_provider.dart    # Authentication state
│   ├── media_provider.dart   # Media data state
│   └── theme_provider.dart  # Theme management
├── screens/                  # UI screens
│   ├── home_screen.dart      # Home feed
│   ├── search_screen.dart    # Search functionality
│   ├── upload_screen.dart    # Content upload
│   └── profile_screen.dart   # User profile
├── widgets/                  # Reusable components
│   ├── custom_bottom_nav.dart # Navigation bar
│   ├── media_card.dart       # Media preview card
│   ├── media_player.dart     # Media viewer
│   └── category_chips.dart   # Category filter
└── models/                   # Data models
    └── media_item.dart       # Media data model
```

## Getting Started

### Prerequisites

- Flutter SDK (>=3.10.0)
- Dart SDK (>=3.0.0)
- Android Studio / Xcode for mobile development

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd MyCircle
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Platform Setup

#### Android
- Set `minSdkVersion` to 21 in `android/app/build.gradle`
- Add internet permission in `android/app/src/main/AndroidManifest.xml`

#### iOS
- Set minimum deployment target to iOS 11.0
- Add camera and photo library permissions in `Info.plist`

## Key Features Implementation

### Media Grid Layout
- Uses `flutter_staggered_grid_view` for Pinterest-style layout
- Responsive grid that adapts to different screen sizes
- Lazy loading for performance optimization

### State Management
- Provider pattern for clean state management
- Separate providers for authentication, media data, and theme
- Reactive UI updates with minimal rebuilds

### Media Upload
- Image picker integration for camera/gallery access
- File validation and size limits
- Progress indicators and error handling

### Search Functionality
- Real-time search with debouncing
- Search history and trending suggestions
- Category-based filtering

### Theme System
- Material 3 design system
- Dark and light theme support
- Persistent theme preferences

## Dependencies

### Core
- `flutter`: Flutter SDK
- `provider`: State management
- `http`: Network requests

### UI Components
- `cached_network_image`: Image loading and caching
- `video_player`: Video playback
- `chewie`: Enhanced video player UI
- `flutter_staggered_grid_view`: Grid layout
- `shimmer`: Loading animations

### Utilities
- `shared_preferences`: Local storage
- `image_picker`: Camera/gallery access
- `file_picker`: File selection
- `permission_handler`: Runtime permissions
- `infinite_scroll_pagination`: Pagination
- `url_launcher`: External links
- `share_plus`: Content sharing

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is for educational purposes only. Please respect the original platform's terms of service.

## Support

For issues and questions, please create an issue in the repository.

---

**Note**: This is a demo application created for educational purposes. The UI is for media sharing but does not use any of their actual content or APIs.
