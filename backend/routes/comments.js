const express = require('express');
const router = express.Router();

// Mock comments data
const mockComments = [
  {
    _id: '1',
    content: 'Amazing content!',
    author: {
      username: 'user1',
      avatar: 'https://picsum.photos/50/50?random=user1'
    },
    createdAt: new Date().toISOString(),
    likes: 12
  }
];

// Get comments for media
router.get('/media/:mediaId', (req, res) => {
  res.json({
    success: true,
    data: {
      comments: mockComments,
      total: mockComments.length
    }
  });
});

// Add comment
router.post('/media/:mediaId', (req, res) => {
  const { content } = req.body;
  const newComment = {
    _id: Date.now().toString(),
    content,
    author: {
      username: 'current_user',
      avatar: 'https://picsum.photos/50/50?random=current'
    },
    createdAt: new Date().toISOString(),
    likes: 0
  };

  res.status(201).json({
    success: true,
    data: { comment: newComment }
  });
});

// Like comment
router.post('/:id/like', (req, res) => {
  res.json({
    success: true,
    data: { liked: true }
  });
});

module.exports = router;
