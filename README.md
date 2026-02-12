<p align="center">
  <img src="https://img.shields.io/badge/Flutter-3.10+-02569B?style=for-the-badge&logo=flutter&logoColor=white" />
  <img src="https://img.shields.io/badge/Node.js-18+-339933?style=for-the-badge&logo=node.js&logoColor=white" />
  <img src="https://img.shields.io/badge/MongoDB-Atlas-47A248?style=for-the-badge&logo=mongodb&logoColor=white" />
  <img src="https://img.shields.io/badge/License-MIT-blue?style=for-the-badge" />
</p>

# 🔵 MyCircle — Social Discovery & Media Platform

> A premium, enterprise-grade social discovery and media-sharing platform built with Flutter & Node.js. Inspired by **Skout**, **Tagged**, and **Tinder** — featuring real-time social discovery, Tinder-style swiping, proximity-based user grids, and a glassmorphic UI.

---

## ✨ Key Highlights

| Feature | Description |
|---------|-------------|
| 🧭 **Meet Me Grid** | High-density proximity grid showing nearby users with live status pulsars |
| 💘 **Swipe Discovery** | Tinder-style swipeable card deck with gesture-driven like/nope actions |
| 👤 **Social Profiles** | Full-screen user profiles with hero images, bios, interests, and action buttons |
| 🎬 **Media Hub** | Video/image/GIF browsing with staggered grids and infinite scroll |
| 🔔 **Real-Time Notifications** | Socket.IO powered notification system with bell badges |
| 🎨 **Premium UI** | Glassmorphism, dynamic gradients, micro-animations, and DM Sans typography |
| 🌗 **Dark/Light Themes** | Persistent theme switching with Material 3 design tokens |
| 🔐 **Full Auth System** | JWT-based authentication with registration, login, and profile management |

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
- Title, description, category, and tag metadata
- Privacy toggle (public/private)
- File validation and size limits (100MB max)
- Video processing with background queue

### 🔔 Notifications
- Real-time push via Socket.IO
- Notification categories: likes, comments, follows, system
- Mark as read/unread, bulk actions
- Badge count on navigation bar

### 👤 User Profile
- Avatar, stats (posts, followers, following)
- Tabbed content: Posts, Liked, Saved
- Profile editing and settings
- Dark mode toggle, logout

### 💬 Chat (Foundation)
- Chat screen scaffold ready for messaging integration

---

## 🏗️ Architecture

```
MyCircle/
├── lib/                          # Flutter Frontend
│   ├── main.dart                 # App entry point + MultiProvider setup
│   ├── models/
│   │   ├── media_item.dart       # Media data model
│   │   └── social_user.dart      # Social user model (status, gender, interests)
│   ├── providers/
│   │   ├── auth_provider.dart    # JWT authentication state
│   │   ├── media_provider.dart   # Media feed & upload state
│   │   ├── notification_provider.dart  # Real-time notification state
│   │   ├── social_provider.dart  # Social discovery & nearby users
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
│   │   │   ├── upload_screen.dart
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
│           ├── connectivity_banner.dart
│           └── ...
│
├── backend/                      # Node.js + Express Backend
│   ├── server.js                 # Express server with Socket.IO
│   ├── controllers/
│   │   ├── authController.js     # Login, register, JWT management
│   │   └── mediaController.js    # Upload, CRUD, search, likes
│   ├── models/
│   │   ├── User.js               # User schema (Mongoose)
│   │   ├── Media.js              # Media schema with stats
│   │   └── Notification.js       # Notification schema
│   ├── routes/
│   │   ├── auth.js               # Authentication routes
│   │   ├── media.js              # Media CRUD routes
│   │   ├── users.js              # User profile routes
│   │   ├── comments.js           # Comment system routes
│   │   ├── notifications.js      # Notification routes
│   │   └── admin.js              # Admin panel routes
│   ├── middleware/
│   │   ├── auth.js               # JWT verification
│   │   ├── upload.js             # Multer file handling
│   │   └── rateLimiter.js        # Rate limiting
│   └── utils/
│       ├── s3Service.js          # AWS S3 file storage
│       └── videoProcessor.js     # Background video processing
│
├── assets/                       # Fonts, images, icons
├── web/                          # Flutter web configuration
├── android/                      # Android platform
├── ios/                          # iOS platform
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

### Backend
| Technology | Purpose |
|-----------|---------|
| **Node.js + Express** | REST API server |
| **MongoDB + Mongoose** | Document database |
| **JWT** | Token-based authentication |
| **Socket.IO** | Real-time notifications |
| **Multer + Sharp** | File upload & image processing |
| **AWS S3** | Cloud file storage |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** ≥ 3.10.0
- **Node.js** ≥ 18.0
- **MongoDB** (Atlas or local)
- **Android Studio** / **Xcode** (for mobile)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/getuser-shivam/MyCircle.git
cd MyCircle

# 2. Install Flutter dependencies
flutter pub get

# 3. Install backend dependencies
cd backend
npm install

# 4. Configure environment
cp .env.example .env
# Edit .env with your MongoDB URI, JWT secret, AWS keys
```

### Running

```bash
# Start the backend server
cd backend
npm run dev

# In a new terminal, run the Flutter app
flutter run -d chrome    # Web
flutter run -d edge      # Edge
flutter run               # Connected device
```

### Environment Variables

```env
PORT=5000
MONGODB_URI=mongodb+srv://your-cluster.mongodb.net/mycircle
JWT_SECRET=your-jwt-secret
AWS_ACCESS_KEY_ID=your-aws-key
AWS_SECRET_ACCESS_KEY=your-aws-secret
AWS_BUCKET_NAME=your-s3-bucket
AWS_REGION=us-east-1
```

---

## 📋 API Endpoints

| Method | Endpoint | Description |
|--------|----------|-------------|
| `POST` | `/api/auth/register` | Create new account |
| `POST` | `/api/auth/login` | Authenticate user |
| `GET` | `/api/media/feed` | Get media feed (paginated) |
| `POST` | `/api/media/upload` | Upload media file |
| `GET` | `/api/media/:id` | Get single media |
| `PUT` | `/api/media/:id` | Update media |
| `DELETE` | `/api/media/:id` | Delete media |
| `POST` | `/api/media/:id/like` | Toggle like |
| `GET` | `/api/media/search` | Search media |
| `GET` | `/api/users/profile` | Get user profile |
| `GET` | `/api/notifications` | Get notifications |
| `POST` | `/api/comments` | Create comment |

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
