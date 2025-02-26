# File: scripts/deployment/promote.sh
#!/bin/bash
set -e

APP_NAME=$1
SOURCE_ENV=$2
TARGET_ENV=$3
VERSION=$4

# Check inputs
if [ -z "$APP_NAME" ] || [ -z "$SOURCE_ENV" ] || [ -z "$TARGET_ENV" ] || [ -z "$VERSION" ]; then
  echo "Usage: $0 <app-name> <source-env> <target-env> <version>"
  echo "Example: $0 api-service dev staging 1.0.0"
  exit 1
fi

echo "=== Promoting $APP_NAME version $VERSION from $SOURCE_ENV to $TARGET_ENV ==="

# Validate configuration
echo "Validating configuration..."
./scripts/deployment/validate-config.sh $APP_NAME $SOURCE_ENV $TARGET_ENV

# Run tests in source environment to confirm stability
echo "Running tests in $SOURCE_ENV environment..."
./scripts/deployment/run-environment-tests.sh $APP_NAME $SOURCE_ENV

# Get approval for promotion
if [ "$TARGET_ENV" = "prod" ]; then
  echo ""
  echo "⚠️ PRODUCTION DEPLOYMENT REQUIRES APPROVAL ⚠️"
  echo ""
  read -p "Has this deployment been approved (y/n)? " APPROVAL
  if [ "$APPROVAL" != "y" ]; then
    echo "Deployment aborted: Approval required for production deployments."
    exit 1
  fi
  
  # Additional confirmation for production
  echo ""
  echo "Are you sure you want to deploy $APP_NAME version $VERSION to PRODUCTION?"
  echo "This will affect real users."
  echo ""
  read -p "Confirm production deployment (y/n)? " CONFIRM
  if [ "$CONFIRM" != "y" ]; then
    echo "Deployment aborted by user."
    exit 1
  fi
fi

# Deploy to target environment
echo "Deploying to $TARGET_ENV environment..."
./scripts/deployment/helm-release.sh $APP_NAME $TARGET_ENV $VERSION

# Wait for deployment to stabilize
echo "Waiting for deployment to stabilize..."
sleep 30  # Give the application time to start

# Run tests in target environment to confirm successful deployment
echo "Running tests in $TARGET_ENV environment..."
./scripts/deployment/run-environment-tests.sh $APP_NAME $TARGET_ENV

# Record promotion in audit log
TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
AUDIT_DIR="logs"
mkdir -p $AUDIT_DIR
echo "$TIMESTAMP | $APP_NAME | $VERSION | $SOURCE_ENV -> $TARGET_ENV | $(whoami)" >> $AUDIT_DIR/promotion-audit.log

echo "=== Promotion complete ==="
echo "✅ $APP_NAME version $VERSION successfully promoted from $SOURCE_ENV to $TARGET_ENV"