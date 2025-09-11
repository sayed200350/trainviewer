#!/bin/bash

# BahnBlitz - GCP Infrastructure Setup Script
# Sets up all necessary GCP resources for deployment

set -e

# ================================
# Configuration
# ================================
PROJECT_ID="${PROJECT_ID:-your-gcp-project-id}"
REGION="${REGION:-europe-west1}"
SERVICE_ACCOUNT_NAME="bahnblitz-deployer"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# ================================
# Functions
# ================================

log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_gcloud_auth() {
    log_info "Checking GCP authentication..."

    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
        log_error "You are not authenticated with GCP. Please run:"
        log_error "gcloud auth login"
        exit 1
    fi

    log_success "GCP authentication confirmed"
}

create_service_account() {
    log_info "Creating service account for deployments..."

    # Create service account
    gcloud iam service-accounts create $SERVICE_ACCOUNT_NAME \
        --description="Service account for BahnBlitz deployments" \
        --display-name="BahnBlitz Deployer"

    # Grant necessary permissions
    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="roles/cloudbuild.builds.builder"

    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="roles/run.admin"

    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="roles/secretmanager.secretAccessor"

    gcloud projects add-iam-policy-binding $PROJECT_ID \
        --member="serviceAccount:$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com" \
        --role="roles/storage.admin"

    # Create and download key
    gcloud iam service-accounts keys create ~/bahnblitz-service-account-key.json \
        --iam-account=$SERVICE_ACCOUNT_NAME@$PROJECT_ID.iam.gserviceaccount.com

    log_success "Service account created and key downloaded to ~/bahnblitz-service-account-key.json"
    log_warning "Keep this key file secure and never commit it to version control!"
}

setup_apis() {
    log_info "Enabling required GCP APIs..."

    # List of required APIs
    apis=(
        "cloudbuild.googleapis.com"
        "run.googleapis.com"
        "firestore.googleapis.com"
        "secretmanager.googleapis.com"
        "containerregistry.googleapis.com"
        "cloudresourcemanager.googleapis.com"
        "iam.googleapis.com"
        "serviceusage.googleapis.com"
    )

    for api in "${apis[@]}"; do
        log_info "Enabling $api..."
        gcloud services enable $api --project=$PROJECT_ID
    done

    log_success "All required APIs enabled"
}

setup_firestore() {
    log_info "Setting up Firestore database..."

    # Create Firestore database
    gcloud firestore databases create \
        --project=$PROJECT_ID \
        --region=$REGION

    log_success "Firestore database created"
}

setup_container_registry() {
    log_info "Setting up Container Registry..."

    # Create a storage bucket for Container Registry (if not exists)
    BUCKET_NAME=$PROJECT_ID"_cloudbuild"

    if ! gsutil ls -b gs://$BUCKET_NAME >/dev/null 2>&1; then
        gsutil mb -p $PROJECT_ID gs://$BUCKET_NAME
        log_success "Container Registry bucket created"
    else
        log_info "Container Registry bucket already exists"
    fi
}

setup_secrets() {
    log_info "Setting up Secret Manager secrets..."

    # Create placeholder secrets (will be updated with real values later)
    secrets=(
        "mongodb-connection-string"
        "testflight-url"
        "email-config"
        "jwt-secret"
    )

    for secret in "${secrets[@]}"; do
        if ! gcloud secrets describe $secret --project=$PROJECT_ID >/dev/null 2>&1; then
            echo "placeholder-value" | gcloud secrets create $secret \
                --project=$PROJECT_ID \
                --data-file=-
            log_info "Created secret: $secret"
        else
            log_info "Secret already exists: $secret"
        fi
    done

    log_success "Secret Manager setup complete"
}

setup_cloud_build() {
    log_info "Setting up Cloud Build triggers..."

    # Create Cloud Build trigger for main branch
    gcloud beta builds triggers create github \
        --project=$PROJECT_ID \
        --name="bahnblitz-deploy-main" \
        --repo-name="bahnblitz" \
        --repo-owner="your-github-username" \
        --branch-pattern="^main$" \
        --build-config="cloudbuild.yaml" \
        --substitutions="_REGION=$REGION"

    log_success "Cloud Build trigger created"
}

setup_monitoring() {
    log_info "Setting up Cloud Monitoring alerts..."

    # Create uptime checks for both services
    gcloud monitoring uptime-check-configs create bahnblitz-backend-check \
        --project=$PROJECT_ID \
        --display-name="BahnBlitz Backend Uptime Check" \
        --resource-type=uptime-url \
        --http-check-path="/health" \
        --timeout=10 \
        --period=300 \
        --selected-regions=$REGION

    gcloud monitoring uptime-check-configs create bahnblitz-website-check \
        --project=$PROJECT_ID \
        --display-name="BahnBlitz Website Uptime Check" \
        --resource-type=uptime-url \
        --http-check-path="/health" \
        --timeout=10 \
        --period=300 \
        --selected-regions=$REGION

    log_success "Monitoring setup complete"
}

create_env_template() {
    log_info "Creating environment configuration template..."

    cat > backend/.env.gcp << EOF
# BahnBlitz Backend - GCP Environment Configuration
# Copy this to .env and update with your values

# Server Configuration
NODE_ENV=production
PORT=3001

# GCP Project
GCP_PROJECT_ID=$PROJECT_ID
GCP_REGION=$REGION

# Database (Firestore)
FIRESTORE_PROJECT_ID=$PROJECT_ID

# Email Configuration (Gmail for development)
GMAIL_USER=your-email@gmail.com
GMAIL_APP_PASSWORD=your-app-password

# Email Configuration (SendGrid for production)
SMTP_HOST=smtp.sendgrid.net
SMTP_PORT=587
SMTP_SECURE=false
SMTP_USER=apikey
SMTP_PASS=your-sendgrid-api-key
EMAIL_FROM=noreply@bahnblitz.app

# TestFlight Configuration
TESTFLIGHT_URL=https://testflight.apple.com/join/YOUR_APP_ID
TESTFLIGHT_PUBLIC_URL=https://testflight.apple.com/join/YOUR_PUBLIC_LINK

# Security
JWT_SECRET=your-super-secret-jwt-key-here
JWT_EXPIRE=30d

# API Keys (store in Secret Manager)
MONGODB_URI=gs://your-secrets-bucket/mongodb-connection
TESTFLIGHT_URL_SECRET=projects/$PROJECT_ID/secrets/testflight-url/versions/latest
EMAIL_CONFIG_SECRET=projects/$PROJECT_ID/secrets/email-config/versions/latest

# Monitoring
SENTRY_DSN=your-sentry-dsn-here
GOOGLE_ANALYTICS_ID=GA_MEASUREMENT_ID

# File Upload (if needed)
CLOUD_STORAGE_BUCKET=$PROJECT_ID-bahnblitz-uploads
EOF

    log_success "Environment template created at backend/.env.gcp"
}

show_next_steps() {
    echo
    log_success "🎉 GCP Infrastructure Setup Complete!"
    echo
    echo "Next Steps:"
    echo "1. 📝 Update secrets in GCP Secret Manager:"
    echo "   - mongodb-connection-string"
    echo "   - testflight-url"
    echo "   - email-config"
    echo "   - jwt-secret"
    echo
    echo "2. 🔧 Configure your environment:"
    echo "   cp backend/.env.gcp backend/.env"
    echo "   # Edit backend/.env with your actual values"
    echo
    echo "3. 🚀 Deploy your application:"
    echo "   chmod +x gcp-deploy.sh"
    echo "   ./gcp-deploy.sh --first-deploy"
    echo
    echo "4. 🌐 Set up custom domain (optional):"
    echo "   gcloud run domain-mappings create --service=bahnblitz-website --domain=bahnblitz.app"
    echo
    echo "5. 📊 Set up monitoring and alerts in GCP Console"
    echo
    echo "Service URLs after deployment:"
    echo "- Backend API: https://bahnblitz-backend-[hash]-ew.a.run.app"
    echo "- Website: https://bahnblitz-website-[hash]-ew.a.run.app"
    echo
}

# ================================
# Main Setup Flow
# ================================

main() {
    echo "🚂 BahnBlitz - GCP Infrastructure Setup"
    echo "======================================="
    echo

    # Check prerequisites
    check_gcloud_auth

    # Set GCP project
    gcloud config set project $PROJECT_ID

    # Run setup steps
    setup_apis
    create_service_account
    setup_firestore
    setup_container_registry
    setup_secrets
    setup_cloud_build
    setup_monitoring
    create_env_template

    # Show completion message
    show_next_steps
}

# ================================
# Script Execution
# ================================

# Show usage if requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0"
    echo
    echo "This script sets up the complete GCP infrastructure for BahnBlitz."
    echo
    echo "Prerequisites:"
    echo "- gcloud CLI installed and authenticated"
    echo "- GitHub repository connected to Cloud Build (optional)"
    echo
    echo "Required Environment Variables:"
    echo "  PROJECT_ID        Your GCP project ID"
    echo "  REGION           GCP region (default: europe-west1)"
    echo
    exit 0
fi

# Run main setup
main "$@"
