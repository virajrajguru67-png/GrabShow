import nodemailer, { type Transporter } from 'nodemailer';

import { env } from '../config/index.js';

let transporter: Transporter | null = null;

const initializeTransporter = () => {
  if (transporter) return transporter;

  // Check if SMTP is configured
  if (!env.SMTP_HOST || !env.SMTP_USER || !env.SMTP_PASS) {
    console.warn('SMTP not configured. Email sending will be disabled.');
    return null;
  }

  transporter = nodemailer.createTransport({
    host: env.SMTP_HOST,
    port: env.SMTP_PORT,
    secure: env.SMTP_SECURE, // true for 465, false for other ports
    auth: {
      user: env.SMTP_USER,
      pass: env.SMTP_PASS,
    },
  });

  return transporter;
};

export const sendPasswordResetOtp = async (email: string, otp: string) => {
  const mailer = initializeTransporter();
  if (!mailer) {
    // In development, log the OTP instead of sending email
    console.log('SMTP not configured. Password reset OTP:', otp);
    return null; // Return null to indicate email was not sent
  }

  const mailOptions = {
    from: `"${env.SMTP_FROM_NAME}" <${env.SMTP_FROM_EMAIL}>`,
    to: email,
    subject: 'Your Password Reset OTP - StreamFlix',
    html: `
      <!DOCTYPE html>
      <html>
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
        </head>
        <body style="font-family: Arial, sans-serif; line-height: 1.6; color: #333; max-width: 600px; margin: 0 auto; padding: 20px;">
          <div style="background: linear-gradient(135deg, #3B82F6 0%, #1A1F3A 100%); padding: 30px; text-align: center; border-radius: 12px 12px 0 0;">
            <h1 style="color: white; margin: 0; font-size: 28px;">StreamFlix Tickets</h1>
          </div>
          <div style="background: #ffffff; padding: 30px; border-radius: 0 0 12px 12px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);">
            <h2 style="color: #1A1F3A; margin-top: 0;">Password Reset OTP</h2>
            <p>Hello,</p>
            <p>We received a request to reset your password for your StreamFlix account. Use the OTP below to reset your password:</p>
            <div style="text-align: center; margin: 30px 0;">
              <div style="background: #f5f5f5; border: 2px dashed #3B82F6; border-radius: 8px; padding: 20px; display: inline-block;">
                <div style="font-size: 36px; font-weight: bold; color: #3B82F6; letter-spacing: 8px; font-family: 'Courier New', monospace;">${otp}</div>
              </div>
            </div>
            <p style="color: #666; font-size: 14px; text-align: center;">This OTP will expire in 10 minutes.</p>
            <p style="color: #666; font-size: 14px;">If you didn't request a password reset, please ignore this email or contact support if you have concerns.</p>
            <hr style="border: none; border-top: 1px solid #eee; margin: 30px 0;">
            <p style="color: #999; font-size: 12px; margin: 0;">© ${new Date().getFullYear()} StreamFlix Tickets. All rights reserved.</p>
          </div>
        </body>
      </html>
    `,
    text: `
      Password Reset OTP - StreamFlix
      
      We received a request to reset your password for your StreamFlix account.
      
      Your OTP is: ${otp}
      
      This OTP will expire in 10 minutes.
      
      If you didn't request a password reset, please ignore this email.
    `,
  };

  try {
    const info = await mailer.sendMail(mailOptions);
    console.log('Password reset OTP email sent:', info.messageId);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    console.error('Error sending password reset OTP email:', error);
    throw error;
  }
};

export const isEmailConfigured = () => {
  return !!(env.SMTP_HOST && env.SMTP_USER && env.SMTP_PASS);
};

