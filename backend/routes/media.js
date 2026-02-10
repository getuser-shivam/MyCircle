const express = require('express');
const router = express.Router();

// Mock media data
const mockMedia = [
  {
    _id: '1',
    title: 'Amazing Content 1',
    fileUrl: 'https://picsum.photos/400/600?random=1',
    thumbnailUrl: 'https://picsum.photos/200/300?random=1',
    userName: 'demo_user',
    userAvatar: 'https://picsum.photos/50/50?random=user1',
    views: 1250,
    likes: 89,
    duration: 15,
    tags: ['trending', 'hot'],
    isVerified: true,
    createdAt: new Date().toISOString(),
    type: 'image',
    category: 'general',
    author: {
      username: 'demo_user',
      avatar: 'https://picsum.photos/50/50?random=user1',
      isVerified: true
    }
  },
  {
    _id: '2',
    title: 'Awesome Video 2',
    fileUrl: 'https://picsum.photos/400/600?random=2',
    thumbnailUrl: 'https://picsum.photos/200/300?random=2',
    userName: 'cool_user',
    userAvatar: 'https://picsum.photos/50/50?random=user2',
    views: 2100,
    likes: 156,
    duration: 30,
    tags: ['viral', 'popular'],
    isVerified: false,
    createdAt: new Date().toISOString(),
    type: 'video',
    category: 'trending',
    author: {
      username: 'cool_user',
      avatar: 'https://picsum.photos/50/50?random=user2',
      isVerified: false
    }
  }
];

// Get media feed
router.get('/feed', (req, res) => {
  const { page = 1, limit = 20, category = 'all' } = req.query;

  let filteredMedia = mockMedia;
  if (category !== 'all') {
    filteredMedia = mockMedia.filter(item => item.category === category);
  }

  res.json({
    success: true,
    data: {
      media: filteredMedia,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: filteredMedia.length,
        pages: Math.ceil(filteredMedia.length / limit)
      }
    }
  });
});

// Get single media
router.get('/:id', (req, res) => {
  const item = mockMedia.find(m => m._id === req.params.id);
  if (!item) {
    return res.status(404).json({ success: false, message: 'Media not found' });
  }

  res.json({ success: true, data: { media: item } });
});

// Search media
router.get('/search', (req, res) => {
  const { q = '', page = 1, limit = 20 } = req.query;

  let results = mockMedia;
  if (q.trim()) {
    results = mockMedia.filter(item =>
      item.title.toLowerCase().includes(q.toLowerCase()) ||
      item.tags.some(tag => tag.toLowerCase().includes(q.toLowerCase()))
    );
  }

  res.json({
    success: true,
    data: {
      media: results,
      pagination: {
        page: parseInt(page),
        limit: parseInt(limit),
        total: results.length,
        pages: Math.ceil(results.length / limit)
      }
    }
  });
});

// Like media
router.post('/:id/like', (req, res) => {
  res.json({
    success: true,
    data: {
      liked: true,
      likeCount: Math.floor(Math.random() * 100) + 1
    }
  });
});

// Upload media
router.post('/upload', (req, res) => {
  res.status(201).json({
    success: true,
    message: 'Media uploaded successfully',
    data: {
      media: {
        _id: Date.now().toString(),
        title: 'Uploaded Media',
        fileUrl: 'https://picsum.photos/400/600?random=upload',
        thumbnailUrl: 'https://picsum.photos/200/300?random=upload',
        type: 'image'
      }
    }
  });
});

module.exports = router;
