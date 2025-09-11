#!/bin/bash

# BahnBlitz - Google Cloud Platform Deployment Script
# Deploys both backend and website to GCP

set -e

# ================================
# Configuration
# ================================
PROJECT_ID="${PROJECT_ID:-your-gcp-project-id}"
REGION="${REGION:-europe-west1}"
SERVICE_NAME_BACKEND="bahnblitz-backend"
SERVICE_NAME_WEBSITE="bahnblitz-website"
IMAGE_TAG="${IMAGE_TAG:-latest}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

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

check_dependencies() {
    log_info "Checking dependencies..."

    if ! command -v gcloud &> /dev/null; then
        log_error "gcloud CLI is not installed. Please install it first."
        log_error "Visit: https://cloud.google.com/sdk/docs/install"
        exit 1
    fi

    if ! command -v docker &> /dev/null; then
        log_error "Docker is not installed. Please install it first."
        exit 1
    fi

    log_success "All dependencies are installed"
}

setup_gcp_project() {
    log_info "Setting up GCP project: $PROJECT_ID"

    # Set the project
    gcloud config set project $PROJECT_ID

    # Enable required APIs
    log_info "Enabling required GCP APIs..."
    gcloud services enable cloudbuild.googleapis.com
    gcloud services enable run.googleapis.com
    gcloud services enable firestore.googleapis.com
    gcloud services enable secretmanager.googleapis.com

    log_success "GCP project setup complete"
}

build_and_push_backend() {
    log_info "Building and pushing backend image..."

    cd backend

    # Build the Docker image
    docker build -t gcr.io/$PROJECT_ID/$SERVICE_NAME_BACKEND:$IMAGE_TAG .

    # Configure Docker to use gcloud as a credential helper
    gcloud auth configure-docker --quiet

    # Push the image to GCR
    docker push gcr.io/$PROJECT_ID/$SERVICE_NAME_BACKEND:$IMAGE_TAG

    cd ..
    log_success "Backend image pushed to GCR"
}

build_and_push_website() {
    log_info "Building and pushing website image..."

    cd website

    # Build the Docker image
    docker build -t gcr.io/$PROJECT_ID/$SERVICE_NAME_WEBSITE:$IMAGE_TAG .

    # Push the image to GCR
    docker push gcr.io/$PROJECT_ID/$SERVICE_NAME_WEBSITE:$IMAGE_TAG

    cd ..
    log_success "Website image pushed to GCR"
}

deploy_backend() {
    log_info "Deploying backend to Cloud Run..."

    # Deploy to Cloud Run
    gcloud run deploy $SERVICE_NAME_BACKEND \
        --image gcr.io/$PROJECT_ID/$SERVICE_NAME_BACKEND:$IMAGE_TAG \
        --platform managed \
        --region $REGION \
        --allow-unauthenticated \
        --port 3001 \
        --memory 1Gi \
        --cpu 1 \
        --max-instances 10 \
        --timeout 300 \
        --concurrency 80 \
        --set-env-vars "NODE_ENV=production" \
        --set-secrets "MONGODB_URI=mongodb-connection-string:latest" \
        --set-secrets "TESTFLIGHT_URL=testflight-url:latest" \
        --set-secrets "EMAIL_CONFIG=email-config:latest"

    # Get the backend URL
    BACKEND_URL=$(gcloud run services describe $SERVICE_NAME_BACKEND --region=$REGION --format="value(status.url)")

    log_success "Backend deployed to: $BACKEND_URL"
}

deploy_website() {
    log_info "Deploying website to Cloud Run..."

    # Deploy to Cloud Run
    gcloud run deploy $SERVICE_NAME_WEBSITE \
        --image gcr.io/$PROJECT_ID/$SERVICE_NAME_WEBSITE:$IMAGE_TAG \
        --platform managed \
        --region $REGION \
        --allow-unauthenticated \
        --port 8080 \
        --memory 512Mi \
        --cpu 1 \
        --max-instances 10 \
        --timeout 300 \
        --concurrency 100 \
        --set-env-vars "NODE_ENV=production"

    # Get the website URL
    WEBSITE_URL=$(gcloud run services describe $SERVICE_NAME_WEBSITE --region=$REGION --format="value(status.url)")

    log_success "Website deployed to: $WEBSITE_URL"
}

setup_secrets() {
    log_info "Setting up GCP Secret Manager secrets..."

    # MongoDB Connection String
    echo -n "Enter your MongoDB connection string: "
    read -s MONGODB_URI
    echo
    echo $MONGODB_URI | gcloud secrets create mongodb-connection-string --data-file=-

    # TestFlight URL
    echo -n "Enter your TestFlight public URL: "
    read TESTFLIGHT_URL
    echo $TESTFLIGHT_URL | gcloud secrets create testflight-url --data-file=-

    # Email configuration (JSON format)
    cat > /tmp/email-config.json << EOF
{
  "gmail_user": "your-email@gmail.com",
  "gmail_app_password": "your-app-password",
  "smtp_host": "smtp.gmail.com",
  "smtp_port": "587"
}
EOF

    gcloud secrets create email-config --data-file=/tmp/email-config.json
    rm /tmp/email-config.json

    log_success "Secrets created in GCP Secret Manager"
}

setup_firestore() {
    log_info "Setting up Firestore database..."

    # Create Firestore database in native mode
    gcloud firestore databases create --region=$REGION

    log_success "Firestore database created"
}

update_website_config() {
    log_info "Updating website configuration with backend URL..."

    # Get backend URL
    BACKEND_URL=$(gcloud run services describe $SERVICE_NAME_BACKEND --region=$REGION --format="value(status.url)")

    # Update the website's JavaScript to use the production backend URL
    sed -i "s|https://your-backend-domain.com|$BACKEND_URL|g" website/assets/js/main.js

    log_success "Website configuration updated with backend URL: $BACKEND_URL"
}

cleanup() {
    log_info "Cleaning up temporary files..."

    # Remove any temporary files created during deployment
    rm -f /tmp/email-config.json 2>/dev/null || true

    log_success "Cleanup complete"
}

# ================================
# Main Deployment Flow
# ================================

main() {
    echo "🚂 BahnBlitz - GCP Deployment Script"
    echo "===================================="
    echo

    # Check if this is the first deployment
    if [ "$1" = "--first-deploy" ]; then
        log_info "First deployment detected. Setting up GCP project..."
        check_dependencies
        setup_gcp_project
        setup_secrets
        setup_firestore
    else
        check_dependencies
    fi

    # Build and deploy
    build_and_push_backend
    build_and_push_website
    deploy_backend
    deploy_website
    update_website_config
    cleanup

    echo
    log_success "🎉 Deployment complete!"
    echo
    echo "Your BahnBlitz services are now live:"
    echo "- Backend API: $(gcloud run services describe $SERVICE_NAME_BACKEND --region=$REGION --format="value(status.url)")"
    echo "- Website: $(gcloud run services describe $SERVICE_NAME_WEBSITE --region=$REGION --format="value(status.url)")"
    echo
    echo "Don't forget to:"
    echo "1. Update your DNS to point to the website URL"
    echo "2. Configure your TestFlight public link"
    echo "3. Set up monitoring and alerts in GCP Console"
}

# ================================
# Script Execution
# ================================

# Show usage if requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  --first-deploy    Set up GCP project and secrets for first deployment"
    echo "  --help, -h        Show this help message"
    echo
    echo "Environment Variables:"
    echo "  PROJECT_ID        Your GCP project ID (required)"
    echo "  REGION           GCP region (default: europe-west1)"
    echo "  IMAGE_TAG        Docker image tag (default: latest)"
    echo
    exit 0
fi

# Run main deployment
main "$@"
