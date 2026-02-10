const mongoose = require('mongoose');

const userSchema = new mongoose.Schema({
  username: {
    type: String,
    required: true,
    unique: true,
    trim: true,
    minlength: 3,
    maxlength: 30
  },
  email: {
    type: String,
    required: true,
    unique: true,
    lowercase: true,
    trim: true
  },
  password: {
    type: String,
    required: true,
    minlength: 6
  },
  avatar: {
    type: String,
    default: ''
  },
  bio: {
    type: String,
    maxlength: 500,
    default: ''
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  isPremium: {
    type: Boolean,
    default: false
  },
  followers: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  following: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User'
  }],
  posts: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Media'
  }],
  likedPosts: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Media'
  }],
  savedPosts: [{
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Media'
  }],
  stats: {
    totalViews: { type: Number, default: 0 },
    totalLikes: { type: Number, default: 0 },
    totalComments: { type: Number, default: 0 }
  },
  preferences: {
    theme: { type: String, enum: ['light', 'dark'], default: 'dark' },
    notifications: {
      likes: { type: Boolean, default: true },
      comments: { type: Boolean, default: true },
      follows: { type: Boolean, default: true },
      mentions: { type: Boolean, default: true }
    },
    privacy: {
      profileVisibility: { type: String, enum: ['public', 'private'], default: 'public' },
      showOnlineStatus: { type: Boolean, default: true }
    }
  },
  lastLogin: Date,
  emailVerifiedAt: Date,
  bannedAt: Date,
  banReason: String
}, {
  timestamps: true
});

// Indexes for performance
userSchema.index({ username: 1 });
userSchema.index({ email: 1 });
userSchema.index({ createdAt: -1 });
userSchema.index({ 'stats.totalViews': -1 });

// Virtual for follower count
userSchema.virtual('followerCount').get(function() {
  return this.followers.length;
});

// Virtual for following count
userSchema.virtual('followingCount').get(function() {
  return this.following.length;
});

// Virtual for post count
userSchema.virtual('postCount').get(function() {
  return this.posts.length;
});

// Instance methods
userSchema.methods.follow = function(userId) {
  if (this.following.indexOf(userId) === -1) {
    this.following.push(userId);
  }
  return this.save();
};

userSchema.methods.unfollow = function(userId) {
  this.following = this.following.filter(id => !id.equals(userId));
  return this.save();
};

userSchema.methods.likePost = function(mediaId) {
  if (this.likedPosts.indexOf(mediaId) === -1) {
    this.likedPosts.push(mediaId);
  }
  return this.save();
};

userSchema.methods.unlikePost = function(mediaId) {
  this.likedPosts = this.likedPosts.filter(id => !id.equals(mediaId));
  return this.save();
};

userSchema.methods.savePost = function(mediaId) {
  if (this.savedPosts.indexOf(mediaId) === -1) {
    this.savedPosts.push(mediaId);
  }
  return this.save();
};

userSchema.methods.unsavePost = function(mediaId) {
  this.savedPosts = this.savedPosts.filter(id => !id.equals(mediaId));
  return this.save();
};

// Static methods
userSchema.statics.findByUsername = function(username) {
  return this.findOne({ username: new RegExp(`^${username}$`, 'i') });
};

userSchema.statics.findByEmail = function(email) {
  return this.findOne({ email: email.toLowerCase() });
};

module.exports = mongoose.model('User', userSchema);
