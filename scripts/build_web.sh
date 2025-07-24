#!/bin/bash

# Web Build Script for E-Paper Flutter App
# This script builds the web application for different environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="epaper"
BUILD_DIR="build/web"

echo -e "${BLUE}🚀 Starting Web build for $APP_NAME${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    print_error "Flutter is not installed or not in PATH"
    exit 1
fi

print_status "Flutter found: $(flutter --version | head -n 1)"

# Check if web support is enabled
if ! flutter config | grep -q "enable-web: true"; then
    echo -e "${BLUE}🌐 Enabling Flutter web support...${NC}"
    flutter config --enable-web
fi

# Clean previous builds
echo -e "${BLUE}🧹 Cleaning previous builds...${NC}"
flutter clean
flutter pub get

# Analyze code
echo -e "${BLUE}🔍 Analyzing code...${NC}"
flutter analyze
if [ $? -ne 0 ]; then
    print_warning "Code analysis found issues, but continuing with build..."
fi

# Build type (default to release)
BUILD_TYPE=${1:-release}
WEB_RENDERER=${2:-canvaskit}
BASE_HREF=${3:-"/"}

echo -e "${BLUE}🌐 Building web app in $BUILD_TYPE mode with $WEB_RENDERER renderer...${NC}"

# Build arguments
BUILD_ARGS="--web-renderer $WEB_RENDERER --base-href $BASE_HREF"

# Set environment variables based on build type
case $BUILD_TYPE in
    "debug")
        flutter build web --debug $BUILD_ARGS \
            --dart-define=ENVIRONMENT=development \
            --dart-define=API_BASE_URL=http://localhost:3000
        ;;
    "profile")
        flutter build web --profile $BUILD_ARGS \
            --dart-define=ENVIRONMENT=staging \
            --dart-define=API_BASE_URL=https://api-staging.epaper.example.com
        ;;
    "release")
        flutter build web --release $BUILD_ARGS \
            --dart-define=ENVIRONMENT=production \
            --dart-define=API_BASE_URL=https://api.epaper.example.com
        ;;
    *)
        print_error "Invalid build type: $BUILD_TYPE. Use debug, profile, or release"
        exit 1
        ;;
esac

# Check if build was successful
if [ -d "$BUILD_DIR" ] && [ -f "$BUILD_DIR/index.html" ]; then
    print_status "Web build completed successfully!"
    echo -e "${GREEN}📦 Build location: $BUILD_DIR${NC}"
    
    # Get build size
    BUILD_SIZE=$(du -sh "$BUILD_DIR" | cut -f1)
    echo -e "${GREEN}📏 Build size: $BUILD_SIZE${NC}"
    
    # List main files
    echo -e "${BLUE}📄 Main files:${NC}"
    ls -la "$BUILD_DIR" | grep -E '\.(html|js|css)$' | awk '{print "   " $9 " (" $5 " bytes)"}'
    
    # Create artifacts directory for CI/CD
    mkdir -p artifacts/web
    cp -r "$BUILD_DIR"/* "artifacts/web/"
    print_status "Artifacts copied to artifacts/web/"
    
    # Create deployment-ready archive
    cd "$BUILD_DIR"
    tar -czf "../web-$BUILD_TYPE.tar.gz" .
    cd - > /dev/null
    mv "build/web-$BUILD_TYPE.tar.gz" "artifacts/web/"
    print_status "Deployment archive created: artifacts/web/web-$BUILD_TYPE.tar.gz"
    
else
    print_error "Build failed! Web build not found at $BUILD_DIR"
    exit 1
fi

echo -e "${GREEN}🎉 Web build completed successfully!${NC}"

# Additional deployment information
echo -e "${YELLOW}📝 Deployment Notes:${NC}"
echo -e "${YELLOW}   • Web renderer: $WEB_RENDERER${NC}"
echo -e "${YELLOW}   • Base href: $BASE_HREF${NC}"
echo -e "${YELLOW}   • For Google Cloud Run deployment, use the artifacts/web/ directory${NC}"
echo -e "${YELLOW}   • For static hosting, serve the contents of build/web/${NC}"
echo -e "${YELLOW}   • Ensure CORS is configured for PDF assets if serving from different domain${NC}"

# Performance recommendations
echo -e "${BLUE}⚡ Performance Tips:${NC}"
echo -e "${BLUE}   • Use 'canvaskit' renderer for better PDF rendering performance${NC}"
echo -e "${BLUE}   • Consider enabling gzip compression on your web server${NC}"
echo -e "${BLUE}   • Implement proper caching headers for static assets${NC}"
