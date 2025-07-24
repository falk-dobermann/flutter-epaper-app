# E-Paper Flutter Application

A cross-platform Flutter application for viewing PDF documents, designed specifically for e-paper content. The app provides an intuitive interface for browsing and reading PDF files with optimized rendering for different screen sizes.

## Features

- 📱 **Cross-platform support**: Android, iOS, Web, macOS, Windows, Linux
- 📄 **PDF viewing**: High-quality PDF rendering with zoom and navigation
- 🎨 **Responsive design**: Optimized for different screen sizes and orientations
- 🔍 **Search functionality**: Find content within PDF documents
- 📑 **Thumbnail navigation**: Quick page overview and navigation
- 🌐 **Web deployment**: Cloud Run integration for web access
- 🔒 **Secure PDF storage**: Server-only PDF access with RESTful API
- 🚀 **Development tools**: Automated scripts for local development

## Screenshots

The application features two main screens:
1. **PDF List Screen**: Browse available e-paper issues
2. **PDF Viewer Screen**: Read and navigate through PDF content

## Getting Started

### Prerequisites

- Flutter SDK 3.32.7 or later
- Dart 3.8.1 or later
- For Android: Android Studio and Android SDK
- For iOS: Xcode (macOS only)
- For web deployment: Google Cloud CLI (optional)

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd epaper
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   cd api-server && npm install
   ```

3. **Run the application**

   #### Development Mode (Recommended)
   ```bash
   # Start both API server and Flutter web app
   ./scripts/dev-start.sh
   
   # Or start only the API server
   ./scripts/start-api.sh
   ```

   #### Manual Platform Runs
   ```bash
   # Web (with API integration)
   flutter run -d chrome --dart-define=ENVIRONMENT=development --dart-define=API_BASE_URL=http://localhost:3000
   
   # Android
   flutter run -d android
   
   # iOS (macOS only)
   flutter run -d ios
   
   # macOS
   flutter run -d macos
   ```

## Build and Deployment

This project includes comprehensive build and deployment scripts for all supported platforms.

### Build Scripts

#### Android Build
```bash
# Build debug APK
./scripts/build_android.sh debug apk

# Build release APK
./scripts/build_android.sh release apk

# Build release AAB (for Play Store)
./scripts/build_android.sh release aab
```

#### iOS Build
```bash
# Build debug (macOS only)
./scripts/build_ios.sh debug development

# Build release (macOS only)
./scripts/build_ios.sh release development
```

#### Web Build
```bash
# Build debug
./scripts/build_web.sh debug canvaskit "/"

# Build release
./scripts/build_web.sh release canvaskit "/"
```

### Deployment Scripts

The unified deployment script handles multiple platforms and environments:

```bash
# Deploy web to development
./scripts/deploy.sh web dev

# Deploy web to staging
./scripts/deploy.sh web staging

# Deploy web to production
./scripts/deploy.sh web prod

# Deploy all platforms to staging
./scripts/deploy.sh all staging

# Build only (no deployment)
./scripts/deploy.sh web prod --build-only

# Dry run (show what would be deployed)
./scripts/deploy.sh web prod --dry-run
```

### CI/CD Pipeline

The project includes a comprehensive GitHub Actions workflow that:

- **Analyzes code** and runs tests on every push and PR
- **Builds artifacts** for Android, iOS, and Web
- **Deploys preview instances** for pull requests
- **Deploys to staging** when pushing to `develop` branch
- **Deploys to production** when creating a GitHub release
- **Cleans up preview deployments** when PRs are closed

#### Required Secrets

For full CI/CD functionality, configure these GitHub secrets:

- `GCP_SA_KEY`: Google Cloud service account key (JSON)
- `GCP_PROJECT_ID`: Google Cloud project ID

#### Workflow Triggers

- **Pull Requests**: Build all platforms + deploy web preview
- **Push to `develop`**: Build all platforms + deploy to staging
- **GitHub Release**: Build all platforms + deploy to production

## Project Structure

```
epaper/
├── lib/
│   ├── main.dart                 # Application entry point
│   ├── config/
│   │   └── environment.dart      # Environment configuration
│   ├── models/
│   │   └── pdf_asset.dart        # PDF asset model
│   ├── screens/
│   │   ├── pdf_list_screen.dart  # PDF selection screen
│   │   └── pdf_viewer_screen.dart # PDF reading screen
│   ├── services/
│   │   └── pdf_service.dart      # API service for PDF operations
│   └── widgets/
│       ├── pdf_thumbnail_card.dart
│       ├── pdf_thumbnail_panel.dart
│       └── pdf_outline_panel.dart
├── api-server/
│   ├── server.js                 # Express.js API server
│   ├── package.json              # Node.js dependencies
│   ├── Dockerfile                # API server container
│   ├── pdfs/                     # Server-only PDF storage
│   └── thumbnails/               # Generated PDF thumbnails
├── scripts/
│   ├── build_android.sh          # Android build script
│   ├── build_ios.sh              # iOS build script
│   ├── build_web.sh              # Web build script
│   ├── deploy.sh                 # Unified deployment script
│   ├── deploy_api.sh             # API server deployment
│   ├── dev-start.sh              # Development environment starter
│   ├── start-api.sh              # API server only starter
│   └── quick-start.sh            # Interactive development menu
├── .github/
│   └── workflows/
│       └── ci.yml                # CI/CD pipeline
├── Dockerfile                    # Web deployment container
└── platform directories (android/, ios/, web/, etc.)
```

## Configuration

### PDF Assets

PDF files are now stored securely in the `api-server/pdfs/` directory and served through the REST API. This provides better security and controlled access to PDF content.

**For development:**
- Place PDF files in `api-server/pdfs/` directory
- The API server automatically detects and serves available PDFs
- No need to declare PDFs in `pubspec.yaml` as they're served via API

**API Endpoints:**
- `GET /api/pdfs` - List all available PDFs
- `GET /api/pdfs/:id/download` - Download a specific PDF
- `GET /api/pdfs/:id/metadata` - Get PDF metadata
- `GET /health` - API health check

### Environment Configuration

The deployment scripts support three environments:

- **dev**: Development environment (debug builds)
- **staging**: Staging environment (profile builds)
- **prod**: Production environment (release builds)

### Web Deployment

For Google Cloud Run deployment, ensure:

1. Google Cloud CLI is installed and configured
2. Required secrets are set in GitHub repository
3. Cloud Run API is enabled in your GCP project

## Development Guidelines

### Code Quality

- Run `flutter analyze` before committing
- Follow Dart naming conventions
- Use proper widget composition and separation of concerns
- Handle platform-specific code appropriately

### Asset Management

- Use descriptive filenames for PDF assets (e.g., date-location format)
- Optimize file sizes for mobile deployment
- Ensure all assets are properly declared in pubspec.yaml

### Testing

- Write unit tests for business logic
- Test across multiple platforms when making significant changes
- Use the CI/CD pipeline to validate changes

## Performance Optimization

### PDF Rendering

- The app uses `canvaskit` renderer for optimal PDF performance on web
- PDF pages are loaded progressively for better user experience
- Thumbnail generation is optimized for quick navigation

### Build Optimization

- Release builds are optimized for size and performance
- Web builds include proper caching headers configuration
- Android builds support both APK and AAB formats

## Troubleshooting

### Common Issues

1. **PDF not loading on iOS**: The pdfrx package has limited iOS support
2. **Build failures**: Ensure all dependencies are properly installed
3. **Web deployment issues**: Check Google Cloud CLI authentication

### Platform-Specific Notes

- **iOS**: Requires macOS for building and code signing for distribution
- **Android**: NDK version conflicts may require updating build.gradle.kts
- **Web**: CORS configuration may be needed for PDF assets from different domains

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes following the development guidelines
4. Test across relevant platforms
5. Submit a pull request

The CI/CD pipeline will automatically build and deploy a preview for your PR.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Check the troubleshooting section
- Review the CI/CD pipeline logs
- Create an issue in the repository

---

Built with ❤️ using Flutter and optimized for e-paper content delivery.
