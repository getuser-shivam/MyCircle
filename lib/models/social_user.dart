import 'package:flutter/foundation.dart';

enum UserStatus { online, offline, live, away }
enum Gender { male, female, other }

class SocialUser {
  final String id;
  final String username;
  final String avatar;
  final int age;
  final Gender gender;
  final String locationSnippet;
  final double distanceKm;
  final UserStatus status;
  final bool isVerified;
  final List<String> interests;
  final String? bio;

  SocialUser({
    required this.id,
    required this.username,
    required this.avatar,
    required this.age,
    required this.gender,
    required this.locationSnippet,
    required this.distanceKm,
    this.status = UserStatus.offline,
    this.isVerified = false,
    this.interests = const [],
    this.bio,
  });

  factory SocialUser.fromJson(Map<String, dynamic> json) {
    return SocialUser(
      id: json['id'] ?? json['_id'] ?? '',
      username: json['username'] ?? '',
      avatar: json['avatar'] ?? '',
      age: json['age'] ?? 20,
      gender: _parseGender(json['gender']),
      locationSnippet: json['locationSnippet'] ?? 'Nearby',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 5.0,
      status: _parseStatus(json['status']),
      isVerified: json['isVerified'] ?? false,
      interests: List<String>.from(json['interests'] ?? []),
      bio: json['bio'],
    );
  }

  static Gender _parseGender(dynamic gender) {
    if (gender == 'male') return Gender.male;
    if (gender == 'female') return Gender.female;
    return Gender.other;
  }

  static UserStatus _parseStatus(dynamic status) {
    if (status == 'online') return UserStatus.online;
    if (status == 'live') return UserStatus.live;
    if (status == 'away') return UserStatus.away;
    return UserStatus.offline;
  }
}
