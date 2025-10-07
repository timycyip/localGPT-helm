#!/bin/bash
set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REGISTRY="ghcr.io"
OWNER="${GITHUB_REPOSITORY_OWNER:-timycyip}"
IMAGE_PREFIX="${REGISTRY}/${OWNER}"
TAG="${1:-latest}"
PLATFORMS="${PLATFORMS:-linux/amd64,linux/arm64}"

echo -e "${BLUE}🐳 LocalGPT Multi-Platform Docker Build${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
echo -e "Registry:   ${GREEN}${REGISTRY}${NC}"
echo -e "Owner:      ${GREEN}${OWNER}${NC}"
echo -e "Tag:        ${GREEN}${TAG}${NC}"
echo -e "Platforms:  ${GREEN}${PLATFORMS}${NC}"
echo ""

# Check if buildx is available
if ! docker buildx version &> /dev/null; then
    echo -e "${RED}❌ Docker Buildx is not available${NC}"
    echo "Please install Docker Desktop or enable buildx"
    exit 1
fi

# Create/use buildx builder
echo -e "${YELLOW}Setting up buildx builder...${NC}"
if ! docker buildx inspect localgpt-builder &> /dev/null; then
    docker buildx create --name localgpt-builder --use --bootstrap
else
    docker buildx use localgpt-builder
fi

# Function to build an image
build_image() {
    local service=$1
    local dockerfile=$2
    local image="${IMAGE_PREFIX}/localgpt-${service}:${TAG}"
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📦 Building: ${service}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Image: ${GREEN}${image}${NC}"
    echo -e "Dockerfile: ${dockerfile}"
    echo ""
    
    docker buildx build \
        --platform "${PLATFORMS}" \
        --file "${dockerfile}" \
        --tag "${image}" \
        --tag "${IMAGE_PREFIX}/localgpt-${service}:$(git rev-parse --short HEAD)" \
        --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
        --build-arg VCS_REF="$(git rev-parse --short HEAD)" \
        --load \
        . || {
            echo -e "${RED}❌ Failed to build ${service}${NC}"
            return 1
        }
    
    echo -e "${GREEN}✅ Successfully built ${service}${NC}"
}

# Build all images
echo -e "${YELLOW}Starting build process...${NC}"
echo ""

BUILD_FAILED=0

build_image "frontend" "Dockerfile.frontend" || BUILD_FAILED=1
build_image "backend" "Dockerfile.backend" || BUILD_FAILED=1
build_image "rag-api" "Dockerfile.rag-api" || BUILD_FAILED=1

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ $BUILD_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All images built successfully!${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Built images:${NC}"
    echo -e "  • ${IMAGE_PREFIX}/localgpt-frontend:${TAG}"
    echo -e "  • ${IMAGE_PREFIX}/localgpt-backend:${TAG}"
    echo -e "  • ${IMAGE_PREFIX}/localgpt-rag-api:${TAG}"
    echo ""
    echo -e "${YELLOW}To push these images, run:${NC}"
    echo -e "  ${GREEN}./scripts/push-images.sh ${TAG}${NC}"
    echo ""
    echo -e "${YELLOW}To test locally:${NC}"
    echo -e "  ${GREEN}docker compose -f docker-compose.ghcr.yml up -d${NC}"
else
    echo -e "${RED}❌ Some builds failed${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
fi
