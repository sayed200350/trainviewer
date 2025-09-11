/**
 * BahnBlitz Beta Website - Main JavaScript
 * Handles form submission, cookie consent, and interactive elements
 */

// DOM Content Loaded
document.addEventListener('DOMContentLoaded', function() {
    initializeForm();
    initializeCookieBanner();
    initializeScrollEffects();
    initializeAnimations();
});

// Form Handling
function initializeForm() {
    const form = document.getElementById('betaForm');
    if (!form) return;

    form.addEventListener('submit', handleFormSubmission);
}

// Form Submission Handler
async function handleFormSubmission(event) {
    event.preventDefault();

    const form = event.target;
    const submitBtn = form.querySelector('.btn-primary');
    const btnText = submitBtn.querySelector('.btn-text');
    const btnLoading = submitBtn.querySelector('.btn-loading');

    // Show loading state
    submitBtn.disabled = true;
    btnText.style.display = 'none';
    btnLoading.style.display = 'flex';

    try {
        // Collect form data
        const formData = new FormData(form);
        const data = {
            email: formData.get('email'),
            name: formData.get('name'),
            device: formData.get('device'),
            experience: formData.get('experience'),
            features: formData.getAll('features[]'),
            privacy: formData.get('privacy'),
            timestamp: new Date().toISOString(),
            userAgent: navigator.userAgent,
            source: 'website_beta_signup'
        };

        // Validate required fields
        if (!validateForm(data)) {
            throw new Error('Please fill in all required fields');
        }

        // Simulate API call (replace with actual endpoint)
        await submitBetaSignup(data);

        // Show success message
        showSuccessMessage();

        // Track conversion
        trackConversion('beta_signup', data);

    } catch (error) {
        console.error('Form submission error:', error);
        showErrorMessage(error.message);
    } finally {
        // Reset loading state
        submitBtn.disabled = false;
        btnText.style.display = 'flex';
        btnLoading.style.display = 'none';
    }
}

// Form Validation
function validateForm(data) {
    const requiredFields = ['email', 'name', 'device'];
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

    // Check required fields
    for (const field of requiredFields) {
        if (!data[field] || data[field].trim() === '') {
            return false;
        }
    }

    // Validate email format
    if (!emailRegex.test(data.email)) {
        return false;
    }

    // Check privacy consent
    if (!data.privacy) {
        return false;
    }

    return true;
}

// Submit Beta Signup (Production API)
async function submitBetaSignup(data) {
    try {
        const response = await fetch('https://your-backend-domain.com/api/beta-signup', {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer YOUR_API_KEY' // Replace with actual key
            },
            body: JSON.stringify(data)
        });

        if (!response.ok) {
            throw new Error('Failed to submit signup');
        }

        const result = await response.json();

        // Track successful signup
        if (result.testflightUrl) {
            trackConversion('testflight_invite_sent', data);
        }

        return result;
    } catch (error) {
        console.error('API Error:', error);
        throw new Error('Signup service temporarily unavailable. Please try again later.');
    }
}

// Success Message
function showSuccessMessage() {
    const form = document.getElementById('betaForm');
    const successMessage = document.getElementById('successMessage');

    form.style.display = 'none';
    successMessage.style.display = 'block';

    // Scroll to success message
    successMessage.scrollIntoView({ behavior: 'smooth', block: 'center' });
}

// Error Message
function showErrorMessage(message) {
    // Create error notification
    const notification = document.createElement('div');
    notification.className = 'error-notification';
    notification.innerHTML = `
        <div class="error-content">
            <span class="error-icon">⚠️</span>
            <span class="error-text">${message}</span>
            <button class="error-close" onclick="this.parentElement.parentElement.remove()">×</button>
        </div>
    `;

    // Add styles for error notification
    notification.style.cssText = `
        position: fixed;
        top: 20px;
        right: 20px;
        background: #ef4444;
        color: white;
        padding: 16px;
        border-radius: 8px;
        box-shadow: 0 10px 25px rgba(0,0,0,0.3);
        z-index: 1002;
        max-width: 400px;
        animation: slideIn 0.3s ease-out;
    `;

    document.body.appendChild(notification);

    // Auto-remove after 5 seconds
    setTimeout(() => {
        if (notification.parentElement) {
            notification.remove();
        }
    }, 5000);
}

// Reset Form
function resetForm() {
    const form = document.getElementById('betaForm');
    const successMessage = document.getElementById('successMessage');

    form.reset();
    form.style.display = 'block';
    successMessage.style.display = 'none';

    // Scroll back to form
    form.scrollIntoView({ behavior: 'smooth', block: 'center' });
}

// Cookie Banner
function initializeCookieBanner() {
    const banner = document.getElementById('cookieBanner');
    if (!banner) return;

    // Check if user has already made a choice
    const cookieConsent = localStorage.getItem('bahnblitz_cookie_consent');

    if (!cookieConsent) {
        // Show banner after 2 seconds
        setTimeout(() => {
            banner.classList.add('show');
        }, 2000);
    } else if (cookieConsent === 'accepted') {
        // Initialize analytics if accepted
        initializeAnalytics();
    }
}

// Accept Cookies
function acceptCookies() {
    localStorage.setItem('bahnblitz_cookie_consent', 'accepted');
    document.getElementById('cookieBanner').classList.remove('show');
    initializeAnalytics();

    // Track cookie acceptance
    trackEvent('cookie_consent', 'accepted');
}

// Decline Cookies
function declineCookies() {
    localStorage.setItem('bahnblitz_cookie_consent', 'declined');
    document.getElementById('cookieBanner').classList.remove('show');

    // Track cookie decline
    trackEvent('cookie_consent', 'declined');
}

// Analytics Initialization
function initializeAnalytics() {
    // Google Analytics 4 - Replace with your GA4 ID
    /*
    (function() {
        var script = document.createElement('script');
        script.async = true;
        script.src = 'https://www.googletagmanager.com/gtag/js?id=GA_MEASUREMENT_ID';
        document.head.appendChild(script);

        window.dataLayer = window.dataLayer || [];
        function gtag(){dataLayer.push(arguments);}
        gtag('js', new Date());
        gtag('config', 'GA_MEASUREMENT_ID');
    })();
    */

    console.log('Analytics initialized');
}

// Event Tracking
function trackEvent(eventName, eventValue) {
    // Google Analytics event
    if (window.gtag) {
        gtag('event', eventName, {
            value: eventValue,
            custom_parameter: 'bahnblitz_beta'
        });
    }

    // Custom tracking
    console.log(`Event tracked: ${eventName} = ${eventValue}`);
}

// Conversion Tracking
function trackConversion(conversionType, data) {
    trackEvent('conversion', conversionType);

    // Facebook Pixel (if implemented)
    /*
    if (window.fbq) {
        fbq('track', 'Lead', {
            content_name: 'BahnBlitz Beta Signup',
            content_category: 'Beta Testing'
        });
    }
    */

    console.log(`Conversion tracked: ${conversionType}`, data);
}

// Scroll Effects
function initializeScrollEffects() {
    const observerOptions = {
        threshold: 0.1,
        rootMargin: '0px 0px -50px 0px'
    };

    const observer = new IntersectionObserver((entries) => {
        entries.forEach(entry => {
            if (entry.isIntersecting) {
                entry.target.classList.add('animate-in');
            }
        });
    }, observerOptions);

    // Observe elements for animation
    document.querySelectorAll('.feature-card, .testimonial, .faq-item').forEach(el => {
        observer.observe(el);
    });
}

// Initialize Animations
function initializeAnimations() {
    // Add CSS for scroll animations
    const style = document.createElement('style');
    style.textContent = `
        .feature-card, .testimonial, .faq-item {
            opacity: 0;
            transform: translateY(30px);
            transition: opacity 0.6s ease, transform 0.6s ease;
        }

        .feature-card.animate-in, .testimonial.animate-in, .faq-item.animate-in {
            opacity: 1;
            transform: translateY(0);
        }

        @keyframes slideIn {
            from {
                transform: translateX(100%);
                opacity: 0;
            }
            to {
                transform: translateX(0);
                opacity: 1;
            }
        }
    `;
    document.head.appendChild(style);
}

// Smooth scrolling for navigation links
document.addEventListener('click', function(e) {
    if (e.target.classList.contains('nav-link')) {
        e.preventDefault();
        const targetId = e.target.getAttribute('href');
        const targetElement = document.querySelector(targetId);

        if (targetElement) {
            targetElement.scrollIntoView({
                behavior: 'smooth',
                block: 'start'
            });

            // Update active nav link
            document.querySelectorAll('.nav-link').forEach(link => {
                link.classList.remove('active');
            });
            e.target.classList.add('active');
        }
    }
});

// Mobile menu toggle (if needed in future)
function toggleMobileMenu() {
    const navLinks = document.querySelector('.nav-links');
    navLinks.classList.toggle('mobile-menu-open');
}

// Performance monitoring
function initializePerformanceMonitoring() {
    // Monitor Core Web Vitals
    if ('web-vitals' in window) {
        import('https://unpkg.com/web-vitals@3?module')
            .then(({ getCLS, getFID, getFCP, getLCP, getTTFB }) => {
                getCLS(trackWebVital);
                getFID(trackWebVital);
                getFCP(trackWebVital);
                getLCP(trackWebVital);
                getTTFB(trackWebVital);
            });
    }
}

function trackWebVital({ name, value, id }) {
    // Send to analytics
    trackEvent('web_vital', {
        name,
        value: Math.round(value),
        id
    });

    console.log(`${name}: ${value} (${id})`);
}

// Initialize performance monitoring
if (document.readyState === 'complete') {
    initializePerformanceMonitoring();
} else {
    window.addEventListener('load', initializePerformanceMonitoring);
}

// Error handling
window.addEventListener('error', function(e) {
    console.error('JavaScript error:', e.error);
    trackEvent('javascript_error', {
        message: e.message,
        filename: e.filename,
        lineno: e.lineno,
        colno: e.colno
    });
});

// Unhandled promise rejections
window.addEventListener('unhandledrejection', function(e) {
    console.error('Unhandled promise rejection:', e.reason);
    trackEvent('unhandled_rejection', {
        reason: e.reason?.toString()
    });
});

// Service Worker registration (for PWA features if needed)
if ('serviceWorker' in navigator) {
    window.addEventListener('load', function() {
        // navigator.serviceWorker.register('/sw.js')
        //     .then(registration => console.log('SW registered'))
        //     .catch(error => console.log('SW registration failed'));
    });
}

// Accessibility improvements
function initializeAccessibility() {
    // Skip to main content link (add to HTML if needed)
    // Keyboard navigation improvements
    // Focus management for modals
}

// Initialize accessibility features
initializeAccessibility();

// Export functions for global access (if needed)
window.resetForm = resetForm;
window.acceptCookies = acceptCookies;
window.declineCookies = declineCookies;
