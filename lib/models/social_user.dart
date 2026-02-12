import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

  factory SocialUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SocialUser(
      id: doc.id,
      username: data['username'] ?? '',
      avatar: data['avatar'] ?? 'https://i.pravatar.cc/300',
      age: data['age'] ?? 20,
      gender: _parseGender(data['gender']),
      // Mock location for now as Firestore doesn't store it yet
      locationSnippet: data['locationSnippet'] ?? 'Nearby',
      distanceKm: (data['distanceKm'] as num?)?.toDouble() ?? 5.0,
      status: _parseStatus(data['status']),
      isVerified: data['isVerified'] ?? false,
      interests: List<String>.from(data['interests'] ?? []),
      bio: data['bio'],
    );
  }

  static Gender _parseGender(dynamic gender) {
    final value = gender?.toString().toLowerCase();
    if (value == 'male') return Gender.male;
    if (value == 'female') return Gender.female;
    return Gender.other;
  }

  static UserStatus _parseStatus(dynamic status) {
    final value = status?.toString().toLowerCase();
    if (value == 'online') return UserStatus.online;
    if (value == 'live') return UserStatus.live;
    if (value == 'away') return UserStatus.away;
    return UserStatus.offline;
  }
}
