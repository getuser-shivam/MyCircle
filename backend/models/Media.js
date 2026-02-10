const mongoose = require('mongoose');

const mediaSchema = new mongoose.Schema({
  title: {
    type: String,
    required: true,
    trim: true,
    maxlength: 100
  },
  description: {
    type: String,
    maxlength: 1000,
    default: ''
  },
  fileUrl: {
    type: String,
    required: true
  },
  thumbnailUrl: {
    type: String,
    required: true
  },
  fileSize: {
    type: Number,
    required: true
  },
  mimeType: {
    type: String,
    required: true
  },
  duration: {
    type: Number, // in seconds, for videos
    default: 0
  },
  width: Number,
  height: Number,
  author: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  type: {
    type: String,
    enum: ['image', 'gif', 'video'],
    required: true
  },
  category: {
    type: String,
    enum: ['general', 'trending', 'popular', 'new', 'hot', 'top_rated'],
    default: 'general'
  },
  tags: [{
    type: String,
    trim: true,
    lowercase: true
  }],
  isPrivate: {
    type: Boolean,
    default: false
  },
  isApproved: {
    type: Boolean,
    default: false
  },
  isFeatured: {
    type: Boolean,
    default: false
  },
  moderationStatus: {
    type: String,
    enum: ['pending', 'approved', 'rejected', 'flagged'],
    default: 'pending'
  },
  moderationReason: String,
  moderatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  },
  moderatedAt: Date,
  stats: {
    views: { type: Number, default: 0 },
    likes: { type: Number, default: 0 },
    comments: { type: Number, default: 0 },
    shares: { type: Number, default: 0 },
    downloads: { type: Number, default: 0 }
  },
  likes: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    createdAt: {
      type: Date,
      default: Date.now
    }
  }],
  reports: [{
    user: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'User'
    },
    reason: {
      type: String,
      enum: ['inappropriate', 'copyright', 'spam', 'harassment', 'other'],
      required: true
    },
    description: String,
    status: {
      type: String,
      enum: ['pending', 'reviewed', 'dismissed'],
      default: 'pending'
    },
    createdAt: {
      type: Date,
      default: Date.now
    }
  }],
  processing: {
    status: {
      type: String,
      enum: ['pending', 'processing', 'completed', 'failed'],
      default: 'pending'
    },
    progress: {
      type: Number,
      min: 0,
      max: 100,
      default: 0
    },
    error: String,
    startedAt: Date,
    completedAt: Date
  },
  metadata: {
    // Video-specific metadata
    bitrate: Number,
    frameRate: Number,
    codec: String,
    // Image-specific metadata
    format: String,
    colorSpace: String,
    // AI-generated content detection
    aiGenerated: { type: Boolean, default: false },
    aiConfidence: Number
  },
  expiresAt: Date, // For temporary content
  deletedAt: Date // Soft delete
}, {
  timestamps: true
});

// Indexes for performance
mediaSchema.index({ author: 1, createdAt: -1 });
mediaSchema.index({ category: 1, createdAt: -1 });
mediaSchema.index({ tags: 1 });
mediaSchema.index({ 'stats.views': -1 });
mediaSchema.index({ 'stats.likes': -1 });
mediaSchema.index({ createdAt: -1 });
mediaSchema.index({ moderationStatus: 1 });
mediaSchema.index({ isFeatured: 1, createdAt: -1 });
mediaSchema.index({ type: 1, createdAt: -1 });

// Virtual for total engagement
mediaSchema.virtual('engagementScore').get(function() {
  return this.stats.likes * 2 + this.stats.comments * 3 + this.stats.shares * 4 + this.stats.views * 0.1;
});

// Virtual for like count
mediaSchema.virtual('likeCount').get(function() {
  return this.likes.length;
});

// Instance methods
mediaSchema.methods.incrementViews = function() {
  this.stats.views += 1;
  return this.save();
};

mediaSchema.methods.addLike = function(userId) {
  if (!this.likes.some(like => like.user.equals(userId))) {
    this.likes.push({ user: userId });
    this.stats.likes = this.likes.length;
    return this.save();
  }
  return this;
};

mediaSchema.methods.removeLike = function(userId) {
  this.likes = this.likes.filter(like => !like.user.equals(userId));
  this.stats.likes = this.likes.length;
  return this.save();
};

mediaSchema.methods.addReport = function(userId, reason, description) {
  this.reports.push({
    user: userId,
    reason,
    description
  });
  return this.save();
};

mediaSchema.methods.approve = function(moderatorId) {
  this.moderationStatus = 'approved';
  this.isApproved = true;
  this.moderatedBy = moderatorId;
  this.moderatedAt = new Date();
  return this.save();
};

mediaSchema.methods.reject = function(moderatorId, reason) {
  this.moderationStatus = 'rejected';
  this.isApproved = false;
  this.moderationReason = reason;
  this.moderatedBy = moderatorId;
  this.moderatedAt = new Date();
  return this.save();
};

// Static methods
mediaSchema.statics.findByAuthor = function(authorId, limit = 20) {
  return this.find({ author: authorId, deletedAt: null })
    .sort({ createdAt: -1 })
    .limit(limit);
};

mediaSchema.statics.findTrending = function(limit = 20) {
  return this.find({
    isApproved: true,
    moderationStatus: 'approved',
    deletedAt: null
  })
  .sort({ 'stats.views': -1, createdAt: -1 })
  .limit(limit);
};

mediaSchema.statics.findPopular = function(limit = 20) {
  return this.find({
    isApproved: true,
    moderationStatus: 'approved',
    deletedAt: null
  })
  .sort({ engagementScore: -1, createdAt: -1 })
  .limit(limit);
};

mediaSchema.statics.findByCategory = function(category, limit = 20) {
  return this.find({
    category,
    isApproved: true,
    moderationStatus: 'approved',
    deletedAt: null
  })
  .sort({ createdAt: -1 })
  .limit(limit);
};

mediaSchema.statics.search = function(query, limit = 20) {
  const searchRegex = new RegExp(query, 'i');
  return this.find({
    $or: [
      { title: searchRegex },
      { description: searchRegex },
      { tags: searchRegex }
    ],
    isApproved: true,
    moderationStatus: 'approved',
    deletedAt: null
  })
  .sort({ createdAt: -1 })
  .limit(limit);
};

// Middleware to update user stats when media is saved
mediaSchema.post('save', async function(doc) {
  if (doc.author) {
    const User = mongoose.model('User');
    await User.findByIdAndUpdate(doc.author, {
      $push: { posts: doc._id }
    });
  }
});

// Middleware for soft delete
mediaSchema.pre('find', function() {
  this.where({ deletedAt: null });
});

mediaSchema.pre('findOne', function() {
  this.where({ deletedAt: null });
});

module.exports = mongoose.model('Media', mediaSchema);
