import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});

  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _tagsController = TextEditingController();
  
  File? _selectedFile;
  bool _isUploading = false;
  bool _isPrivate = false;
  String _selectedCategory = 'General';
  double _uploadProgress = 0.0;

  final List<String> _categories = [
    'General',
    'Trending',
    'Popular',
    'New',
    'Hot',
    'Top Rated',
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Content'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUploadArea(),
            if (_isUploading) ...[
              const SizedBox(height: 24),
              LinearProgressIndicator(value: _uploadProgress),
              const SizedBox(height: 8),
              Text('${(_uploadProgress * 100).toStringAsFixed(1)}% Uploaded'),
            ],
            const SizedBox(height: 24),
            _buildTitleField(),
            const SizedBox(height: 16),
            _buildDescriptionField(),
            const SizedBox(height: 16),
            _buildTagsField(),
            const SizedBox(height: 16),
            _buildCategoryDropdown(),
            const SizedBox(height: 16),
            _buildPrivacyToggle(),
            const SizedBox(height: 24),
            _buildUploadButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadArea() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          style: BorderStyle.solid,
        ),
      ),
      child: _selectedFile == null
          ? _buildEmptyUploadArea()
          : _buildSelectedFileArea(),
    );
  }

  Widget _buildEmptyUploadArea() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.cloud_upload_outlined,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 16),
        Text(
          'Upload your content',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'GIF, MP4, JPG, PNG up to 100MB',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            ElevatedButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library),
              label: const Text('Gallery'),
            ),
            ElevatedButton.icon(
              onPressed: _pickFromCamera,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Camera'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSelectedFileArea() {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _getFileIcon(_selectedFile!.path),
                size: 48,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  path.basename(_selectedFile!.path),
                  style: Theme.of(context).textTheme.bodySmall,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: GestureDetector(
            onTap: _removeFile,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 16,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTitleField() {
    return TextField(
      controller: _titleController,
      decoration: InputDecoration(
        labelText: 'Title',
        hintText: 'Enter a catchy title',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLength: 100,
    );
  }

  Widget _buildDescriptionField() {
    return TextField(
      controller: _descriptionController,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Describe your content',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      maxLines: 3,
      maxLength: 500,
    );
  }

  Widget _buildTagsField() {
    return TextField(
      controller: _tagsController,
      decoration: InputDecoration(
        labelText: 'Tags',
        hintText: 'Enter tags separated by commas',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: const Icon(Icons.tag),
      ),
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCategory,
      decoration: InputDecoration(
        labelText: 'Category',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
    );
  }

  Widget _buildPrivacyToggle() {
    return SwitchListTile(
      title: const Text('Private'),
      subtitle: const Text('Only you can see this content'),
      value: _isPrivate,
      onChanged: (value) {
        setState(() {
          _isPrivate = value;
        });
      },
      activeColor: Theme.of(context).colorScheme.primary,
    );
  }

  Widget _buildUploadButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: (_selectedFile == null || _isUploading) ? null : _uploadContent,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isUploading
            ? const Text('Uploading...')
            : const Text(
                'Upload Content',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  IconData _getFileIcon(String filePath) {
    final extension = path.extension(filePath).toLowerCase().replaceAll('.', '');
    switch (extension) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.videocam;
      default:
        return Icons.insert_drive_file;
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? file = await _imagePicker.pickMedia();
      if (file != null) {
        setState(() {
          _selectedFile = File(file.path);
        });
      }
    } catch (e) {
      _showErrorDialog('Error picking file: $e');
    }
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.camera,
      );
      if (file != null) {
        setState(() {
          _selectedFile = File(file.path);
        });
      }
    } catch (e) {
      _showErrorDialog('Error capturing photo: $e');
    }
  }

  void _removeFile() {
    setState(() {
      _selectedFile = null;
    });
  }

  Future<void> _uploadContent() async {
    if (_titleController.text.trim().isEmpty) {
      _showErrorDialog('Please enter a title');
      return;
    }

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      _showErrorDialog('You must be logged in to upload content');
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // 1. Upload to Supabase Storage
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${path.basename(_selectedFile!.path)}';
      final storage = Supabase.instance.client.storage;
      
      // Note: Supabase SDK doesn't have a built-in progress listener in the same way as Firebase,
      // but we can simulate it or just show an indeterminate progress.
      // For a real app, you'd use a custom stream if needed.
      await storage.from('media').upload(
        fileName,
        _selectedFile!,
        fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
      );

      final downloadUrl = storage.from('media').getPublicUrl(fileName);

      // 2. Determine file type
      final extension = path.extension(_selectedFile!.path).toLowerCase();
      String mediaType = 'image';
      if (['.mp4', '.mov', '.avi'].contains(extension)) {
        mediaType = 'video';
      } else if (extension == '.gif') {
        mediaType = 'gif';
      }

      // 3. Save metadata to Postgres
      final tags = _tagsController.text.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      
      await Supabase.instance.client.from('media').insert({
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'url': downloadUrl,
        'thumbnail_url': mediaType == 'video' ? '' : downloadUrl,
        'type': mediaType,
        'category': _selectedCategory,
        'tags': tags,
        'author_id': user.id,
        'user_name': user.userMetadata?['username'] ?? 'Unknown',
        'user_avatar': user.userMetadata?['avatar'] ?? 'https://i.pravatar.cc/300?u=${user.id}',
        'likes_count': 0,
        'views_count': 0,
        'is_private': _isPrivate,
        'is_premium': false,
      });

      _showSuccessDialog();
    } catch (e) {
      _showErrorDialog('Upload failed: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Upload Successful!'),
        content: const Text('Your content has been uploaded successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}

