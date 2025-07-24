## Brief overview
Project-specific guidelines for Flutter e-paper application development, focusing on cross-platform mobile development with PDF asset handling and clean architecture patterns.

## Communication style
- Be direct and technical in responses, avoiding conversational phrases like "Great" or "Certainly"
- Provide clear explanations of Flutter-specific concepts and implementation details
- Focus on actionable solutions rather than lengthy discussions

## Development workflow
- Follow Flutter project structure conventions with lib/ as the main source directory
- Maintain platform-specific configurations in android/, ios/, web/, etc. directories
- Use pubspec.yaml for dependency management and asset declarations
- Implement proper asset management for PDF files in assets/pdf/ directory
- Test across multiple platforms when making significant changes

## Coding best practices
- Follow Dart naming conventions with camelCase for variables and methods
- Use proper widget composition and separation of concerns
- Implement proper state management patterns appropriate for the app complexity
- Handle platform-specific code when necessary using platform channels
- Ensure proper error handling for file operations and PDF processing

## Project context
- This is an e-paper application that handles PDF documents
- PDF assets are stored in assets/pdf/ directory and must be declared in pubspec.yaml
- Cross-platform support is important (Android, iOS, web, desktop)
- Focus on performance optimization for document rendering and display
- There are two screens, one for selecting the epaper issue, one for reading the epaper/pdf

## Asset and file management
- PDF files should be properly organized in assets/pdf/ directory
- Use descriptive filenames for PDF assets (e.g., date-location format)
- Ensure all assets are properly declared in pubspec.yaml under flutter/assets
- Consider file size optimization for mobile deployment
- Implement proper error handling for missing or corrupted PDF files

## CICD
- Builds and deployments are based on GitHub workflows
- For web deployments, Google Cloud Run is used
- Pull Requests are build for previewing new features (by preview cloud run instances (web) or by creating artifacts (apps))
- GitHub Releases are used for live deployments