# BahnBlitz Beta Website - Nginx Static Site
# Optimized for Google Cloud Platform

# ================================
# Stage 1: Build Stage (if needed for future)
# ================================
FROM alpine:latest AS builder

# Install build tools if needed for future assets processing
RUN apk add --no-cache \
    curl \
    ca-certificates

# Set working directory
WORKDIR /build

# Copy website files
COPY . /build/

# ================================
# Stage 2: Production Nginx
# ================================
FROM nginx:alpine

# Install security updates and curl for health checks
RUN apk update && \
    apk upgrade && \
    apk add --no-cache curl && \
    rm -rf /var/cache/apk/*

# Copy custom nginx configuration
COPY nginx.conf /etc/nginx/nginx.conf

# Copy website files from builder stage
COPY --from=builder /build /usr/share/nginx/html

# Create nginx user and set proper permissions
RUN chown -R nginx:nginx /usr/share/nginx/html && \
    chown -R nginx:nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx && \
    chown -R nginx:nginx /etc/nginx/conf.d && \
    touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid

# Switch to non-root user
USER nginx

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

# Start nginx
CMD ["nginx", "-g", "daemon off;"]

# ================================
# Metadata
# ================================
LABEL maintainer="BahnBlitz Team" \
      version="1.0.0" \
      description="BahnBlitz Beta Website - Static Site with Nginx" \
      org.opencontainers.image.source="https://github.com/bahnblitz/website"
