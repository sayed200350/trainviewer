// TestFlight service for managing beta invites and codes

/**
 * Generate a unique TestFlight invite code
 * @returns {string} 6-character alphanumeric code
 */
const generateTestFlightCode = () => {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    let code = '';
    for (let i = 0; i < 6; i++) {
        code += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return code;
};

/**
 * Validate TestFlight URL format
 * @param {string} url - TestFlight URL to validate
 * @returns {boolean} True if valid TestFlight URL
 */
const validateTestFlightUrl = (url) => {
    const testflightRegex = /^https:\/\/testflight\.apple\.com\/join\/[a-zA-Z0-9]+$/;
    return testflightRegex.test(url);
};

/**
 * Get TestFlight public link from app ID
 * @param {string} appId - App Store Connect app ID
 * @returns {string} Public TestFlight link
 */
const getTestFlightPublicLink = (appId) => {
    // This would be your actual TestFlight public link
    // You get this from App Store Connect > TestFlight > Public Link
    return process.env.TESTFLIGHT_PUBLIC_URL || `https://testflight.apple.com/join/${appId}`;
};

/**
 * Check if user is eligible for TestFlight invite
 * @param {Object} signup - Beta signup object
 * @returns {Object} Eligibility result
 */
const checkEligibility = (signup) => {
    const result = {
        eligible: false,
        reason: '',
        priority: 'normal'
    };

    // Check device compatibility
    const compatibleDevices = ['iphone', 'ipad', 'ipod'];
    if (!compatibleDevices.includes(signup.device)) {
        result.reason = 'Device not compatible with TestFlight';
        return result;
    }

    // Check if user has iOS device (TestFlight requires iOS)
    if (!['iphone', 'ipad', 'ipod'].includes(signup.device)) {
        result.reason = 'TestFlight requires iOS device';
        return result;
    }

    // Check signup date (prefer newer signups for initial batch)
    const daysSinceSignup = Math.floor((Date.now() - signup.createdAt) / (1000 * 60 * 60 * 24));

    // Prioritize based on various factors
    if (signup.experience === 'daily' || signup.experience === 'weekly') {
        result.priority = 'high';
    } else if (signup.features && signup.features.includes('siri')) {
        result.priority = 'high'; // Interested in voice features
    } else if (daysSinceSignup < 7) {
        result.priority = 'medium'; // Recent signup
    }

    result.eligible = true;
    return result;
};

/**
 * Generate batch of TestFlight invite codes
 * @param {number} count - Number of codes to generate
 * @returns {string[]} Array of unique codes
 */
const generateBatchCodes = (count) => {
    const codes = new Set();

    while (codes.size < count) {
        const code = generateTestFlightCode();
        codes.add(code);
    }

    return Array.from(codes);
};

/**
 * Create TestFlight invite link with custom code
 * @param {string} baseUrl - Base TestFlight URL
 * @param {string} code - Custom invite code
 * @returns {string} Full invite URL
 */
const createInviteLink = (baseUrl, code) => {
    // TestFlight doesn't support custom codes in URLs
    // The code is just for internal tracking
    return baseUrl;
};

/**
 * Track TestFlight invite metrics
 * @param {Object} signup - Beta signup object
 * @param {string} inviteUrl - TestFlight URL sent
 */
const trackInviteMetrics = async (signup, inviteUrl) => {
    // This would integrate with your analytics system
    console.log(`TestFlight invite sent to ${signup.email}`);
    console.log(`Invite URL: ${inviteUrl}`);
    console.log(`User device: ${signup.device}`);
    console.log(`Signup date: ${signup.createdAt}`);
    console.log(`Priority: ${checkEligibility(signup).priority}`);

    // In production, you'd send this to your analytics service
    // Example: Mixpanel, Google Analytics, or custom analytics
};

/**
 * Send bulk TestFlight invites to approved users
 * @param {Array} signups - Array of approved beta signups
 * @param {string} testflightUrl - TestFlight public URL
 * @returns {Object} Results of bulk invite operation
 */
const sendBulkInvites = async (signups, testflightUrl) => {
    const results = {
        successful: [],
        failed: [],
        total: signups.length
    };

    for (const signup of signups) {
        try {
            const eligibility = checkEligibility(signup);

            if (!eligibility.eligible) {
                results.failed.push({
                    email: signup.email,
                    reason: eligibility.reason
                });
                continue;
            }

            // Generate unique code for tracking
            const inviteCode = generateTestFlightCode();
            const inviteUrl = createInviteLink(testflightUrl, inviteCode);

            // Mark as invited
            await signup.markAsInvited(inviteUrl, inviteCode);

            // Track metrics
            await trackInviteMetrics(signup, inviteUrl);

            results.successful.push({
                email: signup.email,
                inviteUrl,
                inviteCode,
                priority: eligibility.priority
            });

        } catch (error) {
            console.error(`Failed to process invite for ${signup.email}:`, error);
            results.failed.push({
                email: signup.email,
                reason: error.message
            });
        }
    }

    return results;
};

/**
 * Get TestFlight invite statistics
 * @returns {Object} Invite statistics
 */
const getInviteStats = async () => {
    // This would query your database for invite statistics
    // Example implementation:
    const stats = {
        totalInvitesSent: 150,
        totalInstalls: 89,
        conversionRate: '59.3%',
        topDevices: {
            iphone: 120,
            ipad: 25,
            ipod: 5
        },
        inviteTimeline: [
            { date: '2024-01-01', invites: 25 },
            { date: '2024-01-02', invites: 30 },
            // ... more data
        ]
    };

    return stats;
};

module.exports = {
    generateTestFlightCode,
    validateTestFlightUrl,
    getTestFlightPublicLink,
    checkEligibility,
    generateBatchCodes,
    createInviteLink,
    trackInviteMetrics,
    sendBulkInvites,
    getInviteStats
};

