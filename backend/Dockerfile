# BahnBlitz Backend - Multi-stage Docker Build
# Optimized for Google Cloud Platform

# ================================
# Stage 1: Dependencies & Build
# ================================
FROM node:18-alpine AS builder

# Set working directory
WORKDIR /app

# Install build dependencies for native modules
RUN apk add --no-cache \
    python3 \
    make \
    g++ \
    git

# Copy package files for better caching
COPY package*.json ./

# Install all dependencies (including dev dependencies)
RUN npm ci --only=production && npm cache clean --force

# Copy source code
COPY . .

# ================================
# Stage 2: Production Runtime
# ================================
FROM node:18-alpine AS production

# Install dumb-init for proper signal handling
RUN apk add --no-cache dumb-init curl

# Create app user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Copy installed dependencies from builder stage
COPY --from=builder /app/node_modules ./node_modules

# Copy application source code
COPY --chown=nodejs:nodejs . .

# Create uploads directory with proper permissions
RUN mkdir -p uploads && \
    chown -R nodejs:nodejs uploads

# Switch to non-root user
USER nodejs

# Expose port
EXPOSE 3001

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3001/health || exit 1

# Use dumb-init to handle signals properly
ENTRYPOINT ["dumb-init", "--"]

# Start the application
CMD ["npm", "start"]

# ================================
# Metadata
# ================================
LABEL maintainer="BahnBlitz Team" \
      version="1.0.0" \
      description="BahnBlitz Backend API for TestFlight Beta Management" \
      org.opencontainers.image.source="https://github.com/bahnblitz/backend"
