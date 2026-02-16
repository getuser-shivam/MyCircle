import 'package:flutter/material.dart';

class AppConstants {
  // API and Configuration
  static const String apiBaseUrl = 'https://api.mycircle.com';
  static const int pageSize = 20;
  static const int maxFileSize = 100 * 1024 * 1024; // 100MB
  
  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double defaultBorderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  
  // Animation Durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Cache Durations
  static const Duration shortCache = Duration(minutes: 5);
  static const Duration mediumCache = Duration(hours: 1);
  static const Duration longCache = Duration(days: 1);
  
  // Media Categories
  static const List<String> mediaCategories = [
    'For You',
    'Trending',
    'Popular',
    'New',
    'Following',
    'Premium',
  ];
  
  // User Roles
  static const List<String> userRoles = [
    'user',
    'creator',
    'moderator',
    'admin',
  ];
  
  // Supported File Types
  static const List<String> supportedImageTypes = [
    'jpg', 'jpeg', 'png', 'gif', 'webp',
  ];
  
  static const List<String> supportedVideoTypes = [
    'mp4', 'mov', 'avi', 'mkv', 'webm',
  ];
}

class AppStrings {
  // General
  static const String appName = 'MyCircle';
  static const String loading = 'Loading...';
  static const String error = 'Error';
  static const String retry = 'Retry';
  static const String cancel = 'Cancel';
  static const String confirm = 'Confirm';
  static const String save = 'Save';
  static const String delete = 'Delete';
  static const String edit = 'Edit';
  static const String share = 'Share';
  static const String like = 'Like';
  static const String comment = 'Comment';
  static const String follow = 'Follow';
  static const String unfollow = 'Unfollow';
  
  // Navigation
  static const String home = 'Home';
  static const String search = 'Search';
  static const String upload = 'Upload';
  static const String notifications = 'Notifications';
  static const String profile = 'Profile';
  
  // Media
  static const String noMediaFound = 'No media found';
  static const String noMediaFoundDescription = 'Check back later for new content';
  static const String uploadMedia = 'Upload Media';
  static const String selectFile = 'Select File';
  static const String addCaption = 'Add Caption';
  static const String addTags = 'Add Tags';
  
  // User
  static const String noUsersFound = 'No users found';
  static const String connectWithPeople = 'Connect with people';
  static const String followers = 'Followers';
  static const String following = 'Following';
  static const String posts = 'Posts';
  
  // Premium
  static const String upgradeToPremium = 'Upgrade to Premium';
  static const String premiumFeatures = 'Premium Features';
  static const String unlimitedAccess = 'Unlimited Access';
  static const String adFreeExperience = 'Ad-Free Experience';
  static const String exclusiveContent = 'Exclusive Content';
  
  // Errors
  static const String networkError = 'Please check your internet connection';
  static const String serverError = 'Server error. Please try again later';
  static const String unauthorized = 'Please log in to continue';
  static const String forbidden = 'You don\'t have permission to access this';
  static const String notFound = 'Content not found';
}

class AppColors {
  static const Color primary = Color(0xFFFF5722); // Firebase Orange
  static const Color secondary = Color(0xFFFFA000); // Amber 700
  static const Color tertiary = Color(0xFFFFC107); // Amber 500
  static const Color surface = Colors.white;
  static const Color background = Color(0xFFFFF7F6);
  static const Color error = Color(0xFFB00020);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color info = Color(0xFF2196F3);
  
  // Dark theme colors
  static const Color darkSurface = Color(0xFF1E0F0F);
  static const Color darkBackground = Color(0xFF0F0505);
  static const Color darkError = Color(0xFFCF6679);
}

class AppTextStyles {
  static const TextStyle headline1 = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headline2 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    letterSpacing: -0.5,
  );
  
  static const TextStyle headline3 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.normal,
  );
  
  static const TextStyle button = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );
  
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
  );
}
