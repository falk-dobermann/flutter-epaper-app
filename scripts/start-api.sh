#!/bin/bash

# E-Paper API Server Start Script
# This script starts only the API server for development

set -e

echo "🚀 Starting E-Paper API Server"
echo "==============================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to cleanup on exit
cleanup() {
    echo -e "\n${YELLOW}🛑 Shutting down API server...${NC}"
    if [ ! -z "$API_PID" ]; then
        echo "Stopping API server (PID: $API_PID)"
        kill $API_PID 2>/dev/null || true
    fi
    echo -e "${GREEN}✅ API server stopped${NC}"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Check if Node.js is installed
echo -e "${BLUE}🔍 Checking prerequisites...${NC}"

if ! command -v node &> /dev/null; then
    echo -e "${RED}❌ Node.js is not installed. Please install Node.js first.${NC}"
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

# Start the API server
echo "Starting API server..."
node server.js &
API_PID=$!

# Wait a moment for the server to start
sleep 3

# Check if API server is running
if curl -s http://localhost:3000/health > /dev/null; then
    echo -e "\n${GREEN}🎉 API server started successfully!${NC}"
    echo -e "${YELLOW}📋 Server running on: ${BLUE}http://localhost:3000${NC}"
    echo -e "\n${YELLOW}📋 Available API endpoints:${NC}"
    echo -e "   • Health check: ${BLUE}http://localhost:3000/health${NC}"
    echo -e "   • List PDFs: ${BLUE}http://localhost:3000/api/pdfs${NC}"
    echo -e "   • Download PDF: ${BLUE}http://localhost:3000/api/pdfs/:id/download${NC}"
    echo -e "   • PDF metadata: ${BLUE}http://localhost:3000/api/pdfs/:id/metadata${NC}"
    echo -e "   • PDF thumbnail: ${BLUE}http://localhost:3000/api/pdfs/:id/thumbnail${NC}"
    echo -e "\n${YELLOW}💡 Press Ctrl+C to stop the server${NC}"
else
    echo -e "${RED}❌ Failed to start API server${NC}"
    kill $API_PID 2>/dev/null || true
    exit 1
fi

# Wait for the server process
wait $API_PID
