const express = require('express');
const router = express.Router();

// Mock notifications
const mockNotifications = [
  {
    _id: '1',
    type: 'like',
    message: 'User liked your post',
    read: false,
    createdAt: new Date().toISOString(),
    sender: {
      username: 'liker_user',
      avatar: 'https://picsum.photos/50/50?random=liker'
    }
  }
];

// Get notifications
router.get('/', (req, res) => {
  res.json({
    success: true,
    data: {
      notifications: mockNotifications,
      unreadCount: mockNotifications.filter(n => !n.read).length
    }
  });
});

// Mark notification as read
router.put('/:id/read', (req, res) => {
  res.json({
    success: true,
    message: 'Notification marked as read'
  });
});

// Mark all notifications as read
router.put('/read-all', (req, res) => {
  res.json({
    success: true,
    message: 'All notifications marked as read'
  });
});

module.exports = router;
