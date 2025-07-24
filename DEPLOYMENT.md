# Deployment Guide

This document provides detailed instructions for setting up and using the build and deployment system for the E-Paper Flutter application.

## Quick Start

For immediate access to all build and deployment features, use the interactive quick-start script:

```bash
./scripts/quick-start.sh
```

This provides a user-friendly menu for all common development tasks.

## Build Scripts Overview

### Individual Platform Scripts

| Script | Purpose | Usage |
|--------|---------|-------|
| `build_android.sh` | Build Android APK/AAB | `./scripts/build_android.sh <type> <format>` |
| `build_ios.sh` | Build iOS app (macOS only) | `./scripts/build_ios.sh <type> <method>` |
| `build_web.sh` | Build web application | `./scripts/build_web.sh <type> <renderer> <base_href>` |
| `deploy.sh` | Unified deployment | `./scripts/deploy.sh <platform> <env> [options]` |
| `deploy_api.sh` | Deploy API server | `./scripts/deploy_api.sh` |

### Build Types

- **debug**: Development builds with debugging enabled
- **profile**: Performance profiling builds
- **release**: Production-ready optimized builds

## Detailed Usage Examples

### Android Builds

```bash
# Debug APK for testing
./scripts/build_android.sh debug apk

# Release APK for distribution
./scripts/build_android.sh release apk

# Release AAB for Google Play Store
./scripts/build_android.sh release aab
```

**Output**: Artifacts in `artifacts/android/`

### iOS Builds (macOS only)

```bash
# Debug build for testing
./scripts/build_ios.sh debug development

# Release build for distribution
./scripts/build_ios.sh release development
```

**Output**: App bundle in `build/ios/iphoneos/Runner.app`

### Web Builds

```bash
# Debug build for development
./scripts/build_web.sh debug canvaskit "/"

# Release build for production
./scripts/build_web.sh release canvaskit "/"

# Custom base href for subdirectory deployment
./scripts/build_web.sh release canvaskit "/epaper/"
```

**Output**: Web files in `build/web/` and `artifacts/web/`

### API Server Deployment

```bash
# Deploy API server to Google Cloud Run
./scripts/deploy_api.sh

# Set environment variables for deployment
export GOOGLE_CLOUD_PROJECT="your-project-id"
export GOOGLE_CLOUD_REGION="europe-west1"
./scripts/deploy_api.sh
```

**Features**:
- Automatic Docker image building
- SVG-based PDF thumbnail generation
- RESTful API endpoints for PDF management
- Health checks and monitoring
- Auto-scaling based on demand

**API Endpoints**:
- `GET /health` - Health check
- `GET /api/pdfs` - List available PDFs
- `GET /api/pdfs/:id/download` - Download PDF file
- `GET /api/pdfs/:id/thumbnail` - Get PDF thumbnail (SVG)
- `GET /api/pdfs/:id/metadata` - Get PDF metadata

### Unified Deployment

```bash
# Deploy web to different environments
./scripts/deploy.sh web dev          # Development
./scripts/deploy.sh web staging      # Staging
./scripts/deploy.sh web prod         # Production

# Deploy all platforms
./scripts/deploy.sh all staging      # All platforms to staging

# Build-only mode (no deployment)
./scripts/deploy.sh web prod --build-only

# Dry run (show what would happen)
./scripts/deploy.sh web prod --dry-run
```

## CI/CD Pipeline

### GitHub Actions Workflow

The project includes a comprehensive CI/CD pipeline (`.github/workflows/ci.yml`) that:

1. **Code Analysis**: Runs `flutter analyze` and tests
2. **Multi-platform Builds**: Builds for Android, iOS, and Web
3. **Automated Deployment**: Deploys based on branch/event
4. **Artifact Management**: Stores build outputs for download

### Workflow Triggers

| Event | Action |
|-------|--------|
| Pull Request | Build all platforms + deploy web preview |
| Push to `develop` | Build all + deploy to staging |
| GitHub Release | Build all + deploy to production |
| PR Closed | Cleanup preview deployments |

### Required Secrets

Configure these in your GitHub repository settings:

```
GCP_SA_KEY          # Google Cloud service account key (JSON)
GCP_PROJECT_ID      # Google Cloud project ID
```

## Google Cloud Run Deployment

### Prerequisites

1. **Google Cloud Project**: Create or select a GCP project
2. **Enable APIs**: Cloud Run API, Cloud Build API
3. **Service Account**: Create with Cloud Run Admin permissions
4. **Authentication**: Download service account key as JSON

### Setup Steps

1. **Install Google Cloud CLI**
   ```bash
   # macOS
   brew install google-cloud-sdk
   
   # Other platforms: https://cloud.google.com/sdk/docs/install
   ```

2. **Authenticate**
   ```bash
   gcloud auth login
   gcloud config set project YOUR_PROJECT_ID
   ```

3. **Enable Required APIs**
   ```bash
   gcloud services enable run.googleapis.com
   gcloud services enable cloudbuild.googleapis.com
   ```

4. **Deploy Manually**
   ```bash
   ./scripts/deploy.sh web prod
   ```

### Deployment Environments

| Environment | Branch/Trigger | URL Pattern |
|-------------|----------------|-------------|
| Development | Manual | `epaper-dev-*` |
| Staging | `develop` branch | `epaper-staging-*` |
| Production | GitHub Release | `epaper-*` |
| Preview | Pull Request | `epaper-pr-{number}-*` |

## Local Development

### Setup

```bash
# Install dependencies
flutter pub get

# Enable web support
flutter config --enable-web

# Run development server
flutter run -d chrome  # Web
flutter run -d android # Android
flutter run -d ios     # iOS (macOS only)
```

### Development Workflow

1. **Make Changes**: Edit code in `lib/` directory
2. **Test Locally**: Use `flutter run` for hot reload
3. **Quality Check**: Run `flutter analyze` and `flutter test`
4. **Build**: Use build scripts to create artifacts
5. **Deploy**: Use deployment scripts or CI/CD pipeline

## Troubleshooting

### Common Issues

#### Build Failures

```bash
# Clean and retry
flutter clean
flutter pub get
./scripts/build_web.sh release canvaskit "/"
```

#### Permission Errors

```bash
# Make scripts executable
chmod +x scripts/*.sh
```

#### Google Cloud Authentication

```bash
# Re-authenticate
gcloud auth login
gcloud auth application-default login
```

#### iOS Build Issues (macOS)

```bash
# Update pods
cd ios
pod install --repo-update
cd ..
```

### Platform-Specific Notes

#### Android
- NDK version conflicts: Update `android/app/build.gradle.kts`
- Signing: Configure keystore for release builds
- Permissions: Check `AndroidManifest.xml`

#### iOS
- Code signing: Requires Apple Developer account
- Provisioning: Set up proper profiles
- Simulator vs Device: Different build targets

#### Web
- CORS: Configure for PDF assets
- Base href: Set correctly for subdirectory deployment
- Renderer: Use `canvaskit` for better PDF performance

## Performance Optimization

### Build Optimization

- **Web**: Use `--release` for production builds
- **Android**: Use AAB format for Play Store
- **iOS**: Enable bitcode for App Store

### Asset Optimization

- **PDF Files**: Optimize file sizes before including
- **Images**: Use appropriate formats and sizes
- **Fonts**: Include only necessary font weights

### Deployment Optimization

- **Caching**: Configure proper cache headers
- **Compression**: Enable gzip/brotli compression
- **CDN**: Use Cloud CDN for global distribution

## Security Considerations

### Secrets Management

- Store sensitive data in GitHub Secrets
- Use service accounts with minimal permissions
- Rotate keys regularly

### Access Control

- Limit Cloud Run access as needed
- Use IAM roles appropriately
- Monitor deployment logs

## Monitoring and Maintenance

### Monitoring

- **Cloud Run**: Monitor via Google Cloud Console
- **GitHub Actions**: Check workflow status
- **Application**: Use Flutter DevTools for debugging

### Maintenance

- **Dependencies**: Regular `flutter pub upgrade`
- **Flutter SDK**: Keep updated to stable releases
- **Scripts**: Review and update as needed

## Support and Resources

### Documentation

- [Flutter Documentation](https://flutter.dev/docs)
- [Google Cloud Run](https://cloud.google.com/run/docs)
- [GitHub Actions](https://docs.github.com/en/actions)

### Getting Help

1. Check this documentation
2. Review CI/CD pipeline logs
3. Check Flutter and Google Cloud documentation
4. Create an issue in the repository

---

For immediate assistance, use the interactive quick-start script:
```bash
./scripts/quick-start.sh
