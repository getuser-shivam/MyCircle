import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/social_user.dart';

class SocialProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  List<SocialUser> _nearbyUsers = [];
  List<SocialUser> _filteredUsers = [];
  bool _isLoading = false;
  
  // Filter criteria
  int? _minAge;
  int? _maxAge;
  String? _selectedGender;
  int? _maxDistance;

  List<SocialUser> get nearbyUsers => _nearbyUsers;
  List<SocialUser> get filteredUsers => _filteredUsers;
  bool get isLoading => _isLoading;

  Future<void> loadNearbyUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Real-time stream for users
      _supabase.from('users').stream(primaryKey: ['id']).limit(50).listen((data) {
        _nearbyUsers = data.map((item) => SocialUser.fromMap(item)).toList();
        _applyFilters();
        _isLoading = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('Error loading nearby users: $e');
      _isLoading = false;
      notifyListeners();
    }
  }
  
  void applyFilters({
    int? minAge,
    int? maxAge,
    String? gender,
    int? maxDistance,
  }) {
    _minAge = minAge;
    _maxAge = maxAge;
    _selectedGender = gender;
    _maxDistance = maxDistance;
    _applyFilters();
  }
  
  void clearFilters() {
    _minAge = null;
    _maxAge = null;
    _selectedGender = null;
    _maxDistance = null;
    _filteredUsers = List.from(_nearbyUsers);
    notifyListeners();
  }
  
  void _applyFilters() {
    _filteredUsers = _nearbyUsers.where((user) {
      // Age filter
      if (_minAge != null && user.age < _minAge!) return false;
      if (_maxAge != null && user.age > _maxAge!) return false;
      
      // Gender filter
      if (_selectedGender != null && _selectedGender != 'All' && user.gender != _selectedGender) return false;
      
      // Distance filter (simplified - would need location data)
      if (_maxDistance != null && user.distance != null && user.distance! > _maxDistance!) return false;
      
      return true;
    }).toList();
    
    notifyListeners();
  }
}

