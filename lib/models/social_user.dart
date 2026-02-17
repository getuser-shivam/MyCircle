  enum Gender {
  male,
  female,
  other;

  String get displayName {
    switch (this) {
      case Gender.male:
        return 'Male';
      case Gender.female:
        return 'Female';
      case Gender.other:
        return 'Other';
    }
  }
}

enum UserStatus {
  online,
  live,
  away,
  offline;

  String get displayName {
    switch (this) {
      case UserStatus.online:
        return 'Online';
      case UserStatus.live:
        return 'Live';
      case UserStatus.away:
        return 'Away';
      case UserStatus.offline:
        return 'Offline';
    }
  }
}

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

  const SocialUser({
    required this.id,
    required this.username,
    required this.avatar,
    required this.age,
    required this.gender,
    required this.locationSnippet,
    required this.distanceKm,
    required this.status,
    required this.isVerified,
    required this.interests,
    this.bio,
  });

  factory SocialUser.fromMap(Map<String, dynamic> data) {
    return SocialUser(
      id: data['id']?.toString() ?? '',
      username: data['username'] ?? '',
      avatar: data['avatar'] ?? 'https://i.pravatar.cc/300',
      age: data['age'] ?? 20,
      gender: _parseGender(data['gender']),
      locationSnippet: data['location_snippet'] ?? 'Nearby',
      distanceKm: (data['distance_km'] as num?)?.toDouble() ?? 5.0,
      status: _parseStatus(data['status']),
      isVerified: data['is_verified'] ?? false,
      interests: List<String>.from(data['interests'] ?? []),
      bio: data['bio'],
    );
  }

  factory SocialUser.fromJson(Map<String, dynamic> data) => SocialUser.fromMap(data);

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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'avatar': avatar,
      'age': age,
      'gender': gender.name,
      'location_snippet': locationSnippet,
      'distance_km': distanceKm,
      'status': status.name,
      'is_verified': isVerified,
      'interests': interests,
      'bio': bio,
    };
  }

  Map<String, dynamic> toJson() => toMap();

  SocialUser copyWith({
    String? id,
    String? username,
    String? avatar,
    int? age,
    Gender? gender,
    String? locationSnippet,
    double? distanceKm,
    UserStatus? status,
    bool? isVerified,
    List<String>? interests,
    String? bio,
  }) {
    return SocialUser(
      id: id ?? this.id,
      username: username ?? this.username,
      avatar: avatar ?? this.avatar,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      locationSnippet: locationSnippet ?? this.locationSnippet,
      distanceKm: distanceKm ?? this.distanceKm,
      status: status ?? this.status,
      isVerified: isVerified ?? this.isVerified,
      interests: interests ?? this.interests,
      bio: bio ?? this.bio,
    );
  }

  // Add getters for compatibility with SocialProvider
  double? get distance => distanceKm;
  int get distanceInKm => distanceKm.round();

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SocialUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'SocialUser(id: $id, username: $username, age: $age, status: $status)';
  }
}
