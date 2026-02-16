import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/subscription_provider.dart';
import '../../widgets/enterprise/premium_components.dart';

class SubscriptionTierScreen extends StatelessWidget {
  const SubscriptionTierScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subProvider = Provider.of<SubscriptionProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Premium Tiers'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Column(
          children: [
            const Text(
              'Choose Your Plan',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, letterSpacing: -1),
            ),
            const SizedBox(height: 8),
            Text(
              'Unlock the full power of the Enterprise Suite',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ...subProvider.tiers.map((tier) => _buildTierCard(context, tier, subProvider)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildTierCard(BuildContext context, SubscriptionTier tier, SubscriptionProvider provider) {
    final isEnterprise = tier.id == 'enterprise';
    
    return Container(
      margin: const EdgeInsets.bottom(24),
      child: EnterpriseGlassCard(
        color: isEnterprise ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.1) : null,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tier.name,
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                if (isEnterprise)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('MOST POPULAR', 
                      style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('\$${tier.price}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900)),
                const Padding(
                  padding: EdgeInsets.only(bottom: 8, left: 4),
                  child: Text('/month', style: TextStyle(color: Colors.grey)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            ...tier.features.map((f) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
                  const SizedBox(width: 12),
                  Text(f),
                ],
              ),
            )).toList(),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: EnterpriseButton(
                text: 'Select ${tier.name}',
                onPressed: () => provider.subscribe(tier.id),
                isSecondary: !isEnterprise,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
