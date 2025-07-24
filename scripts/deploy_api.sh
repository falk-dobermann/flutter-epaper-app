#!/bin/bash

# E-Paper API Server Deployment Script
# Deploys the Node.js API server to Google Cloud Run

set -e

# Configuration
PROJECT_ID=${GOOGLE_CLOUD_PROJECT:-"epaper-app"}
SERVICE_NAME="epaper-api"
REGION=${GOOGLE_CLOUD_REGION:-"europe-west1"}
IMAGE_NAME="gcr.io/${PROJECT_ID}/${SERVICE_NAME}"
API_DIR="api-server"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 E-Paper API Server Deployment${NC}"
echo "=================================="

# Check if we're in the right directory
if [ ! -d "$API_DIR" ]; then
    echo -e "${RED}❌ Error: $API_DIR directory not found${NC}"
    echo "Please run this script from the project root directory"
    exit 1
fi

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo -e "${RED}❌ Error: gcloud CLI not found${NC}"
    echo "Please install Google Cloud SDK: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    echo -e "${RED}❌ Error: Docker is not running${NC}"
    echo "Please start Docker and try again"
    exit 1
fi

# Authenticate with Google Cloud (if needed)
echo -e "${YELLOW}🔐 Checking Google Cloud authentication...${NC}"
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q .; then
    echo -e "${YELLOW}⚠️  Not authenticated with Google Cloud${NC}"
    gcloud auth login
fi

# Set the project
echo -e "${YELLOW}📋 Setting Google Cloud project to: ${PROJECT_ID}${NC}"
gcloud config set project $PROJECT_ID

# Enable required APIs
echo -e "${YELLOW}🔧 Enabling required Google Cloud APIs...${NC}"
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com

# Build the Docker image
echo -e "${YELLOW}🏗️  Building Docker image...${NC}"
cd $API_DIR
docker build -t $IMAGE_NAME .
cd ..

# Push the image to Google Container Registry
echo -e "${YELLOW}📤 Pushing image to Google Container Registry...${NC}"
docker push $IMAGE_NAME

# Deploy to Cloud Run
echo -e "${YELLOW}🚀 Deploying to Google Cloud Run...${NC}"
gcloud run deploy $SERVICE_NAME \
    --image $IMAGE_NAME \
    --platform managed \
    --region $REGION \
    --allow-unauthenticated \
    --port 3000 \
    --memory 512Mi \
    --cpu 1 \
    --min-instances 0 \
    --max-instances 10 \
    --timeout 300 \
    --concurrency 80 \
    --set-env-vars "NODE_ENV=production" \
    --set-env-vars "PORT=3000"

# Get the service URL
SERVICE_URL=$(gcloud run services describe $SERVICE_NAME --platform managed --region $REGION --format 'value(status.url)')

echo ""
echo -e "${GREEN}✅ API Server deployment completed successfully!${NC}"
echo ""
echo -e "${BLUE}📋 Deployment Details:${NC}"
echo "  Service Name: $SERVICE_NAME"
echo "  Region: $REGION"
echo "  Image: $IMAGE_NAME"
echo "  Service URL: $SERVICE_URL"
echo ""
echo -e "${BLUE}🔗 API Endpoints:${NC}"
echo "  Health Check: $SERVICE_URL/health"
echo "  List PDFs: $SERVICE_URL/api/pdfs"
echo "  Download PDF: $SERVICE_URL/api/pdfs/{id}/download"
echo "  PDF Thumbnail: $SERVICE_URL/api/pdfs/{id}/thumbnail"
echo "  PDF Metadata: $SERVICE_URL/api/pdfs/{id}/metadata"
echo ""
echo -e "${YELLOW}💡 Next Steps:${NC}"
echo "1. Update your Flutter app's API_BASE_URL to: $SERVICE_URL"
echo "2. Test the API endpoints to ensure they're working correctly"
echo "3. Update your environment configuration files"
echo ""
echo -e "${BLUE}🧪 Test the deployment:${NC}"
echo "curl $SERVICE_URL/health"
