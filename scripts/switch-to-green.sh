#!/bin/bash

set -e

echo "======================================"
echo "Starting Blue-Green Deployment to GREEN"
echo "======================================"

# Configuration
NAMESPACE="production"
SERVICE_NAME="app-service"
DOCKER_IMAGE="<YOUR_DOCKER_REGISTRY>/myapp:green"

# Step 1: Check current active environment
CURRENT_VERSION=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.selector.version}')
echo "Current active version: $CURRENT_VERSION"

if [ "$CURRENT_VERSION" == "green" ]; then
    echo "Green environment is already active!"
    exit 0
fi

# Step 2: Build and push Docker image with green tag
echo "Building Docker image..."
docker build -t $DOCKER_IMAGE ../app/src/

echo "Pushing Docker image to registry..."
docker push $DOCKER_IMAGE

# Step 3: Deploy to Green environment
echo "Deploying to GREEN environment..."
kubectl apply -f ../k8s/namespace.yaml
kubectl apply -f ../k8s/deployment-green.yaml

# Step 4: Wait for Green deployment to be ready
echo "Waiting for GREEN deployment to be ready..."
kubectl rollout status deployment/myapp-green -n $NAMESPACE --timeout=300s

# Step 5: Run smoke tests on Green environment
echo "Running smoke tests on GREEN environment..."
GREEN_POD=$(kubectl get pods -n $NAMESPACE -l version=green -o jsonpath='{.items[0].metadata.name}')
kubectl port-forward $GREEN_POD 8080:3000 -n $NAMESPACE &
PF_PID=$!
sleep 5

# Simple health check
HEALTH_CHECK=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:8080/health)
kill $PF_PID

if [ "$HEALTH_CHECK" != "200" ]; then
    echo "Health check failed on GREEN environment!"
    exit 1
fi

echo "Smoke tests passed!"

# Step 6: Switch service to Green
echo "Switching traffic to GREEN environment..."
kubectl patch service $SERVICE_NAME -n $NAMESPACE -p '{"spec":{"selector":{"version":"green"}}}'

echo "======================================"
echo "Successfully switched to GREEN environment!"
echo "======================================"

# Step 7: Scale down Blue deployment (optional - keep for rollback)
echo "Scaling down BLUE deployment to 1 replica (keeping for quick rollback)..."
kubectl scale deployment myapp-blue -n $NAMESPACE --replicas=1

echo "Deployment complete! Monitor the GREEN environment."
echo "To rollback, run: ./rollback-to-blue.sh"