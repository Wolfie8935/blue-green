#!/bin/bash

set -e

echo "======================================"
echo "ROLLING BACK to BLUE environment"
echo "======================================"

# Configuration
NAMESPACE="production"
SERVICE_NAME="app-service"

# Step 1: Check current active environment
CURRENT_VERSION=$(kubectl get service $SERVICE_NAME -n $NAMESPACE -o jsonpath='{.spec.selector.version}')
echo "Current active version: $CURRENT_VERSION"

if [ "$CURRENT_VERSION" == "blue" ]; then
    echo "Blue environment is already active!"
    exit 0
fi

# Step 2: Ensure Blue deployment is ready
echo "Scaling up BLUE deployment..."
kubectl scale deployment myapp-blue -n $NAMESPACE --replicas=3

echo "Waiting for BLUE deployment to be ready..."
kubectl rollout status deployment/myapp-blue -n $NAMESPACE --timeout=300s

# Step 3: Switch service back to Blue
echo "Switching traffic back to BLUE environment..."
kubectl patch service $SERVICE_NAME -n $NAMESPACE -p '{"spec":{"selector":{"version":"blue"}}}'

echo "======================================"
echo "Successfully rolled back to BLUE environment!"
echo "======================================"

# Step 4: Scale down Green deployment
echo "Scaling down GREEN deployment..."
kubectl scale deployment myapp-green -n $NAMESPACE --replicas=0

echo "Rollback complete!"