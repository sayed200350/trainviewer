#!/usr/bin/env node

/**
 * BahnBlitz Backend Deployment Script
 * Handles deployment to various platforms
 */

const { execSync } = require('child_process');
const fs = require('fs');
const path = require('path');

class Deployer {
    constructor() {
        this.platform = process.argv[2] || 'render';
        this.env = process.env.NODE_ENV || 'production';
    }

    async deploy() {
        console.log(`🚀 Starting deployment to ${this.platform}...`);

        try {
            switch (this.platform) {
                case 'render':
                    await this.deployToRender();
                    break;
                case 'heroku':
                    await this.deployToHeroku();
                    break;
                case 'railway':
                    await this.deployToRailway();
                    break;
                case 'vercel':
                    await this.deployToVercel();
                    break;
                default:
                    throw new Error(`Unsupported platform: ${this.platform}`);
            }

            console.log('✅ Deployment completed successfully!');
        } catch (error) {
            console.error('❌ Deployment failed:', error.message);
            process.exit(1);
        }
    }

    async deployToRender() {
        console.log('📦 Deploying to Render...');

        // Check if render.yaml exists
        if (!fs.existsSync('render.yaml')) {
            this.createRenderConfig();
        }

        // Build and deploy
        execSync('npm run build', { stdio: 'inherit' });
        execSync('git add . && git commit -m "Deploy to Render"', { stdio: 'inherit' });
        execSync('git push render main', { stdio: 'inherit' });

        console.log('🎉 Render deployment complete!');
        console.log('📊 Check your Render dashboard for deployment status');
    }

    async deployToHeroku() {
        console.log('📦 Deploying to Heroku...');

        // Check if Procfile exists
        if (!fs.existsSync('Procfile')) {
            fs.writeFileSync('Procfile', 'web: npm start\n');
        }

        // Build and deploy
        execSync('heroku create bahnblitz-backend --region eu', { stdio: 'inherit' });
        execSync('git push heroku main', { stdio: 'inherit' });

        console.log('🎉 Heroku deployment complete!');
    }

    async deployToRailway() {
        console.log('📦 Deploying to Railway...');

        // Install Railway CLI if not present
        try {
            execSync('railway --version', { stdio: 'pipe' });
        } catch {
            console.log('Installing Railway CLI...');
            execSync('npm install -g @railway/cli', { stdio: 'inherit' });
        }

        // Login and deploy
        execSync('railway login', { stdio: 'inherit' });
        execSync('railway init', { stdio: 'inherit' });
        execSync('railway up', { stdio: 'inherit' });

        console.log('🎉 Railway deployment complete!');
    }

    async deployToVercel() {
        console.log('📦 Deploying to Vercel...');

        // Install Vercel CLI if not present
        try {
            execSync('vercel --version', { stdio: 'pipe' });
        } catch {
            console.log('Installing Vercel CLI...');
            execSync('npm install -g vercel', { stdio: 'inherit' });
        }

        // Deploy
        execSync('vercel --prod', { stdio: 'inherit' });

        console.log('🎉 Vercel deployment complete!');
    }

    createRenderConfig() {
        const renderConfig = {
            services: [
                {
                    type: 'web',
                    name: 'bahnblitz-backend',
                    runtime: 'node',
                    buildCommand: 'npm install',
                    startCommand: 'npm start',
                    envVars: [
                        { key: 'NODE_ENV', value: 'production' },
                        { key: 'PORT', generateValue: true }
                    ]
                }
            ]
        };

        fs.writeFileSync('render.yaml', JSON.stringify(renderConfig, null, 2));
        console.log('📝 Created render.yaml configuration');
    }

    createVercelConfig() {
        const vercelConfig = {
            version: 2,
            builds: [
                {
                    src: 'src/server.js',
                    use: '@vercel/node'
                }
            ],
            routes: [
                {
                    src: '/(.*)',
                    dest: 'src/server.js'
                }
            ]
        };

        fs.writeFileSync('vercel.json', JSON.stringify(vercelConfig, null, 2));
        console.log('📝 Created vercel.json configuration');
    }

    preDeployChecks() {
        console.log('🔍 Running pre-deployment checks...');

        // Check if .env exists
        if (!fs.existsSync('.env')) {
            console.warn('⚠️  .env file not found. Make sure to set environment variables in your deployment platform.');
        }

        // Check package.json
        const packageJson = JSON.parse(fs.readFileSync('package.json', 'utf8'));
        if (!packageJson.scripts.start) {
            throw new Error('No start script defined in package.json');
        }

        // Check main server file
        if (!fs.existsSync('src/server.js')) {
            throw new Error('src/server.js not found');
        }

        console.log('✅ Pre-deployment checks passed');
    }
}

// CLI usage
if (require.main === module) {
    const deployer = new Deployer();

    console.log(`
🚂 BahnBlitz Backend Deployment Tool
====================================

Usage: node scripts/deploy.js [platform]

Platforms:
  - render (default)
  - heroku
  - railway
  - vercel

Examples:
  node scripts/deploy.js render
  node scripts/deploy.js heroku
  node scripts/deploy.js railway

Environment Variables Required:
  - MONGODB_URI
  - TESTFLIGHT_URL
  - Email credentials (GMAIL or SMTP)

Make sure your .env file is configured before deploying!
    `);

    deployer.deploy();
}

module.exports = Deployer;

