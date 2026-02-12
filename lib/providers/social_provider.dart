import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/social_user.dart';

class SocialProvider extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<SocialUser> _nearbyUsers = [];
  bool _isLoading = false;

  List<SocialUser> get nearbyUsers => _nearbyUsers;
  bool get isLoading => _isLoading;

  Future<void> loadNearbyUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Real-time listener for users
      // In a real app, you would use GeoFlutterFire for location-based queries
      _firestore.collection('users').limit(50).snapshots().listen((snapshot) {
        _nearbyUsers = snapshot.docs.map((doc) => SocialUser.fromFirestore(doc)).toList();
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error loading nearby users: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
}
