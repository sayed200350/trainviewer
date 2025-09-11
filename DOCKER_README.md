# 🚂 BahnBlitz - Docker Deployment Guide

Complete Docker setup for local development and production deployment to Google Cloud Platform.

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Local Development](#local-development)
- [Production Deployment](#production-deployment)
- [GCP Deployment](#gcp-deployment)
- [Docker Images](#docker-images)
- [Configuration](#configuration)
- [Monitoring & Logging](#monitoring--logging)
- [Troubleshooting](#troubleshooting)

## 🚀 Quick Start

### Prerequisites
- Docker & Docker Compose
- Git
- (Optional) GCP account for cloud deployment

### One-Command Setup
```bash
# Clone repository
git clone https://github.com/your-username/bahnblitz.git
cd bahnblitz

# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Access services
# - Website: http://localhost:8080
# - Backend API: http://localhost:3001
# - MongoDB Admin: http://localhost:8081
```

## 🏠 Local Development

### Development Setup
```bash
# Use development compose file
docker-compose -f docker-compose.dev.yml up -d

# View all running containers
docker ps

# Stop all services
docker-compose -f docker-compose.dev.yml down
```

### Development Features
- **Hot reloading** for backend code changes
- **Live file watching** for website changes
- **Debug ports** exposed (9229 for Node.js debugging)
- **MongoDB Express** web interface for database management
- **Volume mounting** for real-time development

### Development URLs
- **Website**: http://localhost:8080
- **Backend API**: http://localhost:3001
- **API Documentation**: http://localhost:3001/api/docs
- **MongoDB Admin**: http://localhost:8081 (admin/admin123)
- **Backend Debug**: http://localhost:9229 (attach debugger)

## 🏭 Production Deployment

### Production Setup
```bash
# Use production compose file
docker-compose -f docker-compose.prod.yml up -d

# Or use production script
./scripts/deploy-docker.sh
```

### Production Features
- **Optimized images** with multi-stage builds
- **Security hardening** with non-root users
- **Health checks** and graceful shutdown
- **Resource limits** and monitoring
- **SSL/TLS support** ready
- **Load balancing** with Nginx (optional)

## ☁️ GCP Deployment

### First-Time Setup
```bash
# Set your GCP project ID
export PROJECT_ID=your-gcp-project-id

# Run GCP setup script
chmod +x setup-gcp.sh
./setup-gcp.sh
```

### Deploy to GCP
```bash
# Deploy both services to Cloud Run
chmod +x gcp-deploy.sh
./gcp-deploy.sh

# Or trigger Cloud Build manually
gcloud builds submit --config cloudbuild.yaml
```

### GCP Services Used
- **Cloud Run**: Serverless container deployment
- **Container Registry**: Docker image storage
- **Secret Manager**: Secure credential storage
- **Cloud Build**: CI/CD pipeline
- **Firestore**: Database (alternative to MongoDB)
- **Cloud Monitoring**: Performance monitoring

## 🐳 Docker Images

### Backend Image
```dockerfile
# Multi-stage build optimized for production
FROM node:18-alpine AS builder
# Dependencies & build stage

FROM node:18-alpine AS production
# Production runtime with security hardening
```

### Website Image
```dockerfile
FROM nginx:alpine
# Optimized nginx for static file serving
```

### Image Optimization Features
- **Multi-stage builds** to reduce final image size
- **Alpine Linux** base for minimal footprint
- **Security hardening** with non-root users
- **Health checks** for container orchestration
- **Proper labeling** for image management

## ⚙️ Configuration

### Environment Variables

#### Backend (.env)
```env
# Server
NODE_ENV=production
PORT=3001

# Database
MONGODB_URI=mongodb://mongodb:27017/bahnblitz-prod

# Email
GMAIL_USER=your-email@gmail.com
GMAIL_APP_PASSWORD=your-app-password

# TestFlight
TESTFLIGHT_URL=https://testflight.apple.com/join/YOUR_LINK

# Security
JWT_SECRET=your-secret-key
```

#### Website (nginx.conf)
```nginx
# Custom nginx configuration for optimal static file serving
server {
    listen 8080;
    root /usr/share/nginx/html;
    gzip on;
    # Security headers and caching rules
}
```

### Docker Compose Overrides
```yaml
# Override for different environments
version: '3.8'
services:
  backend:
    environment:
      - NODE_ENV=staging
  website:
    environment:
      - API_URL=https://staging-api.example.com
```

## 📊 Monitoring & Logging

### Health Checks
```bash
# Check all service health
docker-compose ps

# View service logs
docker-compose logs backend
docker-compose logs website

# Follow logs in real-time
docker-compose logs -f
```

### Resource Monitoring
```bash
# View resource usage
docker stats

# Check container health
docker inspect bahnblitz-backend | grep -A 10 "Health"
```

### GCP Monitoring
- **Cloud Logging**: Centralized log management
- **Cloud Monitoring**: Performance metrics and alerts
- **Uptime Checks**: Service availability monitoring
- **Error Reporting**: Automatic error tracking

## 🔧 Troubleshooting

### Common Issues

#### Port Conflicts
```bash
# Check what's using ports
lsof -i :3001
lsof -i :8080

# Change ports in docker-compose.yml
ports:
  - "3002:3001"  # Host:Container
```

#### Permission Issues
```bash
# Fix file permissions
sudo chown -R $USER:$USER .

# Or run with proper user
docker-compose up --user $(id -u):$(id -g)
```

#### Database Connection Issues
```bash
# Check MongoDB logs
docker-compose logs mongodb

# Connect to MongoDB container
docker exec -it bahnblitz-mongodb-prod mongo

# Reset database
docker-compose down -v
docker-compose up -d mongodb
```

#### Build Failures
```bash
# Clean build cache
docker system prune -f

# Rebuild specific service
docker-compose build --no-cache backend

# Check build logs
docker-compose build backend
```

### Debug Commands
```bash
# Enter container shell
docker exec -it bahnblitz-backend /bin/sh

# View container environment
docker exec bahnblitz-backend env

# Check network connectivity
docker exec bahnblitz-backend curl -f http://bahnblitz-website:8080/health
```

## 📈 Performance Optimization

### Docker Optimizations
```dockerfile
# Use .dockerignore
COPY .dockerignore ./
RUN apk add --no-cache curl

# Multi-stage builds
FROM node:18-alpine AS builder
FROM nginx:alpine AS production

# Proper layer caching
COPY package*.json ./
RUN npm ci --only=production
```

### Production Best Practices
- **Resource limits** in docker-compose.prod.yml
- **Health checks** for automatic restarts
- **Logging configuration** for log rotation
- **Security scanning** of images
- **Regular updates** of base images

## 🔒 Security

### Container Security
- **Non-root users** in production images
- **Minimal base images** (Alpine Linux)
- **No unnecessary packages** in containers
- **Secret management** with environment variables
- **Network isolation** between services

### GCP Security
- **IAM roles** with least privilege
- **Secret Manager** for sensitive data
- **VPC networks** for service isolation
- **Cloud Armor** for DDoS protection
- **Audit logs** for compliance

## 🚀 Deployment Scripts

### Local Development
```bash
# Start development environment
./scripts/start-dev.sh

# Stop all services
./scripts/stop-dev.sh

# Clean restart
./scripts/restart-dev.sh
```

### Production Deployment
```bash
# Deploy to production
./scripts/deploy-prod.sh

# Rollback deployment
./scripts/rollback.sh

# Update specific service
./scripts/update-service.sh backend
```

### GCP Deployment
```bash
# First-time GCP setup
./setup-gcp.sh

# Deploy to Cloud Run
./gcp-deploy.sh

# Update secrets
./scripts/update-secrets.sh
```

## 📚 Additional Resources

### Docker Documentation
- [Docker Compose](https://docs.docker.com/compose/)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [Multi-stage Builds](https://docs.docker.com/develop/dev-best-practices/)

### GCP Documentation
- [Cloud Run](https://cloud.google.com/run/docs)
- [Container Registry](https://cloud.google.com/container-registry)
- [Cloud Build](https://cloud.google.com/cloud-build)

### BahnBlitz Documentation
- [API Documentation](./backend/README.md)
- [Website Guide](./website/README.md)
- [Deployment Guide](./DEPLOYMENT.md)

---

**Happy Dockerizing! 🐳✨**

For issues or questions, check the troubleshooting section or create an issue in the repository.
