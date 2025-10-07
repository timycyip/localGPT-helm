# LocalGPT Helm Chart

This Helm chart deploys the LocalGPT RAG (Retrieval-Augmented Generation) system on Kubernetes.

## Architecture

The chart deploys four main components:

1. **Ollama** (optional) - LLM inference service
2. **RAG API** - RAG API server for document indexing and retrieval
3. **Backend** - Backend API server
4. **Frontend** - Next.js frontend application

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure (for persistent storage)
- Container images built and pushed to a registry

## Building and Pushing Images

Before deploying the Helm chart, you need to build and push the container images:

```bash
# Set your registry
export REGISTRY="your-registry.example.com/localgpt"

# Build images
docker build -t ${REGISTRY}/rag-api:latest -f Dockerfile.rag-api .
docker build -t ${REGISTRY}/backend:latest -f Dockerfile.backend .
docker build -t ${REGISTRY}/frontend:latest -f Dockerfile.frontend .

# Push images
docker push ${REGISTRY}/rag-api:latest
docker push ${REGISTRY}/backend:latest
docker push ${REGISTRY}/frontend:latest
```

## Installation

### Default Installation (with Ollama)

```bash
helm install localgpt ./helm-chart \
  --set ragApi.image.repository=your-registry.example.com/localgpt/rag-api \
  --set backend.image.repository=your-registry.example.com/localgpt/backend \
  --set frontend.image.repository=your-registry.example.com/localgpt/frontend
```

### Using External Ollama (Same Namespace)

```bash
helm install localgpt ./helm-chart \
  --set ollama.enabled=false \
  --set ollama.external.enabled=true \
  --set ollama.external.host=http://ollama-service:11434 \
  --set ragApi.image.repository=your-registry.example.com/localgpt/rag-api \
  --set backend.image.repository=your-registry.example.com/localgpt/backend \
  --set frontend.image.repository=your-registry.example.com/localgpt/frontend
```

### Using External Ollama (Different Namespace)

```bash
helm install localgpt ./helm-chart \
  --set ollama.enabled=false \
  --set ollama.external.enabled=true \
  --set ollama.external.host=http://ollama-service.ollama-namespace.svc.cluster.local:11434 \
  --set ollama.external.namespace=ollama-namespace \
  --set ragApi.image.repository=your-registry.example.com/localgpt/rag-api \
  --set backend.image.repository=your-registry.example.com/localgpt/backend \
  --set frontend.image.repository=your-registry.example.com/localgpt/frontend
```

### With Ingress Enabled

```bash
helm install localgpt ./helm-chart \
  --set ingress.enabled=true \
  --set ingress.hosts[0].host=localgpt.example.com \
  --set ingress.tls[0].secretName=localgpt-tls \
  --set ingress.tls[0].hosts[0]=localgpt.example.com \
  --set ragApi.image.repository=your-registry.example.com/localgpt/rag-api \
  --set backend.image.repository=your-registry.example.com/localgpt/backend \
  --set frontend.image.repository=your-registry.example.com/localgpt/frontend
```

## Configuration

The following table lists the configurable parameters and their default values.

### Global Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `global.imagePullPolicy` | Global image pull policy | `Always` |
| `global.imagePullSecrets` | Global image pull secrets | `[]` |
| `global.storageClass` | Global storage class | `""` |

### Ollama Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ollama.enabled` | Enable Ollama deployment | `true` |
| `ollama.external.enabled` | Use external Ollama service | `false` |
| `ollama.external.host` | External Ollama host URL | `http://ollama-service:11434` |
| `ollama.external.namespace` | External Ollama namespace | `""` |
| `ollama.image.repository` | Ollama image repository | `ollama/ollama` |
| `ollama.image.tag` | Ollama image tag | `latest` |
| `ollama.service.type` | Ollama service type | `ClusterIP` |
| `ollama.service.port` | Ollama service port | `11434` |
| `ollama.persistence.enabled` | Enable persistence for Ollama | `true` |
| `ollama.persistence.size` | Size of persistent volume | `20Gi` |
| `ollama.resources.limits.cpu` | CPU limit | `4000m` |
| `ollama.resources.limits.memory` | Memory limit | `8Gi` |

### RAG API Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ragApi.replicaCount` | Number of replicas | `1` |
| `ragApi.image.repository` | RAG API image repository | `localgpt/rag-api` |
| `ragApi.image.tag` | RAG API image tag | `latest` |
| `ragApi.service.port` | Service port | `8001` |
| `ragApi.persistence.lancedb.size` | LanceDB storage size | `10Gi` |
| `ragApi.persistence.indexStore.size` | Index store size | `5Gi` |

### Backend Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `backend.replicaCount` | Number of replicas | `1` |
| `backend.image.repository` | Backend image repository | `localgpt/backend` |
| `backend.image.tag` | Backend image tag | `latest` |
| `backend.service.port` | Service port | `8000` |
| `backend.persistence.size` | Backend storage size | `2Gi` |

### Frontend Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `frontend.replicaCount` | Number of replicas | `1` |
| `frontend.image.repository` | Frontend image repository | `localgpt/frontend` |
| `frontend.image.tag` | Frontend image tag | `latest` |
| `frontend.service.port` | Service port | `3000` |

### Shared Storage

| Parameter | Description | Default |
|-----------|-------------|---------|
| `sharedUploads.enabled` | Enable shared uploads storage | `true` |
| `sharedUploads.size` | Size of shared storage | `5Gi` |
| `sharedUploads.accessMode` | Access mode | `ReadWriteMany` |

### Ingress Configuration

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class name | `traefik` |
| `ingress.annotations` | Ingress annotations | See values.yaml |
| `ingress.hosts` | Ingress hosts configuration | See values.yaml |
| `ingress.tls` | Ingress TLS configuration | See values.yaml |

## Upgrading

```bash
helm upgrade localgpt ./helm-chart \
  --set ragApi.image.repository=your-registry.example.com/localgpt/rag-api \
  --set backend.image.repository=your-registry.example.com/localgpt/backend \
  --set frontend.image.repository=your-registry.example.com/localgpt/frontend
```

## Uninstalling

```bash
helm uninstall localgpt
```

**Note:** This will not delete the PersistentVolumeClaims. To delete them:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=localgpt
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/instance=localgpt
```

### View Logs

```bash
# Ollama logs
kubectl logs -l app.kubernetes.io/component=ollama

# RAG API logs
kubectl logs -l app.kubernetes.io/component=rag-api

# Backend logs
kubectl logs -l app.kubernetes.io/component=backend

# Frontend logs
kubectl logs -l app.kubernetes.io/component=frontend
```

### Check Services

```bash
kubectl get svc -l app.kubernetes.io/instance=localgpt
```

### Check Persistent Volumes

```bash
kubectl get pvc -l app.kubernetes.io/instance=localgpt
```

## License

Same as LocalGPT project
