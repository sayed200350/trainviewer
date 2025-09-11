# 🚂 BahnBlitz Backend - TestFlight Beta Management

Backend API for managing BahnBlitz beta testing program with automated TestFlight invites.

## 📋 Features

- ✅ **Beta Signup Management** - Collect and manage beta tester applications
- ✅ **Automated TestFlight Invites** - Send invites via email automatically
- ✅ **Email Integration** - Welcome emails and TestFlight notifications
- ✅ **Admin Dashboard API** - Manage signups and send bulk invites
- ✅ **Analytics Tracking** - Monitor signup and conversion metrics
- ✅ **Security & Validation** - Input validation and rate limiting

## 🏗️ Architecture

```
backend/
├── src/
│   ├── server.js           # Main server file
│   ├── routes/
│   │   └── betaRoutes.js   # Beta signup API routes
│   ├── services/
│   │   ├── emailService.js     # Email sending service
│   │   └── testflightService.js # TestFlight management
│   └── middleware/
│       └── errorHandler.js     # Global error handling
├── models/
│   └── BetaSignup.js       # MongoDB schema
├── config/                 # Configuration files
├── .env.example           # Environment template
└── package.json           # Dependencies
```

## 🚀 Quick Start

### Prerequisites
- Node.js 16+
- MongoDB (local or cloud)
- Gmail account (for development) or SMTP service (production)

### Installation

1. **Clone and install dependencies:**
```bash
cd backend
npm install
```

2. **Set up environment variables:**
```bash
cp .env.example .env
# Edit .env with your configuration
```

3. **Start MongoDB:**
```bash
# Local MongoDB
brew services start mongodb-community

# Or use MongoDB Atlas (cloud)
```

4. **Start the server:**
```bash
# Development
npm run dev

# Production
npm start
```

The API will be available at `http://localhost:3001`

## 🔧 Configuration

### Environment Variables

#### Required
```env
MONGODB_URI=mongodb://localhost:27017/bahnblitz-beta
TESTFLIGHT_URL=https://testflight.apple.com/join/YOUR_APP_ID
EMAIL_FROM=noreply@bahnblitz.app
```

#### Email Setup (Choose one method)

**Method 1: Gmail (Development)**
```env
GMAIL_USER=your-email@gmail.com
GMAIL_APP_PASSWORD=your-gmail-app-password
```

**Method 2: SMTP (Production)**
```env
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=apikey
SMTP_PASS=your-sendgrid-api-key
```

### TestFlight Setup

1. **Create TestFlight Public Link:**
   - Go to App Store Connect → TestFlight
   - Create a Public Link for your app
   - Copy the URL (format: `https://testflight.apple.com/join/ABC123`)

2. **Update Environment:**
```env
TESTFLIGHT_URL=https://testflight.apple.com/join/YOUR_LINK
```

## 📡 API Endpoints

### Public Endpoints

#### `POST /api/beta-signup`
Register for beta testing
```json
{
  "email": "user@example.com",
  "name": "John Doe",
  "device": "iphone",
  "experience": "daily",
  "features": ["siri", "widgets"],
  "source": "website"
}
```

#### Response
```json
{
  "success": true,
  "message": "Successfully registered for BahnBlitz beta!",
  "data": {
    "id": "64f...",
    "status": "pending",
    "estimatedWaitTime": "24-48 hours"
  }
}
```

### Admin Endpoints (Protected)

#### `GET /api/beta-signup/stats`
Get signup statistics
```json
{
  "success": true,
  "data": {
    "total": 150,
    "pending": 45,
    "approved": 30,
    "invited": 60,
    "installed": 15
  }
}
```

#### `GET /api/beta-signup/pending?page=1&limit=50`
Get pending signups for review

#### `POST /api/beta-signup/:id/invite`
Send TestFlight invite to specific user
```json
{
  "testflightUrl": "https://testflight.apple.com/join/ABC123"
}
```

#### `PUT /api/beta-signup/:id/status`
Update user status
```json
{
  "status": "approved",
  "adminNotes": "Great candidate for beta testing"
}
```

## 🎯 TestFlight Integration Workflow

### 1. User Signs Up
- User fills form on website
- Data saved to MongoDB
- Welcome email sent automatically

### 2. Admin Review
- Admin reviews pending signups
- Approves users for TestFlight invites
- Can add notes and prioritize users

### 3. Send Invites
- Bulk or individual invites
- TestFlight URLs emailed to users
- Status updated in database

### 4. Track Results
- Monitor invite acceptance
- Track app installations
- Send follow-up emails if needed

## 📧 Email Templates

### Welcome Email
- Sent immediately after signup
- Explains beta program
- Sets expectations for TestFlight invite

### TestFlight Invite Email
- Contains direct TestFlight link
- Installation instructions
- Expiration notice (90 days)
- Feedback instructions

## 🛠️ Development Tools

### Admin Dashboard (Optional)
Create a simple admin interface to manage signups:

```javascript
// Example admin interface
const adminApp = express();

// Protect admin routes
app.use('/admin', authenticateAdmin);

// Admin dashboard
app.get('/admin', async (req, res) => {
    const stats = await BetaSignup.getStats();
    const pending = await BetaSignup.find({ status: 'pending' });
    res.render('admin', { stats, pending });
});
```

### Bulk Invite Script
```javascript
// scripts/sendBulkInvites.js
const BetaSignup = require('../models/BetaSignup');
const { sendBulkInvites } = require('../services/testflightService');

async function sendBulkInvites() {
    const approvedUsers = await BetaSignup.find({ status: 'approved' });
    const results = await sendBulkInvites(approvedUsers, process.env.TESTFLIGHT_URL);
    console.log('Bulk invite results:', results);
}
```

## 🔒 Security Features

- **Rate Limiting**: 100 requests per 15 minutes per IP
- **Input Validation**: Comprehensive validation with Joi
- **CORS Protection**: Configured for allowed origins
- **Helmet Security**: Security headers
- **MongoDB Injection Protection**: Mongoose built-in protection

## 📊 Analytics & Monitoring

### Built-in Metrics
- Signup conversion rates
- Email delivery success
- TestFlight invite acceptance
- Device type distribution

### Integration Options
- Google Analytics
- Mixpanel
- Custom analytics dashboard

## 🚀 Deployment

### Development
```bash
npm run dev  # With nodemon
```

### Production
```bash
npm start
```

### Docker (Optional)
```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY . .
EXPOSE 3001
CMD ["npm", "start"]
```

### Environment Setup
```bash
# Production environment
NODE_ENV=production
MONGODB_URI=mongodb+srv://...
SMTP_HOST=smtp.sendgrid.net
# ... other production vars
```

## 🔧 Troubleshooting

### Common Issues

**Email not sending:**
- Check Gmail app password or SMTP credentials
- Verify firewall settings
- Check spam folder

**MongoDB connection:**
- Ensure MongoDB is running
- Check connection string
- Verify network access

**TestFlight links:**
- Verify public link is active in App Store Connect
- Check link format
- Ensure app is in TestFlight beta

### Debug Mode
```bash
DEBUG=* npm run dev
```

## 📈 Scaling Considerations

### Database
- Add indexes for performance
- Consider read replicas for analytics
- Implement caching with Redis

### Email
- Use dedicated SMTP service (SendGrid, Mailgun)
- Implement email queues for bulk sends
- Add email analytics

### Monitoring
- Add health checks
- Implement logging
- Set up error tracking

## 🤝 Contributing

1. Fork the repository
2. Create feature branch
3. Add tests for new features
4. Submit pull request

## 📞 Support

- **API Issues**: Check `/health` endpoint
- **Email Issues**: Verify SMTP configuration
- **Database Issues**: Check MongoDB connection
- **TestFlight Issues**: Verify App Store Connect setup

---

**Built for German commuters, by German commuters** 🇩🇪🚂✨

