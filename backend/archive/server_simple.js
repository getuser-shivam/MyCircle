const express = require('express');
const cors = require('cors');
const { createServer } = require('http');
const { Server } = require('socket.io');

const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: "http://localhost:3000",
    methods: ["GET", "POST"]
  }
});

// Middleware
app.use(cors());
app.use(express.json());

// Mock data
let users = [];
let media = [
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
    category: 'general'
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
    category: 'trending'
  }
];

// Routes
app.get('/api/health', (req, res) => {
  res.json({ status: 'OK', message: 'RedGifs Clone API is running' });
});

// Auth routes (mock)
app.post('/api/auth/login', (req, res) => {
  const { email, password } = req.body;

  // Mock successful login
  const user = {
    id: '1',
    username: 'demo_user',
    email: email,
    avatar: 'https://picsum.photos/200/200?random=user',
    isVerified: true,
    isPremium: false,
    followerCount: 1250,
    followingCount: 89,
    postCount: 45
  };

  res.json({
    success: true,
    data: {
      user,
      token: 'mock-jwt-token',
      refreshToken: 'mock-refresh-token'
    }
  });
});

app.post('/api/auth/register', (req, res) => {
  const { username, email, password } = req.body;

  const user = {
    id: Date.now().toString(),
    username,
    email,
    avatar: `https://picsum.photos/200/200?random=${username}`,
    isVerified: false,
    isPremium: false,
    followerCount: 0,
    followingCount: 0,
    postCount: 0
  };

  res.status(201).json({
    success: true,
    data: {
      user,
      token: 'mock-jwt-token',
      refreshToken: 'mock-refresh-token'
    }
  });
});

// Media routes
app.get('/api/media/feed', (req, res) => {
  const { page = 1, limit = 20, category = 'all' } = req.query;

  let filteredMedia = media;
  if (category !== 'all') {
    filteredMedia = media.filter(item => item.category === category);
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

app.get('/api/media/:id', (req, res) => {
  const item = media.find(m => m._id === req.params.id);
  if (!item) {
    return res.status(404).json({ success: false, message: 'Media not found' });
  }

  res.json({ success: true, data: { media: item } });
});

// Search
app.get('/api/media/search', (req, res) => {
  const { q = '', page = 1, limit = 20 } = req.query;

  let results = media;
  if (q.trim()) {
    results = media.filter(item =>
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

// Socket.IO
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// Start server
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log(`🚀 RedGifs Clone API running on port ${PORT}`);
  console.log(`📱 Ready to serve Flutter app`);
});

module.exports = { app, server, io };
