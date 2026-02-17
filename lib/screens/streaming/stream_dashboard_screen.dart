import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/stream_model.dart';
import '../../models/stream_viewer_model.dart';
import '../../providers/stream_provider.dart';
import '../../widgets/feedback/error_widget.dart';

class StreamDashboardScreen extends StatefulWidget {
  final String? streamId;

  const StreamDashboardScreen({super.key, this.streamId});

  @override
  State<StreamDashboardScreen> createState() => _StreamDashboardScreenState();
}

class _StreamDashboardScreenState extends State<StreamDashboardScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final streamProvider = context.read<StreamProvider>();
      if (widget.streamId != null) {
        await streamProvider.loadStreamById(widget.streamId!);
      }
      await streamProvider.loadStreamAnalytics();
      await streamProvider.loadStreamHistory();
    } catch (e) {
      _showErrorSnackBar('Failed to load dashboard: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stream Dashboard'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
            Tab(icon: Icon(Icons.history), text: 'History'),
            Tab(icon: Icon(Icons.people), text: 'Audience'),
            Tab(icon: Icon(Icons.settings), text: 'Settings'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildAnalyticsTab(),
                _buildHistoryTab(),
                _buildAudienceTab(),
                _buildSettingsTab(),
              ],
            ),
    );
  }

  Widget _buildAnalyticsTab() {
    return Consumer<StreamProvider>(
      builder: (context, streamProvider, child) {
        final currentStream = streamProvider.currentStream;
        final stats = streamProvider.streamStats;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Stream Status
              if (currentStream != null) ...[
                _buildCurrentStreamCard(currentStream),
                const SizedBox(height: 24),
              ],

              // Key Metrics
              _buildMetricsGrid(stats),
              const SizedBox(height: 24),

              // Viewer Chart
              _buildViewerChart(stats),
              const SizedBox(height: 24),

              // Engagement Metrics
              _buildEngagementMetrics(stats),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCurrentStreamCard(LiveStream stream) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stream.isLive ? Colors.red : Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    stream.status.displayName.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  'Started: ${_formatTime(stream.startedAt)}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              stream.title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.visibility,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  '${stream.viewerCount} viewers',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.schedule,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  _formatDuration(DateTime.now().difference(stream.startedAt)),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid(StreamViewerStats? stats) {
    if (stats == null) return const SizedBox.shrink();

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _MetricCard(
          title: 'Total Viewers',
          value: stats.totalViewers.toString(),
          icon: Icons.people,
          color: Colors.blue,
        ),
        _MetricCard(
          title: 'Peak Viewers',
          value: stats.peakViewers.toString(),
          icon: Icons.trending_up,
          color: Colors.green,
        ),
        _MetricCard(
          title: 'Avg Watch Time',
          value: '${stats.averageWatchTime.toStringAsFixed(1)}m',
          icon: Icons.schedule,
          color: Colors.orange,
        ),
        _MetricCard(
          title: 'Engagement',
          value: '${stats.engagementRate.toStringAsFixed(1)}%',
          icon: Icons.favorite,
          color: Colors.red,
        ),
      ],
    );
  }

  Widget _buildViewerChart(StreamViewerStats? stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Viewer Count Over Time',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: _generateMockDataPoints(),
                      isCurved: true,
                      color: Theme.of(context).colorScheme.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEngagementMetrics(StreamViewerStats? stats) {
    if (stats == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Engagement Metrics',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _EngagementRow(
              label: 'New Viewers',
              value: stats.newViewers,
              percentage: stats.newViewerRate,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _EngagementRow(
              label: 'Returning Viewers',
              value: stats.returningViewers,
              percentage: 100 - stats.newViewerRate,
              color: Colors.blue,
            ),
            const SizedBox(height: 12),
            _EngagementRow(
              label: 'Active Viewers',
              value: stats.activeViewers,
              percentage: stats.engagementRate,
              color: Colors.orange,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    return Consumer<StreamProvider>(
      builder: (context, streamProvider, child) {
        final history = streamProvider.streamHistory;

        if (history.isEmpty) {
          return const EmptyStateWidget(
            title: 'No stream history',
            subtitle: 'Your past streams will appear here',
            icon: Icons.history,
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: history.length,
          itemBuilder: (context, index) {
            final stream = history[index];
            return _StreamHistoryCard(stream: stream);
          },
        );
      },
    );
  }

  Widget _buildAudienceTab() {
    return Consumer<StreamProvider>(
      builder: (context, streamProvider, child) {
        final viewers = streamProvider.currentViewers;
        final stats = streamProvider.streamStats;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Audience Overview
              if (stats != null) ...[
                _buildAudienceOverview(stats),
                const SizedBox(height: 24),
              ],

              // Top Countries
              if (stats != null) ...[
                _buildTopCountries(stats.viewersByCountry),
                const SizedBox(height: 24),
              ],

              // Current Viewers
              Text(
                'Current Viewers',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              if (viewers.isEmpty)
                const EmptyStateWidget(
                  title: 'No active viewers',
                  subtitle: 'Viewers will appear here when they join your stream',
                  icon: Icons.people_outline,
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: viewers.length,
                  itemBuilder: (context, index) {
                    final viewer = viewers[index];
                    return _ViewerCard(viewer: viewer);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stream Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stream Settings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.hd),
                    title: const Text('Default Quality'),
                    trailing: const Text('1080p'),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.videocam),
                    title: const Text('Camera Settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.mic),
                    title: const Text('Audio Settings'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Privacy Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Settings',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('Allow chat'),
                    subtitle: const Text('Viewers can send messages'),
                    value: true,
                    onChanged: (value) {},
                  ),
                  SwitchListTile(
                    title: const Text('Save recordings'),
                    subtitle: const Text('Automatically save stream recordings'),
                    value: true,
                    onChanged: (value) {},
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Moderation
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Moderation',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ListTile(
                    leading: const Icon(Icons.block),
                    title: const Text('Blocked Users'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                  ListTile(
                    leading: const Icon(Icons.filter_list),
                    title: const Text('Blocked Words'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudienceOverview(StreamViewerStats stats) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Audience Overview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatItem(
                    label: 'Total',
                    value: stats.totalViewers.toString(),
                    icon: Icons.people,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'Active',
                    value: stats.activeViewers.toString(),
                    icon: Icons.visibility,
                  ),
                ),
                Expanded(
                  child: _StatItem(
                    label: 'VIP',
                    value: stats.vipCount.toString(),
                    icon: Icons.star,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopCountries(Map<String, int> viewersByCountry) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Top Countries',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...viewersByCountry.entries.take(5).map((entry) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      entry.key,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      '${entry.value} viewers',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  List<FlSpot> _generateMockDataPoints() {
    final now = DateTime.now();
    return List.generate(10, (index) {
      final time = now.subtract(Duration(minutes: (9 - index) * 10));
      final viewers = 50 + (index * 30) + (index % 3 * 20);
      return FlSpot(index.toDouble(), viewers.toDouble());
    });
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else {
      return '${minutes}m';
    }
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _EngagementRow extends StatelessWidget {
  final String label;
  final int value;
  final double percentage;
  final Color color;

  const _EngagementRow({
    required this.label,
    required this.value,
    required this.percentage,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const Spacer(),
        Text(
          '$value (${percentage.toStringAsFixed(1)}%)',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StreamHistoryCard extends StatelessWidget {
  final LiveStream stream;

  const _StreamHistoryCard({required this.stream});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(stream.thumbnailUrl),
        ),
        title: Text(
          stream.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${stream.category} • ${_formatDate(stream.startedAt)}',
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${stream.viewerCount}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'viewers',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        onTap: () {
          // Navigate to stream details or recording
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _ViewerCard extends StatelessWidget {
  final StreamViewer viewer;

  const _ViewerCard({required this.viewer});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: NetworkImage(viewer.userAvatar),
        ),
        title: Row(
          children: [
            Text(viewer.userName),
            if (viewer.isStaff) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.verified,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ],
            if (viewer.isVip) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.star,
                size: 16,
                color: Colors.amber,
              ),
            ],
          ],
        ),
        subtitle: Text(
          'Watching for ${_formatWatchTime(viewer.watchTime)}',
        ),
        trailing: viewer.isOnline
            ? Icon(
                Icons.circle,
                size: 8,
                color: Colors.green,
              )
            : Icon(
                Icons.circle,
                size: 8,
                color: Colors.grey,
              ),
      ),
    );
  }

  String _formatWatchTime(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else {
      return '${duration.inMinutes}m';
    }
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
