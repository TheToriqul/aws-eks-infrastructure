# File: scripts/deployment/validate-config.sh
#!/bin/bash
set -e

APP_NAME=$1
SOURCE_ENV=$2
TARGET_ENV=$3

echo "Validating configuration for $APP_NAME from $SOURCE_ENV to $TARGET_ENV..."

# Check if source environment exists
if [ ! -d "helm/environment-configs/$SOURCE_ENV" ]; then
    echo "❌ Source environment '$SOURCE_ENV' not found in helm/environment-configs/"
    exit 1
fi

# Check if target environment exists
if [ ! -d "helm/environment-configs/$TARGET_ENV" ]; then
    echo "❌ Target environment '$TARGET_ENV' not found in helm/environment-configs/"
    exit 1
fi

# Check if application exists
if [ ! -d "helm/applications/$APP_NAME" ]; then
    echo "❌ Application '$APP_NAME' not found in helm/applications/"
    exit 1
fi

# Create temporary directory for validation
TEMP_DIR=$(mktemp -d)
trap "rm -rf $TEMP_DIR" EXIT

# Check for required configuration
echo "Generating Kubernetes manifests for validation..."
helm template --values helm/environment-configs/$TARGET_ENV/values.yaml \
              --values helm/applications/$APP_NAME/values.yaml \
              --output-dir $TEMP_DIR \
              helm/applications/$APP_NAME

# Validate Kubernetes resources
echo "Validating Kubernetes manifests..."
kubectl apply --dry-run=client -f $TEMP_DIR/$APP_NAME/templates/

# Check for missing environment variables
echo "Checking for required environment variables..."
REQUIRED_ENV_VARS=$(grep -o "name: [A-Z_][A-Z0-9_]*" $TEMP_DIR/$APP_NAME/templates/deployment.yaml | awk '{print $2}')

SOURCE_ENV_VARS=$(grep -o "name: [A-Z_][A-Z0-9_]*" helm/environment-configs/$SOURCE_ENV/values.yaml | awk '{print $2}')
TARGET_ENV_VARS=$(grep -o "name: [A-Z_][A-Z0-9_]*" helm/environment-configs/$TARGET_ENV/values.yaml | awk '{print $2}')

MISSING_VARS=false
for VAR in $REQUIRED_ENV_VARS; do
  if echo "$SOURCE_ENV_VARS" | grep -q "$VAR" && ! echo "$TARGET_ENV_VARS" | grep -q "$VAR"; then
    echo "⚠️ Warning: Environment variable $VAR exists in $SOURCE_ENV but not in $TARGET_ENV"
    MISSING_VARS=true
  fi
done

if [ "$MISSING_VARS" = true ]; then
  echo "⚠️ Some environment variables may need to be defined in $TARGET_ENV"
fi

# Validate required secrets
echo "Checking for required secrets..."
REQUIRED_SECRETS=$(grep -o "secretName: [a-zA-Z0-9-]*" $TEMP_DIR/$APP_NAME/templates/* | awk '{print $2}' | sort | uniq)

if [ -n "$REQUIRED_SECRETS" ]; then
  echo "The following secrets will be required in the $TARGET_ENV environment:"
  echo "$REQUIRED_SECRETS"
fi

# Check resource limits
echo "Validating resource requirements..."
SOURCE_LIMITS=$(yq eval '.resources.limits' helm/environment-configs/$SOURCE_ENV/values.yaml)
TARGET_LIMITS=$(yq eval '.resources.limits' helm/environment-configs/$TARGET_ENV/values.yaml)

if [ "$SOURCE_LIMITS" != "$TARGET_LIMITS" ]; then
  echo "Note: Resource limits differ between environments"
  echo "Source ($SOURCE_ENV): $SOURCE_LIMITS"
  echo "Target ($TARGET_ENV): $TARGET_LIMITS"
fi

# Validate schema if available
if [ -f "helm/applications/$APP_NAME/values.schema.json" ]; then
  echo "Validating values against schema..."
  helm lint --strict helm/applications/$APP_NAME \
    --values helm/environment-configs/$TARGET_ENV/values.yaml \
    --values helm/applications/$APP_NAME/values.yaml
fi

echo "✅ Configuration validation complete"