const nodemailer = require('nodemailer');

// Create transporter based on environment
const createTransporter = () => {
    if (process.env.NODE_ENV === 'production') {
        // Use production email service (SendGrid, AWS SES, etc.)
        return nodemailer.createTransporter({
            host: process.env.SMTP_HOST,
            port: process.env.SMTP_PORT,
            secure: process.env.SMTP_SECURE === 'true',
            auth: {
                user: process.env.SMTP_USER,
                pass: process.env.SMTP_PASS
            }
        });
    } else {
        // Use Gmail for development (or Ethereal for testing)
        return nodemailer.createTransporter({
            service: 'gmail',
            auth: {
                user: process.env.GMAIL_USER,
                pass: process.env.GMAIL_APP_PASSWORD
            }
        });
    }
};

// HTML email templates
const getWelcomeEmailTemplate = (signup) => {
    return `
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Welcome to BahnBlitz Beta</title>
    <style>
        body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #1a73e8, #00d4aa); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .button { display: inline-block; background: #1a73e8; color: white; padding: 12px 30px; text-decoration: none; border-radius: 5px; margin: 20px 0; }
        .footer { text-align: center; color: #666; font-size: 12px; margin-top: 30px; }
        .features { background: white; padding: 20px; border-radius: 8px; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🚂 Welcome to BahnBlitz Beta!</h1>
            <p>You're now part of our exclusive beta testing program</p>
        </div>

        <div class="content">
            <h2>Hi ${signup.name}!</h2>

            <p>Thank you for joining the BahnBlitz beta program! We're excited to have you as part of our community of German commuters who are helping shape the future of train travel apps.</p>

            <div class="features">
                <h3>🎯 What to expect:</h3>
                <ul>
                    <li>📧 <strong>Regular Updates:</strong> We'll keep you informed about new features and improvements</li>
                    <li>🎫 <strong>Early Access:</strong> Be among the first to try new features</li>
                    <li>💬 <strong>Direct Feedback:</strong> Your input helps us build a better app</li>
                    <li>🎁 <strong>Exclusive Content:</strong> Beta-only features and early releases</li>
                </ul>
            </div>

            <p><strong>Your beta application is being reviewed.</strong> We'll send you a TestFlight invitation within 24-48 hours if approved.</p>

            <p>In the meantime, you can:</p>
            <ul>
                <li>Follow us on social media for updates</li>
                <li>Read our blog for behind-the-scenes content</li>
                <li>Share your feedback about German public transport</li>
            </ul>

            <p>Questions? Just reply to this email!</p>

            <p>Best regards,<br>The BahnBlitz Team</p>
        </div>

        <div class="footer">
            <p>This email was sent to ${signup.email} because you signed up for BahnBlitz beta testing.</p>
            <p>You can unsubscribe at any time by replying with "UNSUBSCRIBE".</p>
        </div>
    </div>
</body>
</html>`;
};

const getTestFlightInviteTemplate = (signup, testflightUrl) => {
    return `
<!DOCTYPE html>
<html>
<head>
    <meta charset="utf-8">
    <title>Your BahnBlitz TestFlight Invite</title>
    <style>
        body { font-family: 'Inter', Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #ff6b35, #ef4444); color: white; padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .button { display: inline-block; background: #ff6b35; color: white; padding: 15px 40px; text-decoration: none; border-radius: 8px; margin: 20px 0; font-weight: bold; }
        .button:hover { background: #e55a2b; }
        .urgent { background: #fef3c7; border: 1px solid #f59e0b; padding: 15px; border-radius: 5px; margin: 20px 0; }
        .footer { text-align: center; color: #666; font-size: 12px; margin-top: 30px; }
        .code { background: #e5e7eb; padding: 10px; border-radius: 5px; font-family: monospace; font-size: 16px; margin: 10px 0; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🎉 Your TestFlight Invite is Here!</h1>
            <p>Start testing BahnBlitz today</p>
        </div>

        <div class="content">
            <h2>Congratulations, ${signup.name}!</h2>

            <p>Your beta application has been approved! 🎊</p>

            <div class="urgent">
                <strong>⚡ Limited Time:</strong> This invite expires in 90 days. Make sure to download and install the app before then!
            </div>

            <p>Click the button below to download BahnBlitz via TestFlight:</p>

            <div style="text-align: center;">
                <a href="${testflightUrl}" class="button">🚀 Download BahnBlitz Beta</a>
            </div>

            <p><strong>Installation Steps:</strong></p>
            <ol>
                <li>Tap the "Download" button above</li>
                <li>Install TestFlight if prompted</li>
                <li>Open TestFlight and install BahnBlitz</li>
                <li>Start using the app and send us feedback!</li>
            </ol>

            <p><strong>What you'll get in this beta:</strong></p>
            <ul>
                <li>✅ Real-time German train departures</li>
                <li>✅ Smart route management</li>
                <li>✅ Semester ticket support</li>
                <li>✅ Offline functionality</li>
                <li>🚧 Voice commands (coming soon)</li>
            </ul>

            <p><strong>How to provide feedback:</strong></p>
            <ul>
                <li>Open TestFlight app</li>
                <li>Tap on BahnBlitz</li>
                <li>Scroll down and tap "Send Beta Feedback"</li>
                <li>Include screenshots and detailed descriptions</li>
            </ul>

            <p>Your feedback is crucial for making BahnBlitz the best train app for German commuters!</p>

            <p>Happy testing! 🚂🇩🇪</p>

            <p>Best regards,<br>The BahnBlitz Team</p>
        </div>

        <div class="footer">
            <p>This email was sent to ${signup.email} because you signed up for BahnBlitz beta testing.</p>
            <p>Invite expires: ${new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toLocaleDateString()}</p>
        </div>
    </div>
</body>
</html>`;
};

// Send welcome email
const sendWelcomeEmail = async (signup) => {
    const transporter = createTransporter();

    const mailOptions = {
        from: `"BahnBlitz Team" <${process.env.EMAIL_FROM || 'noreply@bahnblitz.app'}>`,
        to: signup.email,
        subject: '🚂 Welcome to BahnBlitz Beta - Your Application is Being Reviewed!',
        html: getWelcomeEmailTemplate(signup)
    };

    try {
        const info = await transporter.sendMail(mailOptions);
        console.log('Welcome email sent:', info.messageId);

        // Track email sent
        signup.emailSent.push({
            type: 'welcome',
            emailId: info.messageId
        });
        await signup.save();

        return { success: true, messageId: info.messageId };
    } catch (error) {
        console.error('Welcome email error:', error);
        throw new Error('Failed to send welcome email');
    }
};

// Send TestFlight invite email
const sendTestFlightInvite = async (signup, testflightUrl) => {
    const transporter = createTransporter();

    const mailOptions = {
        from: `"BahnBlitz Team" <${process.env.EMAIL_FROM || 'noreply@bahnblitz.app'}>`,
        to: signup.email,
        subject: '🎉 Your BahnBlitz TestFlight Invite is Ready!',
        html: getTestFlightInviteTemplate(signup, testflightUrl)
    };

    try {
        const info = await transporter.sendMail(mailOptions);
        console.log('TestFlight invite email sent:', info.messageId);

        // Track email sent
        signup.emailSent.push({
            type: 'invite',
            emailId: info.messageId
        });
        await signup.save();

        return { success: true, messageId: info.messageId };
    } catch (error) {
        console.error('TestFlight invite email error:', error);
        throw new Error('Failed to send TestFlight invite email');
    }
};

// Send reminder email
const sendReminderEmail = async (signup) => {
    const transporter = createTransporter();

    const reminderTemplate = `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
            <h2>⏰ Gentle Reminder: Your BahnBlitz Beta Invite</h2>
            <p>Hi ${signup.name},</p>
            <p>We noticed you haven't installed BahnBlitz yet. Your TestFlight invite is waiting!</p>
            <p><a href="${signup.testflightUrl}" style="background: #1a73e8; color: white; padding: 10px 20px; text-decoration: none; border-radius: 5px;">Install Now</a></p>
            <p>The BahnBlitz Team</p>
        </div>
    `;

    const mailOptions = {
        from: `"BahnBlitz Team" <${process.env.EMAIL_FROM || 'noreply@bahnblitz.app'}>`,
        to: signup.email,
        subject: '⏰ Don\'t Forget: Your BahnBlitz Beta Invite',
        html: reminderTemplate
    };

    try {
        const info = await transporter.sendMail(mailOptions);
        console.log('Reminder email sent:', info.messageId);

        signup.emailSent.push({
            type: 'reminder',
            emailId: info.messageId
        });
        await signup.save();

        return { success: true, messageId: info.messageId };
    } catch (error) {
        console.error('Reminder email error:', error);
        throw new Error('Failed to send reminder email');
    }
};

module.exports = {
    sendWelcomeEmail,
    sendTestFlightInvite,
    sendReminderEmail
};

