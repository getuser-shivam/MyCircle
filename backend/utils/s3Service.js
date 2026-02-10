// AWS S3 service for file uploads
const AWS = require('aws-sdk');

// Configure AWS
AWS.config.update({
  accessKeyId: process.env.AWS_ACCESS_KEY_ID,
  secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  region: process.env.AWS_REGION || 'us-east-1'
});

const s3 = new AWS.S3();

// Upload file to S3
const uploadToS3 = async (buffer, key, contentType) => {
  try {
    // For development, return a mock URL
    if (process.env.NODE_ENV === 'development') {
      const mockUrl = `https://mock-s3-storage.com/${key}`;
      console.log('📁 File would be uploaded to S3:', mockUrl);
      return mockUrl;
    }

    const params = {
      Bucket: process.env.AWS_S3_BUCKET,
      Key: key,
      Body: buffer,
      ContentType: contentType,
      ACL: 'public-read'
    };

    const result = await s3.upload(params).promise();
    return result.Location;
  } catch (error) {
    console.error('S3 upload error:', error);
    throw error;
  }
};

// Delete file from S3
const deleteFromS3 = async (url) => {
  try {
    // For development, just log
    if (process.env.NODE_ENV === 'development') {
      console.log('🗑️ File would be deleted from S3:', url);
      return;
    }

    const key = url.split('/').slice(-2).join('/'); // Extract key from URL
    const params = {
      Bucket: process.env.AWS_S3_BUCKET,
      Key: key
    };

    await s3.deleteObject(params).promise();
  } catch (error) {
    console.error('S3 delete error:', error);
    // Don't throw error for delete failures
  }
};

module.exports = { uploadToS3, deleteFromS3 };
