# Use Node.js LTS version
FROM node:18-alpine

# Install system dependencies for PDF thumbnail generation
RUN apk add --no-cache \
    ghostscript \
    graphicsmagick \
    imagemagick \
    poppler-utils \
    && rm -rf /var/cache/apk/*

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Create directories for uploads and thumbnails
RUN mkdir -p uploads thumbnails

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD node -e "require('http').get('http://localhost:3000/health', (res) => { process.exit(res.statusCode === 200 ? 0 : 1) })"

# Start the server
CMD ["npm", "start"]
