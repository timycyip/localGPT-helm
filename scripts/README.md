# 🛠️ LocalGPT Docker Build Scripts

This directory contains helper scripts for building and pushing Docker images to GitHub Container Registry.

## 📋 Available Scripts

### `build-images.sh`
Builds all LocalGPT Docker images for multiple platforms (AMD64 + ARM64).

**Usage:**
```bash
# Build all images with latest tag
./scripts/build-images.sh

# Build with custom tag
./scripts/build-images.sh v1.2.0

# Build for single platform (faster testing)
PLATFORMS=linux/amd64 ./scripts/build-images.sh dev

# Build with different owner
GITHUB_REPOSITORY_OWNER=myorg ./scripts/build-images.sh
```

**Features:**
- Multi-platform support (AMD64 + ARM64)
- Automatic buildx setup
- Git SHA tagging
- Build validation
- Colored output

### `push-images.sh`
Pushes built images to GitHub Container Registry.

**Usage:**
```bash
# Login first
echo $GITHUB_TOKEN | docker login ghcr.io -u timycyip --password-stdin

# Push all images with latest tag
./scripts/push-images.sh

# Push with custom tag
./scripts/push-images.sh v1.2.0
```

**Features:**
- Authentication validation
- Image existence check
- Git SHA tag push
- Helpful error messages
- Colored output

## 🚀 Quick Workflow

### Complete Local Build & Push

```bash
# 1. Build images
./scripts/build-images.sh v1.0.0

# 2. Test locally
IMAGE_TAG=v1.0.0 docker compose -f docker-compose.ghcr.yml up -d

# 3. Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u timycyip --password-stdin

# 4. Push to registry
./scripts/push-images.sh v1.0.0
```

### Development Testing

```bash
# Fast single-platform build for testing
PLATFORMS=linux/amd64 ./scripts/build-images.sh test

# Test the build
docker run -p 3000:3000 ghcr.io/timycyip/localgpt-frontend:test
```

## 🔧 Environment Variables

Both scripts support these environment variables:

- `GITHUB_REPOSITORY_OWNER` - GitHub username/org (default: `timycyip`)
- `PLATFORMS` - Target platforms (default: `linux/amd64,linux/arm64`)
- `GITHUB_TOKEN` - GitHub PAT for authentication (push script only)

## 📝 Requirements

- Docker with Buildx support
- Git (for SHA tagging)
- GitHub Personal Access Token (for pushing)
- Sufficient disk space (~5-10GB)

## 🐛 Troubleshooting

### Build fails with "buildx not found"
```bash
# Install buildx (included in Docker Desktop)
# Or enable buildx in Docker Engine
docker buildx version
```

### Multi-platform build fails
```bash
# Install QEMU for cross-platform builds
docker run --privileged --rm tonistiigi/binfmt --install all
docker buildx ls
```

### Push fails with authentication error
```bash
# Verify token has write:packages scope
gh auth status

# Re-login
echo $GITHUB_TOKEN | docker login ghcr.io -u timycyip --password-stdin
```

### Out of disk space
```bash
# Clean up Docker
docker system prune -a --volumes

# Check buildx cache
docker buildx du
docker buildx prune
```

## 📚 Related Documentation

- [GitHub Registry Setup Guide](../Documentation/github_registry_setup.md)
- [Docker Deployment Guide](../DOCKER_README.md)
- [GitHub Actions Workflow](../.github/workflows/docker-build-push.yml)

## 💡 Tips

1. **Faster builds**: Use `PLATFORMS=linux/amd64` for testing
2. **Caching**: Buildx automatically caches layers
3. **Testing**: Always test locally before pushing
4. **Tagging**: Use semantic versioning (v1.2.3)
5. **Automation**: Prefer GitHub Actions for production builds

---

**Need help?** Check the [troubleshooting guide](../Documentation/github_registry_setup.md#troubleshooting) or open an issue.
