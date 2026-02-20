import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SubscriptionTier {
  final String id;
  final String name;
  final double price;
  final List<String> features;
  final String description;

  SubscriptionTier({
    required this.id,
    required this.name,
    required this.price,
    required this.features,
    required this.description,
  });
}

class SubscriptionProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;
  bool _isLoading = false;
  
  bool get isLoading => _isLoading;

  final List<SubscriptionTier> tiers = [
    SubscriptionTier(
      id: 'free',
      name: 'Basic',
      price: 0.0,
      description: 'Standard access to public content',
      features: ['Watch standard resolution', 'Public commenting', 'Basic profile'],
    ),
    SubscriptionTier(
      id: 'creator',
      name: 'Creator Pro',
      price: 9.99,
      description: 'For professional content creators',
      features: ['4K Uploads', 'Analytics Dashboard', 'Verified badge', 'Priority support'],
    ),
    SubscriptionTier(
      id: 'enterprise',
      name: 'Enterprise',
      price: 29.99,
      description: 'Full control for organizations',
      features: ['Unlimited Storage', 'Team Management', 'Custom API access', 'Dedicated manager'],
    ),
  ];

  Future<void> subscribe(String tierId) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('Not authenticated');

      // Update user is_premium status in DB
      await _supabase.from('users').update({
        'is_premium': tierId != 'free',
        'metadata': {'tier': tierId},
      }).eq('id', user.id);

      // In a real app, integrate Stripe/RevenueCat here
      LoggerService.debug('Subscribed to $tierId successfully', tag: 'SUBSCRIPTION');
    } catch (e) {
      LoggerService.error('Subscription error: $e', tag: 'SUBSCRIPTION');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
