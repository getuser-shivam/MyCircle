import '../providers/notification_provider.dart';
import '../providers/superior_media_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/advanced_search_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/superior_home_screen.dart';
import '../screens/upload_screen.dart';
import '../widgets/connectivity_banner.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';



class SuperiorMainWrapper extends StatefulWidget {
  const SuperiorMainWrapper({super.key});

  @override
  State<SuperiorMainWrapper> createState() => _SuperiorMainWrapperState();
}

class _SuperiorMainWrapperState extends State<SuperiorMainWrapper>
    with TickerProviderStateMixin {
  int _currentIndex = 0;
  bool _isConnected = true;
  bool _isQuantumMode = true;
  bool _isAIAssistant = false;
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  Timer? _performanceTimer;
  
  final List<Widget> _superiorScreens = [
    const SuperiorHomeScreen(),
    const AdvancedSearchScreen(),
    const UploadScreen(),
    const ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    
    _fabAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _fabController,
      curve: Curves.elasticOut,
    ));
    
    _fabController.repeat(reverse: true);
    _startQuantumOptimization();
  }

  void _startQuantumOptimization() {
    _performanceTimer = Timer.periodic(
      const Duration(seconds: 10),
      (timer) => _optimizePerformance(),
    );
  }

  void _optimizePerformance() {
    // Quantum performance optimization
    setState(() {
      // Simulate performance boost
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    _performanceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              if (!_isConnected) const ConnectivityBanner(),
              Expanded(
                child: IndexedStack(
                  index: _currentIndex,
                  children: _superiorScreens,
                ),
              ),
            ],
          ),
          
          // Superior floating control panel
          Positioned(
            top: 100,
            right: 20,
            child: _buildSuperiorControlPanel(),
          ),
          
          // AI Assistant
          if (_isAIAssistant) ...[
            Positioned(
              bottom: 100,
              right: 20,
              child: _buildAIAssistant(),
            ),
          ],
        ],
      ),
      bottomNavigationBar: _buildSuperiorNavigationBar(),
      floatingActionButton: _buildSuperiorFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endDocked,
    );
  }

  Widget _buildSuperiorControlPanel() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Quantum Controls',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildQuantumToggle('Quantum Mode', _isQuantumMode, (value) {
            setState(() {
              _isQuantumMode = value;
              context.read<SuperiorMediaProvider>().enableQuantumMode(value);
            });
          }),
          _buildQuantumToggle('AI Assistant', _isAIAssistant, (value) {
            setState(() => _isAIAssistant = value);
          }),
        ],
      ),
    );
  }

  Widget _buildQuantumToggle(String title, bool value, Function(bool) onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: value 
              ? Theme.of(context).primaryColor 
              : Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value 
                ? Theme.of(context).primaryColor 
                : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
            width: 2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              value ? Icons.flash_on : Icons.flash_off,
              size: 16,
              color: value 
                  ? Theme.of(context).colorScheme.onPrimary 
                  : Theme.of(context).colorScheme.onSurface,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: value 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAIAssistant() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).primaryColor.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                Icons.smart_toy,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                'AI Assistant',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'How can I help you create superior content today?',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Ask AI anything...',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary.withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                      border: InputBorder.none,
                    ),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  // AI voice input
                },
                icon: Icon(
                  Icons.mic,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuperiorNavigationBar() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
          ],
        ),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _superiorScreens.length,
              itemBuilder: (context, index) {
                return _buildSuperiorNavItem(index);
              },
            ),
          ),
          
          // Performance indicator
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: _isQuantumMode 
                  ? Theme.of(context).primaryColor 
                  : Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _isQuantumMode 
                    ? Theme.of(context).primaryColor 
                    : Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.speed,
                  size: 16,
                  color: _isQuantumMode 
                      ? Theme.of(context).colorScheme.onPrimary 
                      : Theme.of(context).colorScheme.onSurface,
                ),
                const SizedBox(width: 6),
                Text(
                  'Quantum',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isQuantumMode 
                        ? Theme.of(context).colorScheme.onPrimary 
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuperiorNavItem(int index) {
    final isSelected = _currentIndex == index;
    final icons = [
      Icons.home,
      Icons.search,
      Icons.add_circle,
      Icons.person,
    ];
    
    final labels = [
      'Superior',
      'Neural Search',
      'Create Magic',
      'Profile',
    ];
    
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).primaryColor 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).primaryColor 
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icons[index],
              size: 24,
              color: isSelected 
                  ? Theme.of(context).colorScheme.onPrimary 
                  : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
            ),
            const SizedBox(height: 4),
            Text(
              labels[index],
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                color: isSelected 
                    ? Theme.of(context).colorScheme.onPrimary 
                    : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuperiorFAB() {
    return AnimatedBuilder(
      animation: _fabAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _fabAnimation.value,
          child: FloatingActionButton.extended(
            onPressed: () {
              // Superior action - quantum content creation
              _showQuantumCreationDialog();
            },
            backgroundColor: Theme.of(context).primaryColor,
            icon: const Icon(Icons.auto_awesome),
            label: Text(
              'Quantum Create',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      },
    );
  }

  void _showQuantumCreationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Icon(
              Icons.auto_awesome,
              color: Theme.of(context).primaryColor,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Quantum Creation Studio',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Choose your superior creation method:',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            _buildCreationOption('AI Video Generator', Icons.video_file, () {}),
            _buildCreationOption('Neural Content', Icons.psychology, () {}),
            _buildCreationOption('Quantum Editor', Icons.flash_on, () {}),
            _buildCreationOption('AR Studio', Icons.view_in_ar, () {}),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreationOption(String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap();
      },
    );
  }
}
