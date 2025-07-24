#!/bin/bash

# Quick Start Script for E-Paper Flutter App
# This script provides an interactive menu for common development tasks

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Clear screen and show header
clear
echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║                    E-Paper Flutter App                      ║${NC}"
echo -e "${BLUE}║                   Quick Start Menu                          ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to print colored output
print_header() {
    echo -e "${CYAN}$1${NC}"
    echo -e "${CYAN}$(printf '=%.0s' {1..60})${NC}"
}

print_option() {
    echo -e "${GREEN}$1${NC} $2"
}

print_info() {
    echo -e "${YELLOW}ℹ $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Check if Flutter is installed
check_flutter() {
    if ! command -v flutter &> /dev/null; then
        print_error "Flutter is not installed or not in PATH"
        echo "Please install Flutter from https://flutter.dev/docs/get-started/install"
        exit 1
    fi
    print_success "Flutter found: $(flutter --version | head -n 1)"
}

# Show main menu
show_menu() {
    print_header "Available Actions"
    echo ""
    print_option "1." "Setup & Dependencies"
    print_option "2." "Run Development Server"
    print_option "3." "Build Applications"
    print_option "4." "Deploy Applications"
    print_option "5." "Code Quality & Analysis"
    print_option "6." "Project Information"
    print_option "7." "Exit"
    echo ""
}

# Setup and dependencies
setup_dependencies() {
    print_header "Setup & Dependencies"
    echo ""
    print_info "Installing Flutter dependencies..."
    flutter pub get
    
    print_info "Enabling web support..."
    flutter config --enable-web
    
    print_success "Setup completed!"
    echo ""
    read -p "Press Enter to continue..."
}

# Run development server
run_dev_server() {
    print_header "Run Development Server"
    echo ""
    print_option "1." "Web (Chrome)"
    print_option "2." "Android"
    print_option "3." "iOS (macOS only)"
    print_option "4." "macOS"
    print_option "5." "Back to main menu"
    echo ""
    read -p "Choose platform: " platform_choice
    
    case $platform_choice in
        1)
            print_info "Starting web development server..."
            flutter run -d chrome
            ;;
        2)
            print_info "Starting Android development server..."
            flutter run -d android
            ;;
        3)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                print_info "Starting iOS development server..."
                flutter run -d ios
            else
                print_error "iOS development requires macOS"
            fi
            ;;
        4)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                print_info "Starting macOS development server..."
                flutter run -d macos
            else
                print_error "macOS development requires macOS"
            fi
            ;;
        5)
            return
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
    echo ""
    read -p "Press Enter to continue..."
}

# Build applications
build_applications() {
    print_header "Build Applications"
    echo ""
    print_option "1." "Build Web (Debug)"
    print_option "2." "Build Web (Release)"
    print_option "3." "Build Android APK (Debug)"
    print_option "4." "Build Android APK (Release)"
    print_option "5." "Build Android AAB (Release)"
    print_option "6." "Build iOS (Debug)"
    print_option "7." "Build iOS (Release)"
    print_option "8." "Build All Platforms (Release)"
    print_option "9." "Back to main menu"
    echo ""
    read -p "Choose build option: " build_choice
    
    case $build_choice in
        1)
            print_info "Building web (debug)..."
            ./scripts/build_web.sh debug canvaskit "/"
            ;;
        2)
            print_info "Building web (release)..."
            ./scripts/build_web.sh release canvaskit "/"
            ;;
        3)
            print_info "Building Android APK (debug)..."
            ./scripts/build_android.sh debug apk
            ;;
        4)
            print_info "Building Android APK (release)..."
            ./scripts/build_android.sh release apk
            ;;
        5)
            print_info "Building Android AAB (release)..."
            ./scripts/build_android.sh release aab
            ;;
        6)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                print_info "Building iOS (debug)..."
                ./scripts/build_ios.sh debug development
            else
                print_error "iOS builds require macOS"
            fi
            ;;
        7)
            if [[ "$OSTYPE" == "darwin"* ]]; then
                print_info "Building iOS (release)..."
                ./scripts/build_ios.sh release development
            else
                print_error "iOS builds require macOS"
            fi
            ;;
        8)
            print_info "Building all platforms (release)..."
            ./scripts/deploy.sh all prod --build-only
            ;;
        9)
            return
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
    echo ""
    read -p "Press Enter to continue..."
}

# Deploy applications
deploy_applications() {
    print_header "Deploy Applications"
    echo ""
    print_option "1." "Deploy Web to Development"
    print_option "2." "Deploy Web to Staging"
    print_option "3." "Deploy Web to Production"
    print_option "4." "Deploy All to Staging"
    print_option "5." "Deploy All to Production"
    print_option "6." "Dry Run (Show what would be deployed)"
    print_option "7." "Back to main menu"
    echo ""
    read -p "Choose deployment option: " deploy_choice
    
    case $deploy_choice in
        1)
            print_info "Deploying web to development..."
            ./scripts/deploy.sh web dev
            ;;
        2)
            print_info "Deploying web to staging..."
            ./scripts/deploy.sh web staging
            ;;
        3)
            print_info "Deploying web to production..."
            ./scripts/deploy.sh web prod
            ;;
        4)
            print_info "Deploying all platforms to staging..."
            ./scripts/deploy.sh all staging
            ;;
        5)
            print_info "Deploying all platforms to production..."
            ./scripts/deploy.sh all prod
            ;;
        6)
            print_info "Dry run - showing what would be deployed..."
            ./scripts/deploy.sh web prod --dry-run
            ;;
        7)
            return
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
    echo ""
    read -p "Press Enter to continue..."
}

# Code quality and analysis
code_quality() {
    print_header "Code Quality & Analysis"
    echo ""
    print_option "1." "Run Flutter Analyze"
    print_option "2." "Run Tests"
    print_option "3." "Format Code"
    print_option "4." "Check Dependencies"
    print_option "5." "Full Quality Check"
    print_option "6." "Back to main menu"
    echo ""
    read -p "Choose option: " quality_choice
    
    case $quality_choice in
        1)
            print_info "Running Flutter analyze..."
            flutter analyze
            ;;
        2)
            print_info "Running tests..."
            flutter test
            ;;
        3)
            print_info "Formatting code..."
            flutter format .
            ;;
        4)
            print_info "Checking dependencies..."
            flutter pub deps
            ;;
        5)
            print_info "Running full quality check..."
            flutter analyze
            flutter test
            flutter format . --set-exit-if-changed
            ;;
        6)
            return
            ;;
        *)
            print_error "Invalid choice"
            ;;
    esac
    echo ""
    read -p "Press Enter to continue..."
}

# Project information
project_info() {
    print_header "Project Information"
    echo ""
    print_info "Flutter Version: $(flutter --version | head -n 1)"
    print_info "Dart Version: $(dart --version)"
    print_info "Project Directory: $(pwd)"
    
    if [ -d "artifacts" ]; then
        echo ""
        print_info "Available Artifacts:"
        find artifacts -type f -exec echo "   {}" \;
    fi
    
    echo ""
    print_info "Available Scripts:"
    ls -la scripts/*.sh | awk '{print "   " $9}'
    
    echo ""
    print_info "Git Status:"
    if command -v git &> /dev/null; then
        git status --porcelain | head -10
        if [ $(git status --porcelain | wc -l) -gt 10 ]; then
            echo "   ... and $(( $(git status --porcelain | wc -l) - 10 )) more files"
        fi
    else
        echo "   Git not available"
    fi
    
    echo ""
    read -p "Press Enter to continue..."
}

# Main loop
main() {
    check_flutter
    
    while true; do
        clear
        echo -e "${BLUE}╔══════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${BLUE}║                    E-Paper Flutter App                      ║${NC}"
        echo -e "${BLUE}║                   Quick Start Menu                          ║${NC}"
        echo -e "${BLUE}╚══════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        show_menu
        read -p "Choose an option (1-7): " choice
        
        case $choice in
            1)
                setup_dependencies
                ;;
            2)
                run_dev_server
                ;;
            3)
                build_applications
                ;;
            4)
                deploy_applications
                ;;
            5)
                code_quality
                ;;
            6)
                project_info
                ;;
            7)
                print_success "Goodbye!"
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please select 1-7."
                sleep 2
                ;;
        esac
    done
}

# Run main function
main
