const express = require('express');
const router = express.Router();

// Get user profile
router.get('/:id', (req, res) => {
  // Mock user data
  const user = {
    id: req.params.id,
    username: 'demo_user',
    email: 'user@example.com',
    avatar: 'https://picsum.photos/200/200?random=user',
    bio: 'Demo user profile',
    isVerified: true,
    isPremium: false,
    followersCount: 1250,
    followingCount: 89,
    postsCount: 45,
    createdAt: new Date().toISOString()
  };

  res.json({ success: true, data: { user } });
});

// Follow user
router.post('/:id/follow', (req, res) => {
  res.json({
    success: true,
    message: 'User followed successfully',
    data: { following: true }
  });
});

// Unfollow user
router.delete('/:id/follow', (req, res) => {
  res.json({
    success: true,
    message: 'User unfollowed successfully',
    data: { following: false }
  });
});

module.exports = router;
