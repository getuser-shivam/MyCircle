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
