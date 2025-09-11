const express = require('express');
const { body, validationResult } = require('express-validator');
const BetaSignup = require('../models/BetaSignup');
const { sendWelcomeEmail, sendTestFlightInvite } = require('../services/emailService');
const { generateTestFlightCode } = require('../services/testflightService');

const router = express.Router();

// Validation middleware
const validateBetaSignup = [
    body('email')
        .isEmail()
        .normalizeEmail()
        .withMessage('Please provide a valid email address'),
    body('name')
        .trim()
        .isLength({ min: 2, max: 100 })
        .withMessage('Name must be between 2 and 100 characters'),
    body('device')
        .isIn(['iphone', 'ipad', 'ipod'])
        .withMessage('Device must be iphone, ipad, or ipod'),
    body('experience')
        .optional()
        .isIn(['daily', 'weekly', 'monthly', 'rarely', ''])
        .withMessage('Invalid experience level'),
    body('features')
        .optional()
        .isArray()
        .withMessage('Features must be an array'),
    body('features.*')
        .optional()
        .isIn(['siri', 'widgets', 'semester', 'offline', 'notifications', 'analytics'])
        .withMessage('Invalid feature selection')
];

// @route   POST /api/beta-signup
// @desc    Register for beta testing
// @access  Public
router.post('/beta-signup', validateBetaSignup, async (req, res) => {
    try {
        // Check for validation errors
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({
                success: false,
                message: 'Validation failed',
                errors: errors.array()
            });
        }

        const {
            email,
            name,
            device,
            experience,
            features,
            source
        } = req.body;

        // Check if email already exists
        const existingSignup = await BetaSignup.findOne({ email: email.toLowerCase() });
        if (existingSignup) {
            if (existingSignup.status === 'invited') {
                return res.status(200).json({
                    success: true,
                    message: 'You are already registered and have been invited to test!',
                    data: {
                        status: 'already_invited',
                        testflightUrl: existingSignup.testflightUrl
                    }
                });
            }

            return res.status(409).json({
                success: false,
                message: 'This email is already registered for beta testing'
            });
        }

        // Create new beta signup
        const newSignup = new BetaSignup({
            email: email.toLowerCase(),
            name,
            device,
            experience,
            features: features || [],
            source: source || 'website',
            ipAddress: req.ip,
            userAgent: req.get('User-Agent')
        });

        await newSignup.save();

        // Send welcome email
        try {
            await sendWelcomeEmail(newSignup);
        } catch (emailError) {
            console.error('Welcome email failed:', emailError);
            // Don't fail the signup if email fails
        }

        res.status(201).json({
            success: true,
            message: 'Successfully registered for BahnBlitz beta! Check your email for updates.',
            data: {
                id: newSignup._id,
                status: newSignup.status,
                estimatedWaitTime: '24-48 hours'
            }
        });

    } catch (error) {
        console.error('Beta signup error:', error);
        res.status(500).json({
            success: false,
            message: 'Server error occurred during signup'
        });
    }
});

// @route   GET /api/beta-signup/stats
// @desc    Get beta signup statistics
// @access  Private (Admin only)
router.get('/beta-signup/stats', async (req, res) => {
    try {
        // In production, add authentication middleware here
        const stats = await BetaSignup.getStats();

        res.json({
            success: true,
            data: stats
        });
    } catch (error) {
        console.error('Stats error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch statistics'
        });
    }
});

// @route   POST /api/beta-signup/:id/invite
// @desc    Send TestFlight invite to user
// @access  Private (Admin only)
router.post('/beta-signup/:id/invite', async (req, res) => {
    try {
        const { id } = req.params;
        const { testflightUrl } = req.body;

        // Find the signup
        const signup = await BetaSignup.findById(id);
        if (!signup) {
            return res.status(404).json({
                success: false,
                message: 'Beta signup not found'
            });
        }

        // Check if user can receive invite
        if (!signup.canReceiveInvite()) {
            return res.status(400).json({
                success: false,
                message: `User status is ${signup.status}, cannot send invite`
            });
        }

        // Generate TestFlight code if not provided
        const testflightCode = signup.testflightCode || generateTestFlightCode();
        const inviteUrl = testflightUrl || process.env.TESTFLIGHT_URL;

        if (!inviteUrl) {
            return res.status(400).json({
                success: false,
                message: 'TestFlight URL not configured'
            });
        }

        // Mark as invited
        await signup.markAsInvited(inviteUrl, testflightCode);

        // Send TestFlight invite email
        try {
            await sendTestFlightInvite(signup, inviteUrl);
        } catch (emailError) {
            console.error('TestFlight invite email failed:', emailError);
            // Update status but don't fail the request
        }

        res.json({
            success: true,
            message: 'TestFlight invite sent successfully',
            data: {
                email: signup.email,
                testflightUrl: inviteUrl,
                sentAt: signup.inviteSentAt
            }
        });

    } catch (error) {
        console.error('Invite error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to send TestFlight invite'
        });
    }
});

// @route   GET /api/beta-signup/pending
// @desc    Get pending beta signups
// @access  Private (Admin only)
router.get('/beta-signup/pending', async (req, res) => {
    try {
        const page = parseInt(req.query.page) || 1;
        const limit = parseInt(req.query.limit) || 50;
        const skip = (page - 1) * limit;

        const signups = await BetaSignup
            .find({ status: 'pending' })
            .sort({ createdAt: -1 })
            .skip(skip)
            .limit(limit)
            .select('-__v');

        const total = await BetaSignup.countDocuments({ status: 'pending' });

        res.json({
            success: true,
            data: {
                signups,
                pagination: {
                    page,
                    limit,
                    total,
                    pages: Math.ceil(total / limit)
                }
            }
        });
    } catch (error) {
        console.error('Pending signups error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to fetch pending signups'
        });
    }
});

// @route   PUT /api/beta-signup/:id/status
// @desc    Update beta signup status
// @access  Private (Admin only)
router.put('/beta-signup/:id/status', async (req, res) => {
    try {
        const { id } = req.params;
        const { status, adminNotes } = req.body;

        const validStatuses = ['pending', 'approved', 'invited', 'installed', 'rejected'];
        if (!validStatuses.includes(status)) {
            return res.status(400).json({
                success: false,
                message: 'Invalid status'
            });
        }

        const signup = await BetaSignup.findByIdAndUpdate(
            id,
            {
                status,
                adminNotes,
                updatedAt: new Date()
            },
            { new: true }
        );

        if (!signup) {
            return res.status(404).json({
                success: false,
                message: 'Beta signup not found'
            });
        }

        res.json({
            success: true,
            message: `Status updated to ${status}`,
            data: signup
        });

    } catch (error) {
        console.error('Status update error:', error);
        res.status(500).json({
            success: false,
            message: 'Failed to update status'
        });
    }
});

module.exports = router;

