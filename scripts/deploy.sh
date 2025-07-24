#!/bin/bash

# Deployment Script for E-Paper Flutter App
# This script handles deployment to different platforms and environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 E-Paper App Deployment Script${NC}"

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

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

# Show usage
show_usage() {
    echo "Usage: $0 <platform> <environment> [options]"
    echo ""
    echo "Platforms:"
    echo "  web       - Deploy web application"
    echo "  android   - Deploy Android application"
    echo "  ios       - Deploy iOS application"
    echo "  all       - Deploy all platforms"
    echo ""
    echo "Environments:"
    echo "  dev       - Development environment"
    echo "  staging   - Staging environment"
    echo "  prod      - Production environment"
    echo ""
    echo "Options:"
    echo "  --build-only    - Only build, don't deploy"
    echo "  --skip-build    - Skip build, deploy existing artifacts"
    echo "  --dry-run       - Show what would be deployed without actually deploying"
    echo ""
    echo "Examples:"
    echo "  $0 web dev                    # Deploy web app to development"
    echo "  $0 android prod --build-only  # Build Android for production"
    echo "  $0 all staging                # Deploy all platforms to staging"
}

# Parse arguments
PLATFORM=$1
ENVIRONMENT=$2
BUILD_ONLY=false
SKIP_BUILD=false
DRY_RUN=false

# Parse options
shift 2 2>/dev/null || true
while [[ $# -gt 0 ]]; do
    case $1 in
        --build-only)
            BUILD_ONLY=true
            shift
            ;;
        --skip-build)
            SKIP_BUILD=true
            shift
            ;;
        --dry-run)
            DRY_RUN=true
            shift
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate arguments
if [[ -z "$PLATFORM" || -z "$ENVIRONMENT" ]]; then
    print_error "Platform and environment are required"
    show_usage
    exit 1
fi

if [[ ! "$PLATFORM" =~ ^(web|android|ios|all)$ ]]; then
    print_error "Invalid platform: $PLATFORM"
    show_usage
    exit 1
fi

if [[ ! "$ENVIRONMENT" =~ ^(dev|staging|prod)$ ]]; then
    print_error "Invalid environment: $ENVIRONMENT"
    show_usage
    exit 1
fi

print_info "Platform: $PLATFORM"
print_info "Environment: $ENVIRONMENT"
print_info "Build only: $BUILD_ONLY"
print_info "Skip build: $SKIP_BUILD"
print_info "Dry run: $DRY_RUN"

# Set build type based on environment
case $ENVIRONMENT in
    "dev")
        BUILD_TYPE="debug"
        ;;
    "staging")
        BUILD_TYPE="profile"
        ;;
    "prod")
        BUILD_TYPE="release"
        ;;
esac

print_info "Build type: $BUILD_TYPE"

# Function to build platform
build_platform() {
    local platform=$1
    local build_type=$2
    
    if [[ "$SKIP_BUILD" == "true" ]]; then
        print_warning "Skipping build for $platform"
        return 0
    fi
    
    echo -e "${BLUE}🔨 Building $platform in $build_type mode...${NC}"
    
    case $platform in
        "web")
            ./scripts/build_web.sh $build_type canvaskit "/"
            ;;
        "android")
            ./scripts/build_android.sh $build_type apk
            ;;
        "ios")
            ./scripts/build_ios.sh $build_type development
            ;;
        *)
            print_error "Unknown platform for building: $platform"
            return 1
            ;;
    esac
}

# Function to deploy web
deploy_web() {
    local environment=$1
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "DRY RUN: Would deploy web to $environment"
        return 0
    fi
    
    echo -e "${BLUE}🌐 Deploying web to $environment...${NC}"
    
    case $environment in
        "dev"|"staging")
            # Deploy to preview Cloud Run instance
            print_info "Deploying to preview Cloud Run instance..."
            
            # Check if gcloud is installed
            if ! command -v gcloud &> /dev/null; then
                print_error "gcloud CLI is not installed"
                return 1
            fi
            
            # Dockerfile should already exist in the repository
            if [[ ! -f "Dockerfile" ]]; then
                print_error "Dockerfile not found. Please ensure Dockerfile exists in the repository."
                return 1
            fi
            
            # Deploy to Cloud Run
            gcloud run deploy epaper-$environment \
                --source . \
                --platform managed \
                --region europe-west1 \
                --allow-unauthenticated \
                --port 8080
            ;;
        "prod")
            # Deploy to production Cloud Run instance
            print_info "Deploying to production Cloud Run instance..."
            
            if ! command -v gcloud &> /dev/null; then
                print_error "gcloud CLI is not installed"
                return 1
            fi
            
            if [[ ! -f "Dockerfile" ]]; then
                print_error "Dockerfile not found. Please ensure Dockerfile exists in the repository."
                return 1
            fi
            
            gcloud run deploy epaper \
                --source . \
                --platform managed \
                --region europe-west1 \
                --allow-unauthenticated \
                --port 8080
            ;;
    esac
    
    print_status "Web deployment completed"
}

# Function to deploy Android
deploy_android() {
    local environment=$1
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "DRY RUN: Would deploy Android to $environment"
        return 0
    fi
    
    echo -e "${BLUE}📱 Deploying Android to $environment...${NC}"
    
    case $environment in
        "dev"|"staging")
            print_info "Android artifacts ready for manual distribution"
            print_info "APK location: artifacts/android/"
            ;;
        "prod")
            print_info "For production deployment:"
            print_info "1. Upload AAB to Google Play Console"
            print_info "2. Follow Google Play release process"
            print_info "AAB location: artifacts/android/"
            ;;
    esac
    
    print_status "Android deployment information provided"
}

# Function to deploy iOS
deploy_ios() {
    local environment=$1
    
    if [[ "$DRY_RUN" == "true" ]]; then
        print_info "DRY RUN: Would deploy iOS to $environment"
        return 0
    fi
    
    echo -e "${BLUE}📱 Deploying iOS to $environment...${NC}"
    
    case $environment in
        "dev"|"staging")
            print_info "iOS artifacts ready for manual distribution"
            print_info "App bundle location: build/ios/iphoneos/Runner.app"
            ;;
        "prod")
            print_info "For production deployment:"
            print_info "1. Archive app in Xcode"
            print_info "2. Upload to App Store Connect"
            print_info "3. Submit for App Store review"
            ;;
    esac
    
    print_status "iOS deployment information provided"
}


# Main deployment logic
case $PLATFORM in
    "web")
        build_platform "web" $BUILD_TYPE
        if [[ "$BUILD_ONLY" == "false" ]]; then
            deploy_web $ENVIRONMENT
        fi
        ;;
    "android")
        build_platform "android" $BUILD_TYPE
        if [[ "$BUILD_ONLY" == "false" ]]; then
            deploy_android $ENVIRONMENT
        fi
        ;;
    "ios")
        build_platform "ios" $BUILD_TYPE
        if [[ "$BUILD_ONLY" == "false" ]]; then
            deploy_ios $ENVIRONMENT
        fi
        ;;
    "all")
        build_platform "web" $BUILD_TYPE
        build_platform "android" $BUILD_TYPE
        if [[ "$OSTYPE" == "darwin"* ]]; then
            build_platform "ios" $BUILD_TYPE
        else
            print_warning "Skipping iOS build (not on macOS)"
        fi
        
        if [[ "$BUILD_ONLY" == "false" ]]; then
            deploy_web $ENVIRONMENT
            deploy_android $ENVIRONMENT
            if [[ "$OSTYPE" == "darwin"* ]]; then
                deploy_ios $ENVIRONMENT
            fi
        fi
        ;;
esac

echo -e "${GREEN}🎉 Deployment process completed!${NC}"

# Show artifact locations
if [[ -d "artifacts" ]]; then
    echo -e "${BLUE}📦 Artifacts created:${NC}"
    find artifacts -type f -exec echo "   {}" \;
fi
