#!/bin/bash

# Android Build Script for E-Paper Flutter App
# This script builds the Android APK and AAB files for different environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="epaper"
BUILD_DIR="build/app/outputs"

echo -e "${BLUE}🚀 Starting Android build for $APP_NAME${NC}"

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
BUILD_FORMAT=${2:-apk}

echo -e "${BLUE}📱 Building Android $BUILD_FORMAT in $BUILD_TYPE mode...${NC}"

# Set environment variables and build
case $BUILD_TYPE in
    "debug")
        if [ "$BUILD_FORMAT" = "aab" ]; then
            flutter build appbundle --debug \
                --dart-define=ENVIRONMENT=development \
                --dart-define=API_BASE_URL=http://localhost:3000
            ARTIFACT_PATH="$BUILD_DIR/bundle/debug/app-debug.aab"
        else
            flutter build apk --debug \
                --dart-define=ENVIRONMENT=development \
                --dart-define=API_BASE_URL=http://localhost:3000
            ARTIFACT_PATH="$BUILD_DIR/flutter-apk/app-debug.apk"
        fi
        ;;
    "profile")
        if [ "$BUILD_FORMAT" = "aab" ]; then
            flutter build appbundle --profile \
                --dart-define=ENVIRONMENT=staging \
                --dart-define=API_BASE_URL=https://api-staging.epaper.example.com
            ARTIFACT_PATH="$BUILD_DIR/bundle/profile/app-profile.aab"
        else
            flutter build apk --profile \
                --dart-define=ENVIRONMENT=staging \
                --dart-define=API_BASE_URL=https://api-staging.epaper.example.com
            ARTIFACT_PATH="$BUILD_DIR/flutter-apk/app-profile.apk"
        fi
        ;;
    "release")
        if [ "$BUILD_FORMAT" = "aab" ]; then
            flutter build appbundle --release \
                --dart-define=ENVIRONMENT=production \
                --dart-define=API_BASE_URL=https://api.epaper.example.com
            ARTIFACT_PATH="$BUILD_DIR/bundle/release/app-release.aab"
        else
            flutter build apk --release \
                --dart-define=ENVIRONMENT=production \
                --dart-define=API_BASE_URL=https://api.epaper.example.com
            ARTIFACT_PATH="$BUILD_DIR/flutter-apk/app-release.apk"
        fi
        ;;
    *)
        print_error "Invalid build type: $BUILD_TYPE. Use debug, profile, or release"
        exit 1
        ;;
esac

# Check if build was successful
if [ -f "$ARTIFACT_PATH" ]; then
    print_status "Android $BUILD_FORMAT built successfully!"
    echo -e "${GREEN}📦 Artifact location: $ARTIFACT_PATH${NC}"
    
    # Get file size
    FILE_SIZE=$(du -h "$ARTIFACT_PATH" | cut -f1)
    echo -e "${GREEN}📏 File size: $FILE_SIZE${NC}"
    
    # Create artifacts directory for CI/CD
    mkdir -p artifacts/android
    cp "$ARTIFACT_PATH" "artifacts/android/"
    print_status "Artifact copied to artifacts/android/"
    
else
    print_error "Build failed! Artifact not found at $ARTIFACT_PATH"
    exit 1
fi

echo -e "${GREEN}🎉 Android build completed successfully!${NC}"
