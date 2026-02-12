const express = require('express');
const cors = require('cors');
const { createServer } = require('http');
const { Server } = require('socket.io');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const NodeCache = require('node-cache');

const app = express();
const server = createServer(app);
const io = new Server(server, {
  cors: {
    origin: ["http://localhost:3000", "http://localhost:8080", "http://127.0.0.1:3000"],
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    credentials: true
  },
  transports: ['websocket', 'polling']
});

// Cache for performance
const cache = new NodeCache({ stdTTL: 300, checkperiod: 600 }); // 5min TTL, 10min check

// Security and performance middleware
app.use(helmet({
  contentSecurityPolicy: false,
  crossOriginEmbedderPolicy: false
}));
app.use(compression());
app.use(morgan('combined'));
app.use(cors({
  origin: ["http://localhost:3000", "http://localhost:8080", "http://127.0.0.1:3000"],
  credentials: true
}));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 1000, // limit each IP to 1000 requests per windowMs
  message: 'Too many requests from this IP, please try again later',
  standardHeaders: true,
  legacyHeaders: false
});
app.use('/api/', limiter);

// Enhanced mock data with more realistic content
const generateMockMedia = (count = 50) => {
  const categories = ['trending', 'popular', 'new', 'hot', 'viral', 'top'];
  const tags = ['funny', 'cute', 'gaming', 'music', 'sports', 'news', 'tech', 'food', 'travel', 'fashion'];
  const types = ['image', 'video'];
  
  return Array.from({ length: count }, (_, i) => ({
    _id: `media_${i + 1}`,
    title: `Amazing Content ${i + 1}`,
    description: `This is an amazing piece of content that showcases creativity and talent. Content #${i + 1}`,
    fileUrl: `https://picsum.photos/400/600?random=${i + 1}`,
    thumbnailUrl: `https://picsum.photos/200/300?random=${i + 1}`,
    userName: `user_${i + 1}`,
    userAvatar: `https://picsum.photos/50/50?random=user${i + 1}`,
    views: Math.floor(Math.random() * 10000) + 100,
    likes: Math.floor(Math.random() * 1000) + 10,
    comments: Math.floor(Math.random() * 100) + 1,
    duration: Math.floor(Math.random() * 60) + 10,
    tags: [tags[Math.floor(Math.random() * tags.length)], tags[Math.floor(Math.random() * tags.length)]],
    isVerified: Math.random() > 0.7,
    isPremium: Math.random() > 0.8,
    createdAt: new Date(Date.now() - Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString(),
    type: types[Math.floor(Math.random() * types.length)],
    category: categories[Math.floor(Math.random() * categories.length)],
    quality: 'HD',
    resolution: '1920x1080',
    fileSize: Math.floor(Math.random() * 50) + 10, // MB
    downloadUrl: `https://example.com/download/media_${i + 1}`,
    shareUrl: `https://mycircle.app/media/${i + 1}`,
    embedUrl: `https://mycircle.app/embed/media_${i + 1}`,
    stats: {
      shares: Math.floor(Math.random() * 100) + 1,
      downloads: Math.floor(Math.random() * 50) + 1,
      favorites: Math.floor(Math.random() * 200) + 1,
    }
  }));
};

let media = generateMockMedia(100);
let users = Array.from({ length: 20 }, (_, i) => ({
  _id: `user_${i + 1}`,
  username: `user_${i + 1}`,
  email: `user${i + 1}@example.com`,
  avatar: `https://picsum.photos/100/100?random=user${i + 1}`,
  bio: `Bio for user ${i + 1}`,
  isVerified: Math.random() > 0.7,
  isPremium: Math.random() > 0.8,
  followersCount: Math.floor(Math.random() * 1000) + 10,
  followingCount: Math.floor(Math.random() * 500) + 5,
  postsCount: Math.floor(Math.random() * 100) + 1,
  stats: {
    totalViews: Math.floor(Math.random() * 100000) + 1000,
    totalLikes: Math.floor(Math.random() * 10000) + 100,
    totalComments: Math.floor(Math.random() * 1000) + 10,
  },
  preferences: {
    theme: 'dark',
    language: 'en',
    notifications: true,
    autoplay: true,
  }
}));

// Enhanced API routes with caching
app.get('/api/media', (req, res) => {
  const cacheKey = `media_${JSON.stringify(req.query)}`;
  const cached = cache.get(cacheKey);
  
  if (cached) {
    return res.json(cached);
  }

  const { page = 1, limit = 20, category, sortBy = 'trending', tags } = req.query;
  let filteredMedia = [...media];

  // Apply filters
  if (category && category !== 'all') {
    filteredMedia = filteredMedia.filter(item => item.category === category);
  }

  if (tags) {
    const tagArray = Array.isArray(tags) ? tags : [tags];
    filteredMedia = filteredMedia.filter(item => 
      tagArray.some(tag => item.tags.includes(tag))
    );
  }

  // Apply sorting
  switch (sortBy) {
    case 'trending':
      filteredMedia.sort((a, b) => (b.views + b.likes) - (a.views + a.likes));
      break;
    case 'popular':
      filteredMedia.sort((a, b) => b.likes - a.likes);
      break;
    case 'newest':
      filteredMedia.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
      break;
    case 'most_viewed':
      filteredMedia.sort((a, b) => b.views - a.views);
      break;
  }

  // Pagination
  const startIndex = (page - 1) * limit;
  const endIndex = startIndex + parseInt(limit);
  const paginatedMedia = filteredMedia.slice(startIndex, endIndex);

  const response = {
    media: paginatedMedia,
    pagination: {
      currentPage: parseInt(page),
      totalPages: Math.ceil(filteredMedia.length / limit),
      totalItems: filteredMedia.length,
      itemsPerPage: parseInt(limit),
    },
    filters: {
      category,
      sortBy,
      tags: tags ? (Array.isArray(tags) ? tags : [tags]) : [],
    }
  };

  cache.set(cacheKey, response);
  res.json(response);
});

app.get('/api/media/:id', (req, res) => {
  const cacheKey = `media_${req.params.id}`;
  const cached = cache.get(cacheKey);
  
  if (cached) {
    return res.json(cached);
  }

  const mediaItem = media.find(item => item._id === req.params.id);
  
  if (!mediaItem) {
    return res.status(404).json({ error: 'Media not found' });
  }

  // Increment views
  mediaItem.views += 1;
  
  cache.set(cacheKey, mediaItem);
  res.json(mediaItem);
});

app.post('/api/media/:id/like', (req, res) => {
  const mediaItem = media.find(item => item._id === req.params.id);
  
  if (!mediaItem) {
    return res.status(404).json({ error: 'Media not found' });
  }

  mediaItem.likes += 1;
  
  // Clear related caches
  cache.del('media_*');
  
  res.json({ 
    message: 'Media liked successfully',
    likes: mediaItem.likes 
  });
});

// Enhanced search endpoint
app.get('/api/search', (req, res) => {
  const { q, category, tags, sortBy = 'relevance' } = req.query;
  
  if (!q && !category && !tags) {
    return res.status(400).json({ error: 'Search query or filters required' });
  }

  let results = [...media];

  // Text search
  if (q) {
    const query = q.toLowerCase();
    results = results.filter(item => 
      item.title.toLowerCase().includes(query) ||
      item.description.toLowerCase().includes(query) ||
      item.userName.toLowerCase().includes(query) ||
      item.tags.some(tag => tag.toLowerCase().includes(query))
    );
  }

  // Apply filters
  if (category && category !== 'all') {
    results = results.filter(item => item.category === category);
  }

  if (tags) {
    const tagArray = Array.isArray(tags) ? tags : [tags];
    results = results.filter(item => 
      tagArray.some(tag => item.tags.includes(tag))
    );
  }

  // Sort by relevance (simple implementation)
  if (sortBy === 'relevance' && q) {
    const query = q.toLowerCase();
    results.sort((a, b) => {
      const aScore = (a.title.toLowerCase().includes(query) ? 3 : 0) +
                     (a.description.toLowerCase().includes(query) ? 2 : 0) +
                     (a.userName.toLowerCase().includes(query) ? 1 : 0);
      const bScore = (b.title.toLowerCase().includes(query) ? 3 : 0) +
                     (b.description.toLowerCase().includes(query) ? 2 : 0) +
                     (b.userName.toLowerCase().includes(query) ? 1 : 0);
      return bScore - aScore;
    });
  }

  res.json({
    query: q,
    results: results.slice(0, 50), // Limit search results
    total: results.length,
    filters: { category, tags, sortBy }
  });
});

// User endpoints
app.get('/api/users/:id', (req, res) => {
  const user = users.find(u => u._id === req.params.id);
  
  if (!user) {
    return res.status(404).json({ error: 'User not found' });
  }

  const userMedia = media.filter(item => item.userName === user.username);
  
  res.json({
    ...user,
    media: userMedia.slice(0, 20), // Recent media
    totalMedia: userMedia.length
  });
});

// Socket.IO for real-time features
io.on('connection', (socket) => {
  console.log('User connected:', socket.id);

  socket.on('join_room', (roomId) => {
    socket.join(roomId);
    console.log(`User ${socket.id} joined room ${roomId}`);
  });

  socket.on('like_media', (data) => {
    const { mediaId, userId } = data;
    const mediaItem = media.find(item => item._id === mediaId);
    
    if (mediaItem) {
      mediaItem.likes += 1;
      
      // Broadcast to all users in the media room
      io.to(`media_${mediaId}`).emit('media_liked', {
        mediaId,
        likes: mediaItem.likes,
        userId
      });
    }
  });

  socket.on('comment_added', (data) => {
    const { mediaId, comment } = data;
    
    // Broadcast to all users in the media room
    io.to(`media_${mediaId}`).emit('new_comment', {
      mediaId,
      comment
    });
  });

  socket.on('disconnect', () => {
    console.log('User disconnected:', socket.id);
  });
});

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    cache: cache.getStats()
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

const PORT = process.env.PORT || 5000;

server.listen(PORT, () => {
  console.log(`🚀 Enhanced server running on port ${PORT}`);
  console.log(`📊 Media items: ${media.length}`);
  console.log(`👥 Users: ${users.length}`);
  console.log(`💾 Cache enabled: ${cache.getStats().keys} items cached`);
});
