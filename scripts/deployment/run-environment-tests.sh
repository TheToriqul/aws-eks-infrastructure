# File: scripts/deployment/run-environment-tests.sh
#!/bin/bash
set -e

APP_NAME=$1
ENV=$2

echo "Running $ENV environment tests for $APP_NAME..."

# Get application endpoint
if kubectl get ingress -n $ENV $APP_NAME &>/dev/null; then
  APP_ENDPOINT=$(kubectl get ingress -n $ENV $APP_NAME -o jsonpath='{.spec.rules[0].host}')
  PROTOCOL="https"
else
  # Try to get service endpoint
  if kubectl get svc -n $ENV $APP_NAME &>/dev/null; then
    SVC_TYPE=$(kubectl get svc -n $ENV $APP_NAME -o jsonpath='{.spec.type}')
    
    if [ "$SVC_TYPE" == "LoadBalancer" ]; then
      APP_ENDPOINT=$(kubectl get svc -n $ENV $APP_NAME -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
      if [ -z "$APP_ENDPOINT" ]; then
        APP_ENDPOINT=$(kubectl get svc -n $ENV $APP_NAME -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
      fi
    elif [ "$SVC_TYPE" == "ClusterIP" ]; then
      APP_ENDPOINT=$(kubectl get svc -n $ENV $APP_NAME -o jsonpath='{.spec.clusterIP}')
      echo "Note: Service is ClusterIP type. Tests will run in-cluster."
    fi
    
    PROTOCOL="http"
  else
    echo "⚠️ Warning: Could not find service or ingress for $APP_NAME in $ENV namespace"
    APP_ENDPOINT="unknown"
    PROTOCOL="http"
  fi
fi

echo "Using endpoint: $PROTOCOL://$APP_ENDPOINT"

# Create test results directory
mkdir -p test-results/$ENV/$APP_NAME

# Run appropriate test suite based on environment
case $ENV in
  dev)
    echo "Running development tests..."
    
    # Basic health check
    if [ "$APP_ENDPOINT" != "unknown" ]; then
      echo "Performing health check..."
      HEALTH_ENDPOINT="$PROTOCOL://$APP_ENDPOINT/health"
      
      # Use kubectl exec to run curl from within the cluster if needed
      if [ "$SVC_TYPE" == "ClusterIP" ]; then
        RESULT=$(kubectl exec -n $ENV deploy/$APP_NAME -- curl -s -o /dev/null -w "%{http_code}" $HEALTH_ENDPOINT || echo "Failed")
      else
        RESULT=$(curl -s -o /dev/null -w "%{http_code}" $HEALTH_ENDPOINT || echo "Failed")
      fi
      
      if [ "$RESULT" == "200" ]; then
        echo "✅ Health check passed"
      else
        echo "❌ Health check failed with status: $RESULT"
        exit 1
      fi
    fi
    
    # Run unit tests if available
    if [ -d "tests/unit" ]; then
      echo "Running unit tests..."
      cd tests/unit
      npm test || exit 1
      cd ../..
    fi
    ;;
    
  staging)
    echo "Running staging tests..."
    
    # Run integration tests if available
    if [ -d "tests/integration" ]; then
      echo "Running integration tests..."
      cd tests/integration
      TEST_URL="$PROTOCOL://$APP_ENDPOINT" npm test || exit 1
      cd ../..
    fi
    
    # Run performance tests if available
    if [ -d "tests/performance" ]; then
      echo "Running performance tests..."
      cd tests/performance
      TEST_URL="$PROTOCOL://$APP_ENDPOINT" npm test || exit 1
      cd ../..
    fi
    ;;
    
  prod)
    echo "Running production smoke tests..."
    
    # Run smoke tests
    if [ -d "tests/smoke" ]; then
      echo "Running smoke tests..."
      cd tests/smoke
      TEST_URL="$PROTOCOL://$APP_ENDPOINT" npm test || exit 1
      cd ../..
    else
      # Fallback to basic endpoint checks if smoke tests aren't available
      echo "No smoke tests found, performing basic checks..."
      
      # Check main endpoint
      if [ "$APP_ENDPOINT" != "unknown" ]; then
        echo "Checking main endpoint..."
        
        if [ "$SVC_TYPE" == "ClusterIP" ]; then
          RESULT=$(kubectl exec -n $ENV deploy/$APP_NAME -- curl -s -o /dev/null -w "%{http_code}" "$PROTOCOL://$APP_ENDPOINT" || echo "Failed")
        else
          RESULT=$(curl -s -o /dev/null -w "%{http_code}" "$PROTOCOL://$APP_ENDPOINT" || echo "Failed")
        fi
        
        if [[ "$RESULT" =~ ^(200|301|302)$ ]]; then
          echo "✅ Main endpoint check passed"
        else
          echo "❌ Main endpoint check failed with status: $RESULT"
          exit 1
        fi
      fi
    fi
    ;;
    
  *)
    echo "Unknown environment: $ENV"
    exit 1
    ;;
esac

echo "✅ All tests passed for $APP_NAME in $ENV environment"