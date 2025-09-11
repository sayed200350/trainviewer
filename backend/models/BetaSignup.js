const mongoose = require('mongoose');

const betaSignupSchema = new mongoose.Schema({
    // Personal Information
    email: {
        type: String,
        required: [true, 'Email is required'],
        unique: true,
        lowercase: true,
        trim: true,
        match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
    },
    name: {
        type: String,
        required: [true, 'Name is required'],
        trim: true,
        maxlength: [100, 'Name cannot exceed 100 characters']
    },

    // Device & Experience
    device: {
        type: String,
        required: [true, 'Device type is required'],
        enum: {
            values: ['iphone', 'ipad', 'ipod'],
            message: 'Device must be iphone, ipad, or ipod'
        }
    },
    experience: {
        type: String,
        enum: ['daily', 'weekly', 'monthly', 'rarely', ''],
        default: ''
    },

    // Feature Interests
    features: [{
        type: String,
        enum: ['siri', 'widgets', 'semester', 'offline', 'notifications', 'analytics']
    }],

    // Status Tracking
    status: {
        type: String,
        enum: ['pending', 'approved', 'invited', 'installed', 'rejected'],
        default: 'pending'
    },
    inviteSentAt: {
        type: Date
    },
    invitedBy: {
        type: String,
        trim: true
    },

    // TestFlight Specific
    testflightUrl: {
        type: String,
        trim: true
    },
    testflightCode: {
        type: String,
        trim: true
    },

    // Metadata
    ipAddress: {
        type: String,
        trim: true
    },
    userAgent: {
        type: String,
        trim: true
    },
    source: {
        type: String,
        default: 'website',
        enum: ['website', 'app_store', 'social', 'referral']
    },

    // Communication
    emailSent: [{
        type: {
            type: String,
            enum: ['welcome', 'invite', 'reminder', 'update']
        },
        sentAt: {
            type: Date,
            default: Date.now
        },
        emailId: String
    }],

    // Admin Notes
    adminNotes: {
        type: String,
        trim: true
    },

    // Timestamps
    createdAt: {
        type: Date,
        default: Date.now
    },
    updatedAt: {
        type: Date,
        default: Date.now
    }
});

// Indexes for performance
betaSignupSchema.index({ email: 1 });
betaSignupSchema.index({ status: 1 });
betaSignupSchema.index({ createdAt: -1 });
betaSignupSchema.index({ device: 1 });

// Update updatedAt on save
betaSignupSchema.pre('save', function(next) {
    this.updatedAt = Date.now();
    next();
});

// Virtual for invite status
betaSignupSchema.virtual('isInvited').get(function() {
    return this.status === 'invited' || this.status === 'installed';
});

// Method to mark as invited
betaSignupSchema.methods.markAsInvited = function(testflightUrl, testflightCode) {
    this.status = 'invited';
    this.inviteSentAt = new Date();
    this.testflightUrl = testflightUrl;
    this.testflightCode = testflightCode;
    return this.save();
};

// Method to check if user can receive invite
betaSignupSchema.methods.canReceiveInvite = function() {
    return this.status === 'pending' || this.status === 'approved';
};

// Static method to get signup stats
betaSignupSchema.statics.getStats = async function() {
    const stats = await this.aggregate([
        {
            $group: {
                _id: '$status',
                count: { $sum: 1 }
            }
        }
    ]);

    const result = {
        total: 0,
        pending: 0,
        approved: 0,
        invited: 0,
        installed: 0,
        rejected: 0
    };

    stats.forEach(stat => {
        result[stat._id] = stat.count;
        result.total += stat.count;
    });

    return result;
};

module.exports = mongoose.model('BetaSignup', betaSignupSchema);

