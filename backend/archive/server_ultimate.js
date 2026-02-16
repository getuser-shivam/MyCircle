const express = require('express');
const cors = require('cors');
const { createServer } = require('http');
const { Server } = require('socket.io');
const rateLimit = require('express-rate-limit');
const helmet = require('helmet');
const compression = require('compression');
const morgan = require('morgan');
const NodeCache = require('node-cache');
const cluster = require('cluster');
const os = require('os');

const app = express();
const server = createServer(app);

// Multi-process clustering for performance
if (cluster.isMaster) {
  const numCPUs = os.cpus().length;
  console.log(`🚀 Master ${process.pid} is running`);
  console.log(`📊 Forking ${numCPUs} workers...`);

  for (let i = 0; i < numCPUs; i++) {
    cluster.fork();
  }

  cluster.on('exit', (worker, code, signal) => {
    console.log(`⚠️ Worker ${worker.process.pid} died. Restarting...`);
    cluster.fork();
  });

  return;
}

// Advanced caching system
const mediaCache = new NodeCache({ 
  stdTTL: 300, // 5 minutes
  checkperiod: 120, // 2 minutes
  useClones: false
});

const userCache = new NodeCache({ 
  stdTTL: 600, // 10 minutes
  checkperiod: 300, // 5 minutes
  useClones: false
});

const searchCache = new NodeCache({ 
  stdTTL: 180, // 3 minutes
  checkperiod: 60, // 1 minute
  useClones: false
});

const io = new Server(server, {
  cors: {
    origin: ["http://localhost:3000", "http://localhost:8080", "http://127.0.0.1:3000"],
    methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
    credentials: true
  },
  transports: ['websocket', 'polling'],
  pingTimeout: 60000,
  pingInterval: 25000
});

// Enhanced security middleware
app.use(helmet({
  contentSecurityPolicy: {
    directives: {
      defaultSrc: ["'self'"],
      styleSrc: ["'self'", "'unsafe-inline'"],
      scriptSrc: ["'self'"],
      imgSrc: ["'self'", "data:", "https:"],
    },
  },
  crossOriginEmbedderPolicy: false,
  hsts: {
    maxAge: 31536000,
    includeSubDomains: true,
    preload: true
  }
}));

app.use(compression({
  level: 6,
  threshold: 1024,
  filter: (req, res) => {
    if (req.headers['x-no-compression']) {
      return false;
    }
    return compression.filter(req, res);
  }
}));

// Enhanced logging
app.use(morgan('combined', {
  skip: (req, res) => res.statusCode < 400,
  stream: {
    write: (message) => console.log(message.trim())
  }
}));

app.use(cors({
  origin: ["http://localhost:3000", "http://localhost:8080", "http://127.0.0.1:3000"],
  credentials: true,
  methods: ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With']
}));

app.use(express.json({ 
  limit: '10mb',
  strict: true
}));

app.use(express.urlencoded({ 
  extended: true, 
  limit: '10mb',
  parameterLimit: 1000
}));

// Advanced rate limiting
const createRateLimiter = (windowMs, max, message) => rateLimit({
  windowMs,
  max,
  message: { error: message },
  standardHeaders: true,
  legacyHeaders: false,
  keyGenerator: (req) => {
    return req.ip + ':' + (req.headers['user-agent'] || '');
  },
  skip: (req) => {
    return req.ip === '127.0.0.1' || req.ip === '::1';
  }
});

app.use('/api/', createRateLimiter(15 * 60 * 1000, 1000, 'Too many requests'));
app.use('/api/auth/', createRateLimiter(15 * 60 * 1000, 100, 'Too many auth attempts'));
app.use('/api/upload/', createRateLimiter(60 * 1000, 50, 'Too many uploads'));

// Enhanced mock data generation
const generateRealisticMedia = (count = 200) => {
  const categories = ['trending', 'popular', 'new', 'hot', 'viral', 'top', 'premium'];
  const tags = ['funny', 'cute', 'gaming', 'music', 'sports', 'news', 'tech', 'food', 'travel', 'fashion', 'art', 'nature', 'pets', 'dance', 'comedy', 'drama', 'educational', 'science', 'history', 'lifestyle'];
  const types = ['image', 'video', 'gif'];
  const qualities = ['HD', 'Full HD', '4K', '8K'];
  
  return Array.from({ length: count }, (_, i) => {
    const createdAt = new Date(Date.now() - Math.random() * 30 * 24 * 60 * 60 * 1000);
    const category = categories[Math.floor(Math.random() * categories.length)];
    const isPremium = category === 'premium' || Math.random() > 0.9;
    
    return {
      _id: `media_${i + 1}`,
      title: `Amazing Content ${i + 1}`,
      description: `This is an incredible piece of content that showcases the best of creativity and talent. Content #${i + 1} has been carefully crafted to entertain and inspire our community.`,
      fileUrl: `https://picsum.photos/800/1200?random=${i + 1}`,
      thumbnailUrl: `https://picsum.photos/400/600?random=${i + 1}`,
      previewUrl: `https://picsum.photos/200/300?random=${i + 1}`,
      userName: `user_${Math.floor(Math.random() * 1000) + 1}`,
      userAvatar: `https://picsum.photos/100/100?random=user${i + 1}`,
      userId: `user_${Math.floor(Math.random() * 1000) + 1}`,
      views: Math.floor(Math.random() * 100000) + 100,
      likes: Math.floor(Math.random() * 10000) + 10,
      comments: Math.floor(Math.random() * 1000) + 1,
      shares: Math.floor(Math.random() * 500) + 1,
      downloads: Math.floor(Math.random() * 100) + 1,
      duration: Math.floor(Math.random() * 120) + 10,
      tags: Array.from({ length: Math.floor(Math.random() * 5) + 1 }, () => 
        tags[Math.floor(Math.random() * tags.length)]
      ).filter((tag, index, arr) => arr.indexOf(tag) === index),
      isVerified: Math.random() > 0.8,
      isPremium: isPremium,
      isTrending: Math.random() > 0.9,
      createdAt: createdAt.toISOString(),
      updatedAt: new Date(createdAt.getTime() + Math.random() * 7 * 24 * 60 * 60 * 1000).toISOString(),
      type: types[Math.floor(Math.random() * types.length)],
      category: category,
      quality: qualities[Math.floor(Math.random() * qualities.length)],
      resolution: '1920x1080',
      fileSize: Math.floor(Math.random() * 100) + 10, // MB
      downloadUrl: `https://cdn.mycircle.app/downloads/media_${i + 1}`,
      shareUrl: `https://mycircle.app/media/${i + 1}`,
      embedUrl: `https://mycircle.app/embed/media_${i + 1}`,
      stats: {
        shares: Math.floor(Math.random() * 100) + 1,
        downloads: Math.floor(Math.random() * 50) + 1,
        favorites: Math.floor(Math.random() * 200) + 1,
        watchTime: Math.floor(Math.random() * 3600) + 60, // seconds
      },
      metadata: {
        location: ['New York', 'Los Angeles', 'London', 'Tokyo', 'Paris'][Math.floor(Math.random() * 5)],
        camera: ['iPhone 14', 'Canon EOS', 'Sony Alpha', 'Samsung Galaxy'][Math.floor(Math.random() * 4)],
        software: ['Photoshop', 'Lightroom', 'Premiere Pro', 'Final Cut'][Math.floor(Math.random() * 4)],
      }
    };
  });
};

let media = generateRealisticMedia(500);
let users = Array.from({ length: 100 }, (_, i) => ({
  _id: `user_${i + 1}`,
  username: `user_${i + 1}`,
  email: `user${i + 1}@example.com`,
  avatar: `https://picsum.photos/200/200?random=user${i + 1}`,
  bio: `Passionate content creator sharing amazing moments. Love ${['photography', 'videography', 'art', 'music', 'gaming'][Math.floor(Math.random() * 5)]} and connecting with amazing people.`,
  isVerified: Math.random() > 0.8,
  isPremium: Math.random() > 0.85,
  isOnline: Math.random() > 0.5,
  followersCount: Math.floor(Math.random() * 10000) + 10,
  followingCount: Math.floor(Math.random() * 1000) + 5,
  postsCount: Math.floor(Math.random() * 500) + 1,
  createdAt: new Date(Date.now() - Math.random() * 365 * 24 * 60 * 60 * 1000).toISOString(),
  stats: {
    totalViews: Math.floor(Math.random() * 1000000) + 1000,
    totalLikes: Math.floor(Math.random() * 100000) + 100,
    totalComments: Math.floor(Math.random() * 10000) + 10,
    totalShares: Math.floor(Math.random() * 5000) + 5,
  },
  preferences: {
    theme: Math.random() > 0.5 ? 'dark' : 'light',
    language: 'en',
    notifications: true,
    autoplay: Math.random() > 0.5,
    privacy: ['public', 'friends', 'private'][Math.floor(Math.random() * 3)],
  },
  social: {
    instagram: `@user_${i + 1}`,
    twitter: `@user_${i + 1}`,
    website: `https://user${i + 1}.example.com`,
  },
}));

// Advanced API endpoints with intelligent caching
app.get('/api/media', async (req, res) => {
  const startTime = Date.now();
  const cacheKey = `media_${JSON.stringify(req.query)}`;
  
  let cached = mediaCache.get(cacheKey);
  if (cached) {
    return res.json({
      ...cached,
      cached: true,
      responseTime: Date.now() - startTime
    });
  }

  try {
    const { 
      page = 1, 
      limit = 20, 
      category, 
      sortBy = 'trending', 
      tags, 
      quality,
      type,
      minViews,
      maxViews,
      minLikes,
      maxLikes
    } = req.query;
    
    let filteredMedia = [...media];

    // Apply advanced filters
    if (category && category !== 'all') {
      filteredMedia = filteredMedia.filter(item => item.category === category);
    }

    if (type) {
      filteredMedia = filteredMedia.filter(item => item.type === type);
    }

    if (quality) {
      filteredMedia = filteredMedia.filter(item => item.quality === quality);
    }

    if (tags) {
      const tagArray = Array.isArray(tags) ? tags : [tags];
      filteredMedia = filteredMedia.filter(item => 
        tagArray.some(tag => item.tags.includes(tag))
      );
    }

    if (minViews) {
      filteredMedia = filteredMedia.filter(item => item.views >= parseInt(minViews));
    }

    if (maxViews) {
      filteredMedia = filteredMedia.filter(item => item.views <= parseInt(maxViews));
    }

    if (minLikes) {
      filteredMedia = filteredMedia.filter(item => item.likes >= parseInt(minLikes));
    }

    if (maxLikes) {
      filteredMedia = filteredMedia.filter(item => item.likes <= parseInt(maxLikes));
    }

    // Advanced sorting algorithms
    switch (sortBy) {
      case 'trending':
        filteredMedia.sort((a, b) => {
          const scoreA = (a.views * 0.3) + (a.likes * 0.4) + (a.comments * 0.2) + (a.shares * 0.1);
          const scoreB = (b.views * 0.3) + (b.likes * 0.4) + (b.comments * 0.2) + (b.shares * 0.1);
          return scoreB - scoreA;
        });
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
      case 'most_commented':
        filteredMedia.sort((a, b) => b.comments - a.comments);
        break;
      case 'most_shared':
        filteredMedia.sort((a, b) => b.shares - a.shares);
        break;
    }

    // Intelligent pagination
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
        hasNextPage: endIndex < filteredMedia.length,
        hasPrevPage: page > 1,
      },
      filters: {
        category,
        sortBy,
        tags: tags ? (Array.isArray(tags) ? tags : [tags]) : [],
        quality,
        type,
        minViews,
        maxViews,
        minLikes,
        maxLikes,
      },
      stats: {
        totalViews: filteredMedia.reduce((sum, item) => sum + item.views, 0),
        totalLikes: filteredMedia.reduce((sum, item) => sum + item.likes, 0),
        avgViews: Math.round(filteredMedia.reduce((sum, item) => sum + item.views, 0) / filteredMedia.length),
        avgLikes: Math.round(filteredMedia.reduce((sum, item) => sum + item.likes, 0) / filteredMedia.length),
      },
      responseTime: Date.now() - startTime,
      cached: false
    };

    // Cache for different durations based on filter complexity
    const cacheDuration = (category || tags || quality || type) ? 180 : 300; // 3min vs 5min
    mediaCache.set(cacheKey, response, cacheDuration);

    res.json(response);
  } catch (error) {
    console.error('Error in /api/media:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Enhanced search with relevance scoring
app.get('/api/search', async (req, res) => {
  const startTime = Date.now();
  const { q, category, tags, sortBy = 'relevance', limit = 50 } = req.query;
  
  if (!q && !category && !tags) {
    return res.status(400).json({ error: 'Search query or filters required' });
  }

  const cacheKey = `search_${JSON.stringify(req.query)}`;
  let cached = searchCache.get(cacheKey);
  
  if (cached) {
    return res.json({
      ...cached,
      cached: true,
      responseTime: Date.now() - startTime
    });
  }

  try {
    let results = [...media];
    const query = q ? q.toLowerCase() : '';

    // Advanced text search with relevance scoring
    if (query) {
      results = results.map(item => {
        let score = 0;
        
        // Title matches (highest weight)
        if (item.title.toLowerCase().includes(query)) {
          score += item.title.toLowerCase() === query ? 100 : 50;
        }
        
        // Description matches
        if (item.description.toLowerCase().includes(query)) {
          score += 30;
        }
        
        // Username matches
        if (item.userName.toLowerCase().includes(query)) {
          score += 20;
        }
        
        // Tag matches
        const tagMatches = item.tags.filter(tag => 
          tag.toLowerCase().includes(query)
        ).length;
        score += tagMatches * 10;
        
        // Category matches
        if (item.category.toLowerCase().includes(query)) {
          score += 15;
        }
        
        return { ...item, _searchScore: score };
      }).filter(item => item._searchScore > 0);
    } else {
      results = results.map(item => ({ ...item, _searchScore: 0 }));
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

    // Sort by relevance or other criteria
    if (sortBy === 'relevance' && query) {
      results.sort((a, b) => b._searchScore - a._searchScore);
    } else if (sortBy === 'newest') {
      results.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
    } else if (sortBy === 'popular') {
      results.sort((a, b) => b.likes - a.likes);
    }

    // Remove search score from final response
    const finalResults = results.map(({ _searchScore, ...item }) => item);

    const response = {
      query: q,
      results: finalResults.slice(0, parseInt(limit)),
      total: results.length,
      filters: { category, tags, sortBy },
      responseTime: Date.now() - startTime,
      cached: false
    };

    searchCache.set(cacheKey, response);
    res.json(response);
  } catch (error) {
    console.error('Error in /api/search:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Real-time analytics endpoint
app.get('/api/analytics', (req, res) => {
  const analytics = {
    overview: {
      totalMedia: media.length,
      totalUsers: users.length,
      totalViews: media.reduce((sum, item) => sum + item.views, 0),
      totalLikes: media.reduce((sum, item) => sum + item.likes, 0),
      totalComments: media.reduce((sum, item) => sum + item.comments, 0),
    },
    categories: media.reduce((acc, item) => {
      acc[item.category] = (acc[item.category] || 0) + 1;
      return acc;
    }, {}),
    topContent: media
      .sort((a, b) => (b.views + b.likes) - (a.views + a.likes))
      .slice(0, 10)
      .map(item => ({
        id: item._id,
        title: item.title,
        views: item.views,
        likes: item.likes,
        category: item.category,
      })),
    cache: {
      media: mediaCache.getStats(),
      user: userCache.getStats(),
      search: searchCache.getStats(),
    },
    server: {
      uptime: process.uptime(),
      memory: process.memoryUsage(),
      pid: process.pid,
      worker: cluster.worker ? cluster.worker.id : 'master',
    }
  };

  res.json(analytics);
});

// Enhanced Socket.IO for real-time features
const connectedUsers = new Map();

io.on('connection', (socket) => {
  console.log(`👤 User connected: ${socket.id} (Worker: ${cluster.worker ? cluster.worker.id : 'master'})`);

  socket.on('user_connected', (userData) => {
    connectedUsers.set(socket.id, {
      ...userData,
      connectedAt: new Date(),
      lastActivity: new Date(),
    });
    
    socket.broadcast.emit('user_online', {
      userId: userData.userId,
      username: userData.username,
    });
    
    io.emit('online_users_count', connectedUsers.size);
  });

  socket.on('join_room', (roomId) => {
    socket.join(roomId);
    console.log(`📱 User ${socket.id} joined room ${roomId}`);
  });

  socket.on('like_media', (data) => {
    const { mediaId, userId } = data;
    const mediaItem = media.find(item => item._id === mediaId);
    
    if (mediaItem) {
      mediaItem.likes += 1;
      
      // Clear related caches
      mediaCache.del('media_*');
      searchCache.del('search_*');
      
      // Broadcast to all users in media room
      io.to(`media_${mediaId}`).emit('media_liked', {
        mediaId,
        likes: mediaItem.likes,
        userId,
        timestamp: new Date().toISOString(),
      });

      // Send notification to media owner
      const ownerSocketId = Array.from(connectedUsers.entries())
        .find(([_, user]) => user.userId === mediaItem.userId)?.[0];
      
      if (ownerSocketId) {
        io.to(ownerSocketId).emit('notification', {
          type: 'like',
          title: 'New Like!',
          body: `Someone liked your content "${mediaItem.title}"`,
          data: { mediaId, userId },
          timestamp: new Date().toISOString(),
        });
      }
    }
  });

  socket.on('comment_added', (data) => {
    const { mediaId, comment, userId } = data;
    const mediaItem = media.find(item => item._id === mediaId);
    
    if (mediaItem) {
      mediaItem.comments += 1;
      
      // Clear related caches
      mediaCache.del('media_*');
      searchCache.del('search_*');
      
      // Broadcast to all users in media room
      io.to(`media_${mediaId}`).emit('new_comment', {
        mediaId,
        comment: {
          ...comment,
          timestamp: new Date().toISOString(),
        },
        userId,
        totalComments: mediaItem.comments,
      });

      // Send notification to media owner
      const ownerSocketId = Array.from(connectedUsers.entries())
        .find(([_, user]) => user.userId === mediaItem.userId)?.[0];
      
      if (ownerSocketId) {
        io.to(ownerSocketId).emit('notification', {
          type: 'comment',
          title: 'New Comment',
          body: `Someone commented on your content "${mediaItem.title}"`,
          data: { mediaId, comment, userId },
          timestamp: new Date().toISOString(),
        });
      }
    }
  });

  socket.on('follow_user', (data) => {
    const { targetUserId, userId } = data;
    
    // Update user stats
    const targetUser = users.find(u => u._id === targetUserId);
    if (targetUser) {
      targetUser.followersCount += 1;
    }
    
    const user = users.find(u => u._id === userId);
    if (user) {
      user.followingCount += 1;
    }

    // Clear user cache
    userCache.del('user_*');

    // Send notification to target user
    const targetSocketId = Array.from(connectedUsers.entries())
      .find(([_, connectedUser]) => connectedUser.userId === targetUserId)?.[0];
    
    if (targetSocketId) {
      io.to(targetSocketId).emit('notification', {
        type: 'follow',
        title: 'New Follower!',
        body: `${user?.username || 'Someone'} started following you`,
        data: { userId },
        timestamp: new Date().toISOString(),
      });
    }

    // Broadcast follow event
    socket.broadcast.emit('user_followed', {
      targetUserId,
      userId,
      timestamp: new Date().toISOString(),
    });
  });

  socket.on('activity_ping', () => {
    const user = connectedUsers.get(socket.id);
    if (user) {
      user.lastActivity = new Date();
      connectedUsers.set(socket.id, user);
    }
  });

  socket.on('disconnect', () => {
    const user = connectedUsers.get(socket.id);
    if (user) {
      connectedUsers.delete(socket.id);
      
      socket.broadcast.emit('user_offline', {
        userId: user.userId,
        username: user.username,
      });
      
      io.emit('online_users_count', connectedUsers.size);
    }
    
    console.log(`👋 User disconnected: ${socket.id}`);
  });
});

// Health check with detailed metrics
app.get('/api/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
    memory: process.memoryUsage(),
    cache: {
      media: mediaCache.getStats(),
      user: userCache.getStats(),
      search: searchCache.getStats(),
    },
    connectedUsers: connectedUsers.size,
    worker: cluster.worker ? cluster.worker.id : 'master',
    pid: process.pid,
    version: '2.0.0-ultimate',
  });
});

// Advanced error handling
app.use((err, req, res, next) => {
  console.error('🚨 Error:', err);
  
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ 
      error: 'Invalid JSON payload',
      details: err.message 
    });
  }
  
  if (err.type === 'entity.too.large') {
    return res.status(413).json({ 
      error: 'Payload too large',
      maxSize: '10MB'
    });
  }
  
  res.status(500).json({ 
    error: 'Internal server error',
    requestId: req.headers['x-request-id'] || 'unknown',
    timestamp: new Date().toISOString()
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({ 
    error: 'Route not found',
    path: req.path,
    method: req.method,
    timestamp: new Date().toISOString()
  });
});

const PORT = process.env.PORT || 5000;

server.listen(PORT, () => {
  console.log(`🚀 Ultimate server running on port ${PORT}`);
  console.log(`📊 Worker ${cluster.worker ? cluster.worker.id : 'master'} (PID: ${process.pid})`);
  console.log(`📈 Media items: ${media.length}`);
  console.log(`👥 Users: ${users.length}`);
  console.log(`💾 Cache stats: Media=${mediaCache.getStats().keys}, User=${userCache.getStats().keys}, Search=${searchCache.getStats().keys}`);
  console.log(`🌐 Ready for connections!`);
});

// Graceful shutdown
process.on('SIGTERM', () => {
  console.log('🛑 SIGTERM received, shutting down gracefully');
  server.close(() => {
    console.log('🔌 Server closed');
    process.exit(0);
  });
});

process.on('SIGINT', () => {
  console.log('🛑 SIGINT received, shutting down gracefully');
  server.close(() => {
    console.log('🔌 Server closed');
    process.exit(0);
  });
});
