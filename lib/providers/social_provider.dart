import 'package:flutter/material.dart';
import '../models/social_user.dart';

class SocialProvider extends ChangeNotifier {
  List<SocialUser> _nearbyUsers = [];
  bool _isLoading = false;

  List<SocialUser> get nearbyUsers => _nearbyUsers;
  bool get isLoading => _isLoading;

  Future<void> loadNearbyUsers() async {
    _isLoading = true;
    notifyListeners();

    // Mocking data for now, reflecting Skout/Tagged style
    await Future.delayed(const Duration(seconds: 1));
    
    _nearbyUsers = [
      SocialUser(
        id: '1',
        username: 'Alex',
        avatar: 'https://i.pravatar.cc/150?u=1',
        age: 24,
        gender: Gender.male,
        locationSnippet: 'New York',
        distanceKm: 2.1,
        status: UserStatus.online,
        isVerified: true,
        bio: 'Avid traveler and coffee enthusiast. Let\'s explore the city together!',
      ),
      SocialUser(
        id: '2',
        username: 'Sarah',
        avatar: 'https://i.pravatar.cc/150?u=2',
        age: 22,
        gender: Gender.female,
        locationSnippet: 'Brooklyn',
        distanceKm: 4.5,
        status: UserStatus.live,
        bio: 'Artist & Dreamer. Always up for a good concert or art show.',
      ),
      SocialUser(
        id: '3',
        username: 'Mike',
        avatar: 'https://i.pravatar.cc/150?u=3',
        age: 28,
        gender: Gender.male,
        locationSnippet: 'Queens',
        distanceKm: 8.2,
        status: UserStatus.offline,
        bio: 'Software engineer by day, musician by night.',
      ),
      SocialUser(
        id: '4',
        username: 'Elena',
        avatar: 'https://i.pravatar.cc/150?u=4',
        age: 25,
        gender: Gender.female,
        locationSnippet: 'Manhattan',
        distanceKm: 1.2,
        status: UserStatus.online,
        isVerified: true,
        bio: 'Fitness freak and foodie. Looking for someone to share new experiences.',
      ),
      SocialUser(
        id: '5',
        username: 'Chris',
        avatar: 'https://i.pravatar.cc/150?u=5',
        age: 23,
        gender: Gender.male,
        locationSnippet: 'Hoboken',
        distanceKm: 5.7,
        status: UserStatus.away,
        bio: 'Just another guy trying to find the best pizza in town.',
      ),
      SocialUser(
        id: '6',
        username: 'Mia',
        avatar: 'https://i.pravatar.cc/150?u=6',
        age: 21,
        gender: Gender.female,
        locationSnippet: 'Jersey City',
        distanceKm: 6.3,
        status: UserStatus.live,
        isVerified: true,
        bio: 'Loves dogs and long walks on the beach. Classic, I know.',
      ),
    ];

    _isLoading = false;
    notifyListeners();
  }
}
