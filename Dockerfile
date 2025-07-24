# Multi-stage Dockerfile for Flutter Web Application
# Stage 1: Build the Flutter web application
FROM ghcr.io/cirruslabs/flutter:3.32.7 AS build

# Set working directory
WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy source code
COPY . .

# Enable web support and build the application
RUN flutter config --enable-web
RUN flutter build web --release --web-renderer canvaskit

# Stage 2: Serve the application with a simple HTTP server
FROM python:3.11-alpine

# Install curl for health checks
RUN apk add --no-cache curl

# Create a non-root user
RUN addgroup -g 1001 -S appuser && \
    adduser -S -D -H -u 1001 -h /app -s /sbin/nologin -G appuser -g appuser appuser

# Set working directory
WORKDIR /app

# Copy the Flutter web build
COPY --from=build /app/build/web ./

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

# Switch to non-root user
USER appuser

# Expose port 8080 for Cloud Run
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

# Start simple HTTP server
CMD ["python", "-m", "http.server", "8080"]
