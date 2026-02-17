import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/desktop_provider.dart';
import '../../providers/theme_provider.dart';
import '../common/animations.dart';

class DesktopSettingsScreen extends StatefulWidget {
  const DesktopSettingsScreen({super.key});

  @override
  State<DesktopSettingsScreen> createState() => _DesktopSettingsScreenState();
}

class _DesktopSettingsScreenState extends State<DesktopSettingsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _animationController = AnimationController(
      duration: AnimationConstants.medium,
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Desktop Settings'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud_upload),
            onPressed: () => _syncSettings(),
            tooltip: 'Sync to Cloud',
          ),
          IconButton(
            icon: const Icon(Icons.cloud_download),
            onPressed: () => _loadSettings(),
            tooltip: 'Load from Cloud',
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _animationController,
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Window', icon: Icon(Icons.desktop_windows)),
                  Tab(text: 'System', icon: Icon(Icons.settings)),
                  Tab(text: 'Shortcuts', icon: Icon(Icons.keyboard)),
                  Tab(text: 'Files', icon: Icon(Icons.folder)),
                ],
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.tab,
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildWindowSettings(),
                  _buildSystemSettings(),
                  _buildShortcutSettings(),
                  _buildFileSettings(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWindowSettings() {
    return Consumer<DesktopProvider>(
      builder: (context, desktopProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Window Behavior'),
              const SizedBox(height: 16),
              
              _buildSettingTile(
                title: 'Always on Top',
                subtitle: 'Keep window above other applications',
                icon: Icons.vertical_align_top,
                value: desktopProvider.isAlwaysOnTop,
                onChanged: (value) => desktopProvider.toggleAlwaysOnTop(),
              ),
              
              _buildSettingTile(
                title: 'Start Maximized',
                subtitle: 'Open application in maximized mode',
                icon: Icons.fullscreen,
                value: desktopProvider.isWindowMaximized,
                onChanged: (value) => desktopProvider.toggleMaximize(),
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Window Theme'),
              const SizedBox(height: 16),
              
              _buildThemeSelector(desktopProvider),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Visual Effects'),
              const SizedBox(height: 16),
              
              _buildSettingTile(
                title: 'Acrylic Effect',
                subtitle: 'Enable Windows 11 acrylic transparency',
                icon: Icons.blur_on,
                value: desktopProvider.isAcrylicEnabled,
                onChanged: (value) => desktopProvider.toggleAcrylicEffect(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSystemSettings() {
    return Consumer<DesktopProvider>(
      builder: (context, desktopProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('System Integration'),
              const SizedBox(height: 16),
              
              _buildSettingTile(
                title: 'System Tray',
                subtitle: 'Show application in system tray',
                icon: Icons.system_update_alt,
                value: desktopProvider.isSystemTrayEnabled,
                onChanged: (value) => desktopProvider.toggleSystemTray(),
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Startup Options'),
              const SizedBox(height: 16),
              
              _buildStartupOptions(),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Notifications'),
              const SizedBox(height: 16),
              
              _buildNotificationSettings(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShortcutSettings() {
    return Consumer<DesktopProvider>(
      builder: (context, desktopProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Global Shortcuts'),
              const SizedBox(height: 16),
              
              _buildShortcutTile(
                title: 'Show/Hide Window',
                shortcut: 'Ctrl + Shift + Q',
                icon: Icons.visibility,
              ),
              
              _buildShortcutTile(
                title: 'New Media',
                shortcut: 'Ctrl + Shift + N',
                icon: Icons.add,
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('In-App Shortcuts'),
              const SizedBox(height: 16),
              
              _buildShortcutTile(
                title: 'Search',
                shortcut: 'Ctrl + F',
                icon: Icons.search,
              ),
              
              _buildShortcutTile(
                title: 'Settings',
                shortcut: 'Ctrl + ,',
                icon: Icons.settings,
              ),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Custom Shortcuts'),
              const SizedBox(height: 16),
              
              _buildCustomShortcutSection(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileSettings() {
    return Consumer<DesktopProvider>(
      builder: (context, desktopProvider, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Recent Files'),
              const SizedBox(height: 16),
              
              if (desktopProvider.recentFiles.isEmpty)
                _buildEmptyRecentFiles()
              else
                _buildRecentFilesList(desktopProvider),
              
              const SizedBox(height: 24),
              _buildSectionTitle('File Associations'),
              const SizedBox(height: 16),
              
              _buildFileAssociations(),
              
              const SizedBox(height: 24),
              _buildSectionTitle('Storage'),
              const SizedBox(height: 16),
              
              _buildStorageSettings(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.bold,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _buildSettingTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return AnimatedSlideIn.fromLeft(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: Theme.of(context).colorScheme.primary,
          ),
          title: Text(title),
          subtitle: Text(subtitle),
          trailing: Switch(
            value: value,
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildThemeSelector(DesktopProvider desktopProvider) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Window Theme',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildThemeOption('auto', 'Auto', desktopProvider.windowTheme),
              _buildThemeOption('light', 'Light', desktopProvider.windowTheme),
              _buildThemeOption('dark', 'Dark', desktopProvider.windowTheme),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeOption(String value, String label, String currentTheme) {
    final isSelected = currentTheme == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => _setWindowTheme(value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected 
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected 
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortcutTile({
    required String title,
    required String shortcut,
    required IconData icon,
  }) {
    return AnimatedSlideIn.fromLeft(
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                shortcut,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentFilesList(DesktopProvider desktopProvider) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (int i = 0; i < desktopProvider.recentFiles.length; i++)
            ListTile(
              leading: Icon(
                Icons.file_present,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: Text(
                desktopProvider.recentFiles[i].split('/').last,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(desktopProvider.recentFiles[i]),
              trailing: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () => _removeRecentFile(i),
              ),
            ),
          ButtonBar(
            children: [
              TextButton(
                onPressed: () => desktopProvider.clearRecentFiles(),
                child: const Text('Clear All'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyRecentFiles() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(
            Icons.folder_open,
            size: 48,
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'No recent files',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Recent files will appear here when you open them',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStartupOptions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSettingTile(
            title: 'Start with Windows',
            subtitle: 'Launch application when Windows starts',
            icon: Icons.power_settings_new,
            value: false, // TODO: Implement startup management
            onChanged: (value) {},
          ),
          _buildSettingTile(
            title: 'Minimize to Tray on Close',
            subtitle: 'Minimize instead of closing the application',
            icon: Icons.minimize,
            value: true, // TODO: Implement close behavior
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSettingTile(
            title: 'Desktop Notifications',
            subtitle: 'Show desktop notifications for important events',
            icon: Icons.notifications,
            value: true, // TODO: Implement notification settings
            onChanged: (value) {},
          ),
          _buildSettingTile(
            title: 'Sound Effects',
            subtitle: 'Play sound for notifications',
            icon: Icons.volume_up,
            value: true, // TODO: Implement sound settings
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }

  Widget _buildCustomShortcutSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'Custom shortcuts coming soon!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ll be able to customize keyboard shortcuts for your favorite actions.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFileAssociations() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            'File Associations',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 12),
          Text(
            'Configure which file types open with MyCircle',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          // TODO: Implement file association settings
          Text(
            'Coming soon...',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStorageSettings() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          _buildSettingTile(
            title: 'Clear Cache',
            subtitle: 'Remove temporary files and cached data',
            icon: Icons.clear_all,
            value: false,
            onChanged: (value) => _clearCache(),
          ),
          _buildSettingTile(
            title: 'Auto-cleanup',
            subtitle: 'Automatically remove old temporary files',
            icon: Icons.auto_delete,
            value: true, // TODO: Implement auto-cleanup
            onChanged: (value) {},
          ),
        ],
      ),
    );
  }

  void _setWindowTheme(String theme) async {
    final desktopProvider = Provider.of<DesktopProvider>(context, listen: false);
    await desktopProvider.setWindowTheme(theme);
  }

  void _removeRecentFile(int index) {
    final desktopProvider = Provider.of<DesktopProvider>(context, listen: false);
    // TODO: Implement remove recent file
  }

  void _clearCache() {
    // TODO: Implement cache clearing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Cache cleared successfully')),
    );
  }

  void _syncSettings() async {
    final desktopProvider = Provider.of<DesktopProvider>(context, listen: false);
    await desktopProvider.syncDesktopSettings();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings synced to cloud')),
    );
  }

  void _loadSettings() async {
    final desktopProvider = Provider.of<DesktopProvider>(context, listen: false);
    await desktopProvider.loadDesktopSettingsFromSupabase();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings loaded from cloud')),
    );
  }
}
