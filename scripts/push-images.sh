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

echo -e "${BLUE}🚀 LocalGPT Docker Image Push${NC}"
echo -e "${BLUE}==============================${NC}"
echo ""
echo -e "Registry:   ${GREEN}${REGISTRY}${NC}"
echo -e "Owner:      ${GREEN}${OWNER}${NC}"
echo -e "Tag:        ${GREEN}${TAG}${NC}"
echo ""

# Check if logged in to GHCR
echo -e "${YELLOW}Checking authentication...${NC}"
if ! docker info | grep -q "Username"; then
    echo -e "${RED}❌ Not logged in to Docker registry${NC}"
    echo ""
    echo -e "${YELLOW}Please log in to GitHub Container Registry:${NC}"
    echo -e "  ${GREEN}echo \$GITHUB_TOKEN | docker login ghcr.io -u USERNAME --password-stdin${NC}"
    echo ""
    echo -e "${YELLOW}Or create a Personal Access Token:${NC}"
    echo "  1. Go to https://github.com/settings/tokens"
    echo "  2. Generate new token with 'write:packages' scope"
    echo "  3. Run: echo YOUR_TOKEN | docker login ghcr.io -u USERNAME --password-stdin"
    echo ""
    exit 1
fi

# Function to push an image
push_image() {
    local service=$1
    local image="${IMAGE_PREFIX}/localgpt-${service}:${TAG}"
    
    echo ""
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${YELLOW}📤 Pushing: ${service}${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "Image: ${GREEN}${image}${NC}"
    echo ""
    
    # Check if image exists locally
    if ! docker image inspect "${image}" &> /dev/null; then
        echo -e "${RED}❌ Image not found locally: ${image}${NC}"
        echo -e "${YELLOW}Please build it first with: ./scripts/build-images.sh${NC}"
        return 1
    fi
    
    docker push "${image}" || {
        echo -e "${RED}❌ Failed to push ${service}${NC}"
        return 1
    }
    
    # Also push the git SHA tag if it exists
    local sha_tag="${IMAGE_PREFIX}/localgpt-${service}:$(git rev-parse --short HEAD)"
    if docker image inspect "${sha_tag}" &> /dev/null; then
        docker push "${sha_tag}" || true
    fi
    
    echo -e "${GREEN}✅ Successfully pushed ${service}${NC}"
}

# Push all images
echo -e "${YELLOW}Starting push process...${NC}"
echo ""

PUSH_FAILED=0

push_image "frontend" || PUSH_FAILED=1
push_image "backend" || PUSH_FAILED=1
push_image "rag-api" || PUSH_FAILED=1

echo ""
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
if [ $PUSH_FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All images pushed successfully!${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    echo -e "${YELLOW}Pushed images:${NC}"
    echo -e "  • ${IMAGE_PREFIX}/localgpt-frontend:${TAG}"
    echo -e "  • ${IMAGE_PREFIX}/localgpt-backend:${TAG}"
    echo -e "  • ${IMAGE_PREFIX}/localgpt-rag-api:${TAG}"
    echo ""
    echo -e "${YELLOW}View packages at:${NC}"
    echo -e "  ${GREEN}https://github.com/${OWNER}?tab=packages${NC}"
    echo ""
    echo -e "${YELLOW}To use these images:${NC}"
    echo -e "  ${GREEN}docker compose -f docker-compose.ghcr.yml up -d${NC}"
    echo ""
    echo -e "${YELLOW}Make packages public:${NC}"
    echo "  1. Go to https://github.com/${OWNER}?tab=packages"
    echo "  2. Click on each package"
    echo "  3. Package settings → Change visibility → Public"
else
    echo -e "${RED}❌ Some pushes failed${NC}"
    echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    exit 1
fi
