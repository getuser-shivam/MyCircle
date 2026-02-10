const nodemailer = require('nodemailer');

// Create transporter
const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST || 'smtp.gmail.com',
  port: process.env.EMAIL_PORT || 587,
  secure: false,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASS
  }
});

// Send email
const sendEmail = async ({ to, subject, template, data }) => {
  try {
    // For development, just log the email
    if (process.env.NODE_ENV === 'development') {
      console.log('📧 Email would be sent:', { to, subject, template, data });
      return;
    }

    let html = '';

    // Simple email templates
    switch (template) {
      case 'welcome':
        html = `
          <h1>Welcome to MyCircle!</h1>
          <p>Hi ${data.username},</p>
          <p>Thank you for joining our platform!</p>
          <p>Please verify your email by clicking the link below:</p>
          <a href="${process.env.FRONTEND_URL}/verify-email/${data.verificationToken}">Verify Email</a>
        `;
        break;

      case 'passwordReset':
        html = `
          <h1>Password Reset</h1>
          <p>Hi ${data.username},</p>
          <p>You requested a password reset. Click the link below to reset your password:</p>
          <a href="${process.env.FRONTEND_URL}/reset-password/${data.resetToken}">Reset Password</a>
          <p>This link will expire in 10 minutes.</p>
        `;
        break;

      default:
        html = '<p>Email content</p>';
    }

    const mailOptions = {
      from: process.env.EMAIL_FROM || 'noreply@mycircle.com',
      to,
      subject,
      html
    };

    await transporter.sendMail(mailOptions);
  } catch (error) {
    console.error('Email sending failed:', error);
    throw error;
  }
};

module.exports = { sendEmail };
