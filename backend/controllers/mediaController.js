const Media = require('../models/Media');
const User = require('../models/User');
const { validationResult } = require('express-validator');
const multer = require('multer');
const sharp = require('sharp');
const { uploadToS3, deleteFromS3 } = require('../utils/s3Service');
const { processVideo } = require('../utils/videoProcessor');

// Configure multer for memory storage
const storage = multer.memoryStorage();
const upload = multer({
  storage,
  limits: {
    fileSize: 100 * 1024 * 1024, // 100MB limit
  },
  fileFilter: (req, file, cb) => {
    // Check file type
    const allowedTypes = /jpeg|jpg|png|gif|mp4|mov|avi|webm/;
    const extname = allowedTypes.test(file.originalname.toLowerCase());
    const mimetype = allowedTypes.test(file.mimetype);

    if (mimetype && extname) {
      return cb(null, true);
    } else {
      cb(new Error('Invalid file type'));
    }
  }
});

// Upload media
const uploadMedia = async (req, res) => {
  try {
    if (!req.file) {
      return res.status(400).json({
        success: false,
        message: 'No file uploaded'
      });
    }

    const { title, description, category, tags, isPrivate } = req.body;
    const userId = req.user._id;

    // Validate input
    const errors = validationResult(req);
    if (!errors.isEmpty()) {
      return res.status(400).json({
        success: false,
        message: 'Validation failed',
        errors: errors.array()
      });
    }

    // Determine media type
    const mimeType = req.file.mimetype;
    let type;
    if (mimeType.startsWith('image/')) {
      type = mimeType === 'image/gif' ? 'gif' : 'image';
    } else if (mimeType.startsWith('video/')) {
      type = 'video';
    } else {
      return res.status(400).json({
        success: false,
        message: 'Unsupported file type'
      });
    }

    // Process image/video
    let processedBuffer = req.file.buffer;
    let metadata = {};

    if (type === 'image' || type === 'gif') {
      // Process image with Sharp
      const image = sharp(req.file.buffer);
      const imageInfo = await image.metadata();

      // Generate thumbnail
      const thumbnailBuffer = await image
        .resize(300, 300, { fit: 'cover' })
        .jpeg({ quality: 80 })
        .toBuffer();

      metadata = {
        width: imageInfo.width,
        height: imageInfo.height,
        format: imageInfo.format
      };

      // Upload original and thumbnail
      const [fileUrl, thumbnailUrl] = await Promise.all([
        uploadToS3(processedBuffer, `${userId}/${Date.now()}_original.${imageInfo.format}`, mimeType),
        uploadToS3(thumbnailBuffer, `${userId}/${Date.now()}_thumb.jpg`, 'image/jpeg')
      ]);

      // Create media record
      const media = new Media({
        title,
        description,
        fileUrl,
        thumbnailUrl,
        fileSize: req.file.size,
        mimeType,
        author: userId,
        type,
        category: category || 'general',
        tags: tags ? tags.split(',').map(tag => tag.trim()) : [],
        isPrivate: isPrivate === 'true',
        metadata,
        processing: { status: 'completed' }
      });

      await media.save();

      res.status(201).json({
        success: true,
        message: 'Media uploaded successfully',
        data: { media }
      });

    } else if (type === 'video') {
      // For videos, we'll process asynchronously
      const media = new Media({
        title,
        description,
        fileUrl: '', // Will be set after processing
        thumbnailUrl: '', // Will be set after processing
        fileSize: req.file.size,
        mimeType,
        author: userId,
        type,
        category: category || 'general',
        tags: tags ? tags.split(',').map(tag => tag.trim()) : [],
        isPrivate: isPrivate === 'true',
        processing: { status: 'processing', progress: 0 }
      });

      await media.save();

      // Process video asynchronously
      processVideo(media._id, req.file.buffer, mimeType)
        .then(async (result) => {
          media.fileUrl = result.fileUrl;
          media.thumbnailUrl = result.thumbnailUrl;
          media.duration = result.duration;
          media.metadata = result.metadata;
          media.processing.status = 'completed';
          media.processing.completedAt = new Date();
          await media.save();
        })
        .catch(async (error) => {
          console.error('Video processing failed:', error);
          media.processing.status = 'failed';
          media.processing.error = error.message;
          await media.save();
        });

      res.status(201).json({
        success: true,
        message: 'Video upload started. Processing in background.',
        data: { media }
      });
    }

  } catch (error) {
    console.error('Upload media error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get media feed
const getMediaFeed = async (req, res) => {
  try {
    const page = parseInt(req.query.page) || 1;
    const limit = parseInt(req.query.limit) || 20;
    const category = req.query.category;
    const type = req.query.type;
    const sort = req.query.sort || 'latest';

    let query = {
      isApproved: true,
      moderationStatus: 'approved',
      isPrivate: false
    };

    if (category && category !== 'all') {
      query.category = category;
    }

    if (type && type !== 'all') {
      query.type = type;
    }

    let sortOptions = { createdAt: -1 }; // Latest first

    switch (sort) {
      case 'popular':
        sortOptions = { 'stats.likes': -1, createdAt: -1 };
        break;
      case 'trending':
        sortOptions = { 'stats.views': -1, createdAt: -1 };
        break;
      case 'oldest':
        sortOptions = { createdAt: 1 };
        break;
    }

    const media = await Media.find(query)
      .populate('author', 'username avatar isVerified')
      .sort(sortOptions)
      .skip((page - 1) * limit)
      .limit(limit)
      .lean();

    const total = await Media.countDocuments(query);

    res.json({
      success: true,
      data: {
        media,
        pagination: {
          page,
          limit,
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Get media feed error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Get single media
const getMedia = async (req, res) => {
  try {
    const media = await Media.findById(req.params.id)
      .populate('author', 'username avatar isVerified followerCount')
      .populate('likes.user', 'username avatar');

    if (!media) {
      return res.status(404).json({
        success: false,
        message: 'Media not found'
      });
    }

    // Check if private media and user has access
    if (media.isPrivate && (!req.user || req.user._id.toString() !== media.author._id.toString())) {
      return res.status(403).json({
        success: false,
        message: 'Access denied'
      });
    }

    // Increment view count (but not for own media)
    if (!req.user || req.user._id.toString() !== media.author._id.toString()) {
      await media.incrementViews();
    }

    res.json({
      success: true,
      data: { media }
    });
  } catch (error) {
    console.error('Get media error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Like/Unlike media
const toggleLike = async (req, res) => {
  try {
    const media = await Media.findById(req.params.id);

    if (!media) {
      return res.status(404).json({
        success: false,
        message: 'Media not found'
      });
    }

    const userId = req.user._id;
    const isLiked = media.likes.some(like => like.user.equals(userId));

    if (isLiked) {
      await media.removeLike(userId);
    } else {
      await media.addLike(userId);

      // Create notification for media author
      if (!media.author.equals(userId)) {
        // TODO: Create notification
      }
    }

    res.json({
      success: true,
      data: {
        liked: !isLiked,
        likeCount: media.likeCount
      }
    });
  } catch (error) {
    console.error('Toggle like error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Update media
const updateMedia = async (req, res) => {
  try {
    const media = await Media.findById(req.params.id);

    if (!media) {
      return res.status(404).json({
        success: false,
        message: 'Media not found'
      });
    }

    // Check ownership
    if (media.author.toString() !== req.user._id.toString()) {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to update this media'
      });
    }

    const { title, description, category, tags, isPrivate } = req.body;

    media.title = title || media.title;
    media.description = description !== undefined ? description : media.description;
    media.category = category || media.category;
    media.tags = tags ? tags.split(',').map(tag => tag.trim()) : media.tags;
    media.isPrivate = isPrivate !== undefined ? isPrivate : media.isPrivate;

    await media.save();

    res.json({
      success: true,
      message: 'Media updated successfully',
      data: { media }
    });
  } catch (error) {
    console.error('Update media error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Delete media
const deleteMedia = async (req, res) => {
  try {
    const media = await Media.findById(req.params.id);

    if (!media) {
      return res.status(404).json({
        success: false,
        message: 'Media not found'
      });
    }

    // Check ownership or admin
    if (media.author.toString() !== req.user._id.toString() && req.user.role !== 'admin') {
      return res.status(403).json({
        success: false,
        message: 'Not authorized to delete this media'
      });
    }

    // Soft delete
    media.deletedAt = new Date();
    await media.save();

    // Remove from user's posts
    await User.findByIdAndUpdate(media.author, {
      $pull: { posts: media._id }
    });

    // Delete files from S3
    try {
      await Promise.all([
        deleteFromS3(media.fileUrl),
        deleteFromS3(media.thumbnailUrl)
      ]);
    } catch (s3Error) {
      console.error('S3 delete error:', s3Error);
      // Don't fail the request if S3 delete fails
    }

    res.json({
      success: true,
      message: 'Media deleted successfully'
    });
  } catch (error) {
    console.error('Delete media error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

// Search media
const searchMedia = async (req, res) => {
  try {
    const { q, category, type, page = 1, limit = 20 } = req.query;

    if (!q) {
      return res.status(400).json({
        success: false,
        message: 'Search query is required'
      });
    }

    let query = {
      $text: { $search: q },
      isApproved: true,
      moderationStatus: 'approved',
      isPrivate: false
    };

    if (category && category !== 'all') {
      query.category = category;
    }

    if (type && type !== 'all') {
      query.type = type;
    }

    const media = await Media.find(query, { score: { $meta: 'textScore' } })
      .populate('author', 'username avatar isVerified')
      .sort({ score: { $meta: 'textScore' }, createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit)
      .lean();

    const total = await Media.countDocuments(query);

    res.json({
      success: true,
      data: {
        media,
        pagination: {
          page: parseInt(page),
          limit: parseInt(limit),
          total,
          pages: Math.ceil(total / limit)
        }
      }
    });
  } catch (error) {
    console.error('Search media error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};

module.exports = {
  upload,
  uploadMedia,
  getMediaFeed,
  getMedia,
  toggleLike,
  updateMedia,
  deleteMedia,
  searchMedia
};
