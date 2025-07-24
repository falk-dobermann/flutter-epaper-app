#!/bin/bash

# E-Paper Development Start Script
# This script starts both the API server and Flutter web app for local development

set -e

echo "🚀 Starting E-Paper Development Environment"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to cleanup background processes on exit
cleanup() {
    echo -e "\n${YELLOW}🛑 Shutting down development environment...${NC}"
    if [ ! -z "$API_PID" ]; then
        echo "Stopping API server (PID: $API_PID)"
        kill $API_PID 2>/dev/null || true
    fi
    if [ ! -z "$FLUTTER_PID" ]; then
        echo "Stopping Flutter app (PID: $FLUTTER_PID)"
        kill $FLUTTER_PID 2>/dev/null || true
    fi
    echo -e "${GREEN}✅ Development environment stopped${NC}"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Check if required tools are installed
echo -e "${BLUE}🔍 Checking prerequisites...${NC}"

if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed. Please install Node.js first.${NC}"
    exit 1
fi

if ! command -v flutter &> /dev/null; then
    echo -e "${RED}❌ Flutter is not installed. Please install Flutter first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Start API server
echo -e "\n${BLUE}📡 Starting API server...${NC}"
cd api-server

# Install dependencies if node_modules doesn't exist
if [ ! -d "node_modules" ]; then
    echo "Installing API server dependencies..."
    npm install
fi

# Start the API server in background
node server.js &
API_PID=$!

# Wait a moment for the server to start
sleep 3

# Check if API server is running
if curl -s http://localhost:3000/health > /dev/null; then
    echo -e "${GREEN}✅ API server started successfully on http://localhost:3000${NC}"
else
    echo -e "${RED}❌ Failed to start API server${NC}"
    kill $API_PID 2>/dev/null || true
    exit 1
fi

# Go back to project root
cd ..

# Start Flutter web app
echo -e "\n${BLUE}🌐 Starting Flutter web app...${NC}"

# Get Flutter dependencies
echo "Getting Flutter dependencies..."
flutter pub get

# Start Flutter in development mode with API configuration
echo "Starting Flutter web app with development configuration..."
flutter run -d chrome \
    --dart-define=ENVIRONMENT=development \
    --dart-define=API_BASE_URL=http://localhost:3000 &
FLUTTER_PID=$!

echo -e "\n${GREEN}🎉 Development environment started successfully!${NC}"
echo -e "${YELLOW}📋 Services running:${NC}"
echo -e "   • API Server: ${BLUE}http://localhost:3000${NC}"
echo -e "   • Flutter App: ${BLUE}Will open in Chrome automatically${NC}"
echo -e "\n${YELLOW}📋 Available API endpoints:${NC}"
echo -e "   • Health check: ${BLUE}http://localhost:3000/health${NC}"
echo -e "   • List PDFs: ${BLUE}http://localhost:3000/api/pdfs${NC}"
echo -e "   • Download PDF: ${BLUE}http://localhost:3000/api/pdfs/:id/download${NC}"
echo -e "\n${YELLOW}💡 Press Ctrl+C to stop all services${NC}"

# Wait for background processes
wait
