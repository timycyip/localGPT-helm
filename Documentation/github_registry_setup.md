# 📦 GitHub Container Registry (GHCR) Setup Guide

This guide covers setting up automated Docker image builds and publishing to GitHub Container Registry for the LocalGPT project.

## 🎯 Overview

The project uses GitHub Actions to automatically build multi-platform Docker images (AMD64 + ARM64) and publish them to GitHub Container Registry (GHCR).

### Built Images

- `ghcr.io/timycyip/localgpt-frontend` - Next.js web interface
- `ghcr.io/timycyip/localgpt-backend` - Python backend API
- `ghcr.io/timycyip/localgpt-rag-api` - RAG system API

## 🚀 Quick Start

### Using Pre-built Images

```bash
# Pull latest images
docker pull ghcr.io/timycyip/localgpt-frontend:latest
docker pull ghcr.io/timycyip/localgpt-backend:latest
docker pull ghcr.io/timycyip/localgpt-rag-api:latest

# Or use docker-compose
docker compose -f docker-compose.ghcr.yml up -d
```

### Building Locally

```bash
# Build all images for multiple platforms
chmod +x scripts/*.sh
./scripts/build-images.sh

# Push to GHCR (requires authentication)
./scripts/push-images.sh
```

## 🔧 Initial Setup

### 1. Repository Permissions (One-time Setup)

The GitHub Actions workflow uses `GITHUB_TOKEN` which is automatically provided. No manual token creation needed for CI/CD.

**For manual pushes**, create a Personal Access Token:

1. Go to https://github.com/settings/tokens
2. Click "Generate new token (classic)"
3. Set scopes:
   - ✅ `write:packages`
   - ✅ `read:packages`
   - ✅ `delete:packages` (optional, for cleanup)
4. Generate and save the token securely

### 2. Make Packages Public (After First Build)

After the first workflow run:

1. Go to https://github.com/timycyip?tab=packages
2. Click on each package (localgpt-frontend, localgpt-backend, localgpt-rag-api)
3. Click "Package settings"
4. Under "Danger Zone" → "Change package visibility"
5. Select "Public"
6. Confirm the change

### 3. Local Authentication (For Manual Pushes)

```bash
# Login to GHCR
echo $GITHUB_TOKEN | docker login ghcr.io -u timycyip --password-stdin

# Verify login
docker info | grep Username
```

## 🔄 Automated CI/CD Workflow

### Triggers

The GitHub Actions workflow (`.github/workflows/docker-build-push.yml`) runs automatically:

**✅ Push to main branch**
```bash
git push origin main
```
- Builds all 3 images
- Tags with `latest`, `sha-<commit>`, branch name
- Pushes to GHCR

**✅ Pull Request to main**
```bash
# PR created/updated
```
- Builds all 3 images (validates build)
- Tags with `pr-<number>`
- Does NOT push (build validation only)

**✅ Scheduled builds (Bi-weekly)**
- Runs automatically on the 1st and 15th of each month at 2 AM UTC
- Rebuilds all images with latest base images and dependencies
- Updates `latest` tag
- Ensures images have latest security patches

**✅ Manual trigger**
- Go to Actions → "Build and Push Docker Images"
- Click "Run workflow"
- Optionally provide custom tag suffix

### Image Tags

Each image is tagged with multiple tags for flexibility:

| Tag Format | Example | When Applied |
|------------|---------|--------------|
| `latest` | `localgpt-frontend:latest` | On push to main |
| `pr-<number>` | `localgpt-frontend:pr-123` | On pull request #123 |
| `sha-<short>` | `localgpt-frontend:sha-a1b2c3d` | Every build (short SHA) |
| `sha-<long>` | `localgpt-frontend:sha-a1b2c3d4e5f6...` | Every build (full SHA) |
| `<branch>` | `localgpt-frontend:develop` | Branch name |
| `<timestamp>` | `localgpt-frontend:20250107-220530` | Manual runs |
| Custom | `localgpt-frontend:staging` | Manual input |

### Build Features

- ⚡ **Multi-platform**: AMD64 + ARM64 support
- 🔄 **Layer caching**: Faster subsequent builds
- 📊 **Build summaries**: Detailed GitHub Actions summaries
- 🛡️ **Security**: Automatic SBOM and provenance (disabled for compatibility)
- 🔀 **Parallel builds**: All 3 images build simultaneously
- ✅ **Health checks**: Validates images after build

## 🛠️ Local Development Workflow

### Build Images Locally

```bash
# Build all images with default tag (latest)
./scripts/build-images.sh

# Build with custom tag
./scripts/build-images.sh v1.2.0

# Build single platform (faster for testing)
PLATFORMS=linux/amd64 ./scripts/build-images.sh dev

# Build with different owner
GITHUB_REPOSITORY_OWNER=myorg ./scripts/build-images.sh
```

### Push Images to GHCR

```bash
# Login first
echo $GITHUB_TOKEN | docker login ghcr.io -u timycyip --password-stdin

# Push all images with latest tag
./scripts/push-images.sh

# Push with custom tag
./scripts/push-images.sh v1.2.0
```

### Test Built Images

```bash
# Use GHCR images with docker-compose
docker compose -f docker-compose.ghcr.yml up -d

# Or specify a tag
IMAGE_TAG=sha-a1b2c3d docker compose -f docker-compose.ghcr.yml up -d

# Test specific service
docker run -p 3000:3000 ghcr.io/timycyip/localgpt-frontend:latest
```

## 📋 Common Tasks

### View Build Status

```bash
# Check latest workflow run
gh workflow view "Build and Push Docker Images"

# List recent runs
gh run list --workflow=docker-build-push.yml

# Watch live build
gh run watch
```

### Pull Specific Version

```bash
# Pull by commit SHA
docker pull ghcr.io/timycyip/localgpt-frontend:sha-a1b2c3d

# Pull PR build (testing)
docker pull ghcr.io/timycyip/localgpt-frontend:pr-123

# Pull specific branch
docker pull ghcr.io/timycyip/localgpt-frontend:develop
```

### Manually Trigger Build

**Via GitHub UI:**
1. Go to Actions tab
2. Select "Build and Push Docker Images"
3. Click "Run workflow"
4. Select branch
5. (Optional) Enter custom tag suffix
6. Click "Run workflow"

**Via GitHub CLI:**
```bash
# Trigger on main branch
gh workflow run docker-build-push.yml

# Trigger with custom tag
gh workflow run docker-build-push.yml -f tag_suffix=staging
```

### List All Published Images

```bash
# Via GitHub CLI
gh api /users/timycyip/packages/container/localgpt-frontend/versions

# Via web
# Visit: https://github.com/timycyip?tab=packages
```

## 🧹 Maintenance

### Clean Up Old Images

```bash
# Delete specific tag (requires delete:packages scope)
gh api -X DELETE /user/packages/container/localgpt-frontend/versions/<VERSION_ID>

# Local cleanup
docker image prune -a
```

### Update Workflow

Edit `.github/workflows/docker-build-push.yml` to:
- Change platforms
- Modify tag strategy
- Add build arguments
- Change trigger conditions

### Rebuild All Images

```bash
# Force rebuild without cache
docker buildx build --no-cache --platform linux/amd64,linux/arm64 \
  -f Dockerfile.frontend -t ghcr.io/timycyip/localgpt-frontend:latest .
```

## 🐛 Troubleshooting

### Build Fails in GitHub Actions

**Check logs:**
```bash
gh run view --log
```

**Common issues:**
- Dockerfile syntax errors → Check Dockerfile
- Missing files → Verify .gitignore isn't excluding needed files
- Platform build failure → Test locally with same platform
- Out of disk space → GitHub runners have 14GB disk, optimize image size

### Cannot Push Images

**Authentication failure:**
```bash
# Re-login
echo $GITHUB_TOKEN | docker login ghcr.io -u timycyip --password-stdin

# Verify token has write:packages scope
gh auth status
```

**Permission denied:**
- Ensure repository has "Read and write permissions" in Settings → Actions → General → Workflow permissions

### Multi-platform Build Issues

**QEMU not available:**
```bash
# Install QEMU
docker run --privileged --rm tonistiigi/binfmt --install all

# Verify
docker buildx ls
```

**Platform-specific failures:**
```bash
# Test each platform separately
docker buildx build --platform linux/amd64 -f Dockerfile.frontend .
docker buildx build --platform linux/arm64 -f Dockerfile.frontend .
```

### Images Too Large

**Check image sizes:**
```bash
docker images ghcr.io/timycyip/localgpt-*
```

**Optimization tips:**
- Use multi-stage builds
- Minimize layers
- Use `.dockerignore`
- Clean up package caches
- Use slim/alpine base images

## 📊 Monitoring & Metrics

### Build Time

Typical build times:
- Frontend: ~5-8 minutes (both platforms)
- Backend: ~3-5 minutes (both platforms)
- RAG API: ~4-6 minutes (both platforms)
- **Total: ~12-20 minutes** (parallel execution)

### Image Sizes

Expected compressed sizes:
- Frontend: ~200-300 MB
- Backend: ~500-600 MB
- RAG API: ~1.5-2 GB (includes ML models)

### GitHub Actions Limits

- **Storage**: 500MB packages for free accounts
- **Transfer**: 1GB/month for free accounts
- **Build time**: 2,000 minutes/month for free accounts
- **Concurrent jobs**: 20 for public repos

## 🔐 Security Best Practices

### ✅ DO

- Use GitHub's automatic `GITHUB_TOKEN`
- Rotate Personal Access Tokens regularly
- Use read-only tokens where possible
- Enable vulnerability scanning
- Keep base images updated

### ❌ DON'T

- Commit tokens to repository
- Use admin tokens for builds
- Expose tokens in logs
- Store secrets in Dockerfiles
- Use outdated base images

## 📚 Additional Resources

- [GitHub Packages Documentation](https://docs.github.com/en/packages)
- [Docker Buildx Documentation](https://docs.docker.com/buildx/working-with-buildx/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [GHCR Pricing](https://docs.github.com/en/billing/managing-billing-for-github-packages/about-billing-for-github-packages)

## 🆘 Getting Help

- Check workflow logs: `gh run view --log`
- View package details: https://github.com/timycyip?tab=packages
- Review Dockerfile: Check for syntax errors
- Test locally: Use `scripts/build-images.sh`
- GitHub Discussions: Open an issue for help

---

**Last Updated:** 2025-01-07  
**Maintainer:** @timycyip
