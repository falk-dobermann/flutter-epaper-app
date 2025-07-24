#!/bin/bash

# iOS Build Script for E-Paper Flutter App
# This script builds the iOS IPA file for different environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_NAME="epaper"
BUILD_DIR="build/ios"

echo -e "${BLUE}🚀 Starting iOS build for $APP_NAME${NC}"

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

# Check if we're on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "iOS builds can only be performed on macOS"
    exit 1
fi

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    print_error "Xcode is not installed or xcodebuild is not in PATH"
    exit 1
fi

print_status "Flutter found: $(flutter --version | head -n 1)"
print_status "Xcode found: $(xcodebuild -version | head -n 1)"

# Clean previous builds
echo -e "${BLUE}🧹 Cleaning previous builds...${NC}"
flutter clean
flutter pub get

# Update iOS pods
echo -e "${BLUE}📦 Updating iOS dependencies...${NC}"
cd ios
pod install --repo-update
cd ..

# Analyze code
echo -e "${BLUE}🔍 Analyzing code...${NC}"
flutter analyze
if [ $? -ne 0 ]; then
    print_warning "Code analysis found issues, but continuing with build..."
fi

# Build type (default to release)
BUILD_TYPE=${1:-release}
EXPORT_METHOD=${2:-development}

echo -e "${BLUE}📱 Building iOS app in $BUILD_TYPE mode with $EXPORT_METHOD export method...${NC}"

# Set environment variables and build
case $BUILD_TYPE in
    "debug")
        flutter build ios --debug --no-codesign \
            --dart-define=ENVIRONMENT=development \
            --dart-define=API_BASE_URL=http://localhost:3000
        print_status "iOS debug build completed (no code signing)"
        ;;
    "profile")
        flutter build ios --profile --no-codesign \
            --dart-define=ENVIRONMENT=staging \
            --dart-define=API_BASE_URL=https://api-staging.epaper.example.com
        print_status "iOS profile build completed (no code signing)"
        ;;
    "release")
        # For release builds, we need to handle code signing
        if [ "$EXPORT_METHOD" = "development" ]; then
            flutter build ios --release --no-codesign \
                --dart-define=ENVIRONMENT=production \
                --dart-define=API_BASE_URL=https://api.epaper.example.com
            print_warning "iOS release build completed without code signing"
            print_warning "For App Store distribution, use proper provisioning profiles"
        else
            # This would require proper provisioning profiles and certificates
            flutter build ios --release \
                --dart-define=ENVIRONMENT=production \
                --dart-define=API_BASE_URL=https://api.epaper.example.com
            
            # Create IPA if build succeeded
            if [ -d "$BUILD_DIR/iphoneos/Runner.app" ]; then
                echo -e "${BLUE}📦 Creating IPA archive...${NC}"
                
                # Create Payload directory
                mkdir -p Payload
                cp -r "$BUILD_DIR/iphoneos/Runner.app" Payload/
                
                # Create IPA
                zip -r "epaper-$BUILD_TYPE.ipa" Payload/
                rm -rf Payload/
                
                # Create artifacts directory for CI/CD
                mkdir -p artifacts/ios
                mv "epaper-$BUILD_TYPE.ipa" "artifacts/ios/"
                
                print_status "IPA created: artifacts/ios/epaper-$BUILD_TYPE.ipa"
            fi
        fi
        ;;
    *)
        print_error "Invalid build type: $BUILD_TYPE. Use debug, profile, or release"
        exit 1
        ;;
esac

# Check if build was successful
if [ -d "$BUILD_DIR/iphoneos/Runner.app" ]; then
    print_status "iOS build completed successfully!"
    echo -e "${GREEN}📦 App bundle location: $BUILD_DIR/iphoneos/Runner.app${NC}"
    
    # Get app bundle size
    BUNDLE_SIZE=$(du -sh "$BUILD_DIR/iphoneos/Runner.app" | cut -f1)
    echo -e "${GREEN}📏 App bundle size: $BUNDLE_SIZE${NC}"
    
else
    print_error "Build failed! App bundle not found at $BUILD_DIR/iphoneos/Runner.app"
    exit 1
fi

echo -e "${GREEN}🎉 iOS build completed successfully!${NC}"

# Additional notes for deployment
echo -e "${YELLOW}📝 Deployment Notes:${NC}"
echo -e "${YELLOW}   • For App Store distribution, ensure you have valid distribution certificates${NC}"
echo -e "${YELLOW}   • For TestFlight, use 'app-store' export method${NC}"
echo -e "${YELLOW}   • For enterprise distribution, use 'enterprise' export method${NC}"
echo -e "${YELLOW}   • For ad-hoc distribution, use 'ad-hoc' export method${NC}"
