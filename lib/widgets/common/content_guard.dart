import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../enterprise/premium_components.dart';

class ContentGuard extends StatelessWidget {
  final Widget child;
  final List<String>? requiredRoles;
  final bool requirePremium;
  final Widget? fallback;

  const ContentGuard({
    super.key,
    required this.child,
    this.requiredRoles,
    this.requirePremium = false,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.currentUser;

    if (user == null) {
      return fallback ?? _buildLoginRequired(context);
    }

    // Role check remains for administrative security (e.g. Admin Dashboard)
    if (requiredRoles != null && !requiredRoles!.contains(user.role)) {
      return fallback ?? _buildAccessDenied(context, 'Insufficient Permissions');
    }

    // Premium check removed: Everything is free of use
    return child;
  }

  Widget _buildLoginRequired(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_person_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('Login Required', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          EnterpriseButton(
            text: 'Sign In',
            onPressed: () {
              // Navigate to login (this depends on how you want to handle it)
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAccessDenied(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.security_rounded, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('This screen is restricted to authorized personal.', textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildPremiumRequired(BuildContext context) {
    return Center(
      child: EnterpriseGlassCard(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, size: 64, color: Colors.amber),
            const SizedBox(height: 16),
            const Text('Premium Content', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900)),
            const SizedBox(height: 8),
            const Text(
              'Unlock Enterprise features with a pro subscription.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            EnterpriseButton(
              text: 'Upgrade Now',
              onPressed: () {
                // Navigate to subscription screen
              },
            ),
          ],
        ),
      ),
    );
  }
}
