# Helm Release Script 
# File: scripts/deployment/helm-release.sh


#!/bin/bash
set -e

# Variables
APP_NAME=$1
ENV=$2
VERSION=$3
NAMESPACE="${ENV}"

# Validate inputs
if [ -z "$APP_NAME" ] || [ -z "$ENV" ] || [ -z "$VERSION" ]; then
    echo "Usage: $0 <app-name> <environment> <version>"
    echo "Example: $0 api-service dev 1.0.0"
    exit 1
fi

# Check if application exists
if [ ! -d "helm/applications/${APP_NAME}" ]; then
    echo "❌ Application '${APP_NAME}' not found in helm/applications/"
    exit 1
fi

# Check if environment exists
if [ ! -d "helm/environment-configs/${ENV}" ]; then
    echo "❌ Environment '${ENV}' not found in helm/environment-configs/"
    exit 1
fi

echo "=== Deploying ${APP_NAME} version ${VERSION} to ${ENV} environment ==="

# Update the application version in Chart.yaml
yq eval ".appVersion = \"${VERSION}\"" -i "helm/applications/${APP_NAME}/Chart.yaml"

# Create namespace if it doesn't exist
kubectl get namespace ${NAMESPACE} >/dev/null 2>&1 || kubectl create namespace ${NAMESPACE}

# Install/upgrade the release
helm upgrade --install ${APP_NAME} "./helm/applications/${APP_NAME}" \
    --namespace ${NAMESPACE} \
    --values "./helm/environment-configs/${ENV}/values.yaml" \
    --values "./helm/applications/${APP_NAME}/values.yaml" \
    --set app-template.image.tag=${VERSION} \
    --set-string app-template.podAnnotations.deployTime="$(date +%s)"

# Wait for deployment to complete
kubectl rollout status deployment/${APP_NAME} -n ${NAMESPACE} --timeout=300s

echo "✅ Deployment complete!"

# Check deployment health
READY_PODS=$(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=${APP_NAME} -o jsonpath='{.items[*].status.containerStatuses[0].ready}' | tr -d '[[:space:]]')
TOTAL_PODS=$(kubectl get pods -n ${NAMESPACE} -l app.kubernetes.io/name=${APP_NAME} --no-headers | wc -l)

echo "Pod status: ${READY_PODS}/${TOTAL_PODS} ready"

# Get service endpoints
if kubectl get ingress -n ${NAMESPACE} ${APP_NAME} >/dev/null 2>&1; then
    INGRESS_HOST=$(kubectl get ingress -n ${NAMESPACE} ${APP_NAME} -o jsonpath='{.spec.rules[0].host}')
    echo "Application is accessible at: https://${INGRESS_HOST}"
fi

echo "=== Deployment summary ==="
echo "Application: ${APP_NAME}"
echo "Environment: ${ENV}"
echo "Version: ${VERSION}"
echo "Namespace: ${NAMESPACE}"
echo "Deployment time: $(date)"