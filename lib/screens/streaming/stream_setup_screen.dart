import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../models/stream_model.dart';
import '../../providers/stream_provider.dart';
import '../../widgets/feedback/error_widget.dart';

class StreamSetupScreen extends StatefulWidget {
  const StreamSetupScreen({super.key});

  @override
  State<StreamSetupScreen> createState() => _StreamSetupScreenState();
}

class _StreamSetupScreenState extends State<StreamSetupScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  final _maxViewersController = TextEditingController(text: '1000');
  
  late TabController _tabController;
  
  String _selectedCategory = 'Gaming';
  StreamQuality _selectedQuality = StreamQuality.medium;
  DateTime? _scheduledAt;
  bool _isPrivate = false;
  bool _isRecorded = true;
  bool _isLoading = false;
  File? _thumbnailImage;
  List<String> _selectedTags = [];
  List<String> _allowedViewers = [];

  final List<String> _categories = [
    'Gaming',
    'Music',
    'Art',
    'Education',
    'Sports',
    'Talk Show',
    'Cooking',
    'Technology',
    'Fitness',
    'Entertainment',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    _maxViewersController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Stream'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.info), text: 'Basic Info'),
            Tab(icon: Icon(Icons.settings), text: 'Advanced'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _startStream,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Start Stream'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildBasicInfoTab(),
            _buildAdvancedTab(),
          ],
        ),
      ),
    );
  }

  Widget _buildBasicInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail Upload
          _buildThumbnailSection(),
          const SizedBox(height: 24),
          
          // Title
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Stream Title',
              hintText: 'Enter an engaging title for your stream',
              prefixIcon: Icon(Icons.title),
              border: OutlineInputBorder(),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a stream title';
              }
              if (value.trim().length < 3) {
                return 'Title must be at least 3 characters';
              }
              return null;
            },
            maxLength: 100,
          ),
          const SizedBox(height: 16),
          
          // Description
          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Tell viewers what your stream is about',
              prefixIcon: Icon(Icons.description),
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            maxLength: 500,
          ),
          const SizedBox(height: 16),
          
          // Category
          DropdownButtonFormField<String>(
            value: _selectedCategory,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.category),
              border: OutlineInputBorder(),
            ),
            items: _categories.map((category) {
              return DropdownMenuItem(
                value: category,
                child: Text(category),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _selectedCategory = value!;
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Tags
          _buildTagsSection(),
          const SizedBox(height: 16),
          
          // Schedule
          _buildScheduleSection(),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stream Quality
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Stream Quality',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: StreamQuality.values.map((quality) {
                      final isSelected = _selectedQuality == quality;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: quality != StreamQuality.ultra ? 8 : 0,
                          ),
                          child: InkWell(
                            onTap: () {
                              setState(() {
                                _selectedQuality = quality;
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primaryContainer
                                    : Theme.of(context).colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.primary
                                      : Colors.transparent,
                                ),
                              ),
                              child: Text(
                                quality.displayName,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected
                                      ? Theme.of(context).colorScheme.onPrimaryContainer
                                      : Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Max Viewers
          TextFormField(
            controller: _maxViewersController,
            decoration: const InputDecoration(
              labelText: 'Maximum Viewers',
              hintText: 'Leave empty for unlimited',
              prefixIcon: Icon(Icons.people),
              border: OutlineInputBorder(),
              suffixText: 'viewers',
            ),
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final number = int.tryParse(value);
                if (number == null || number <= 0) {
                  return 'Please enter a valid number';
                }
              }
              return null;
            },
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
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Private Stream'),
                    subtitle: const Text('Only allowed viewers can join'),
                    value: _isPrivate,
                    onChanged: (value) {
                      setState(() {
                        _isPrivate = value;
                      });
                    },
                  ),
                  if (_isPrivate) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _manageAllowedViewers,
                      icon: const Icon(Icons.people),
                      label: Text('Manage Viewers (${_allowedViewers.length})'),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Recording Settings
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recording Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Record Stream'),
                    subtitle: const Text('Save the stream for later viewing'),
                    value: _isRecorded,
                    onChanged: (value) {
                      setState(() {
                        _isRecorded = value;
                      });
                    },
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Start Stream Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isLoading ? null : _startStream,
              icon: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.broadcast_on_personal),
              label: Text(_isLoading ? 'Starting...' : 'Start Stream'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildThumbnailSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Stream Thumbnail',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (_thumbnailImage != null)
              Stack(
                children: [
                  Container(
                    width: double.infinity,
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: FileImage(_thumbnailImage!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: IconButton.filled(
                      onPressed: () {
                        setState(() {
                          _thumbnailImage = null;
                        });
                      },
                      icon: const Icon(Icons.delete),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.image,
                      size: 48,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Add a thumbnail',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImageFromGallery,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('From Gallery'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImageFromCamera,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('From Camera'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _tagsController,
          decoration: InputDecoration(
            labelText: 'Tags',
            hintText: 'Add tags to help viewers find your stream',
            prefixIcon: const Icon(Icons.tag),
            border: const OutlineInputBorder(),
            suffixIcon: IconButton(
              icon: const Icon(Icons.add),
              onPressed: _addTag,
            ),
          ),
          onSubmitted: (_) => _addTag(),
        ),
        if (_selectedTags.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: _selectedTags.map((tag) {
              return Chip(
                label: Text(tag),
                onDeleted: () {
                  setState(() {
                    _selectedTags.remove(tag);
                  });
                },
                deleteIcon: const Icon(Icons.close, size: 16),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildScheduleSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Schedule',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            RadioListTile<bool>(
              title: const Text('Start Now'),
              value: false,
              groupValue: _scheduledAt != null,
              onChanged: (value) {
                setState(() {
                  _scheduledAt = null;
                });
              },
            ),
            RadioListTile<bool>(
              title: const Text('Schedule for Later'),
              value: true,
              groupValue: _scheduledAt != null,
              onChanged: (value) {
                if (value == true) {
                  _pickScheduleTime();
                }
              },
            ),
            if (_scheduledAt != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.schedule,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Scheduled for: ${_formatDateTime(_scheduledAt!)}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: _pickScheduleTime,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _thumbnailImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _thumbnailImage = File(image.path);
        });
      }
    } catch (e) {
      _showErrorSnackBar('Failed to capture image: $e');
    }
  }

  void _addTag() {
    final tag = _tagsController.text.trim();
    if (tag.isNotEmpty && !_selectedTags.contains(tag)) {
      setState(() {
        _selectedTags.add(tag);
        _tagsController.clear();
      });
    }
  }

  Future<void> _pickScheduleTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    
    if (date != null) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(date),
      );
      
      if (time != null) {
        setState(() {
          _scheduledAt = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _manageAllowedViewers() async {
    final selectedViewers = await showDialog<Set<String>>(
      context: context,
      builder: (context) => _ViewerSelectionDialog(
        initiallySelected: _allowedViewers,
      ),
    );
    
    if (selectedViewers != null) {
      setState(() {
        _allowedViewers = selectedViewers;
      });
    }
  }

  Future<void> _startStream() async {
    if (!_formKey.currentState!.validate()) {
      _tabController.animateTo(0); // Switch to basic info tab
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final streamProvider = context.read<StreamProvider>();
      
      final streamData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'category': _selectedCategory,
        'quality': _selectedQuality,
        'tags': _selectedTags,
        'maxViewers': _maxViewersController.text.isNotEmpty
            ? int.parse(_maxViewersController.text)
            : null,
        'isPrivate': _isPrivate,
        'isRecorded': _isRecorded,
        'scheduledAt': _scheduledAt,
        'allowedViewerIds': _allowedViewers,
        'thumbnailImage': _thumbnailImage,
      };

      final stream = await streamProvider.createStream(streamData);
      
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/streaming/player',
          arguments: {'stream': stream},
        );
      }
    } catch (e) {
      _showErrorSnackBar('Failed to start stream: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _ViewerSelectionDialog extends StatefulWidget {
  final Set<String> initiallySelected;

  const _ViewerSelectionDialog({
    required this.initiallySelected,
  });

  @override
  State<_ViewerSelectionDialog> createState() => _ViewerSelectionDialogState();
}

class _ViewerSelectionDialogState extends State<_ViewerSelectionDialog> {
  late Set<String> _selectedViewers;
  final List<String> _availableViewers = [
    'user1@example.com',
    'user2@example.com', 
    'user3@example.com',
    'user4@example.com',
    'user5@example.com',
  ];

  @override
  void initState() {
    super.initState();
    _selectedViewers = Set.from(widget.initiallySelected);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Select Allowed Viewers'),
      content: SizedBox(
        width: double.maxFinite,
        height: 300,
        child: ListView.builder(
          itemCount: _availableViewers.length,
          itemBuilder: (context, index) {
            final viewer = _availableViewers[index];
            final isSelected = _selectedViewers.contains(viewer);
            
            return CheckboxListTile(
              title: Text(viewer),
              value: isSelected,
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedViewers.add(viewer);
                  } else {
                    _selectedViewers.remove(viewer);
                  }
                });
              },
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_selectedViewers),
          child: const Text('Done'),
        ),
      ],
    );
  }
}
