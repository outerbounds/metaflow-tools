#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if Helm is installed
if ! command -v helm &> /dev/null; then
    print_error "Helm is not installed. Please install Helm first."
    exit 1
fi

print_status "Starting Helm chart validation..."

# Change to the metaflow chart directory
cd "$(dirname "$0")"

# Add required repositories
print_status "Adding Helm repositories..."
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update

# Build dependencies
print_status "Building chart dependencies..."
helm dependency build
helm dependency update

# Lint the main chart
print_status "Linting main chart..."
if helm lint .; then
    print_status "Main chart linting passed"
else
    print_error "Main chart linting failed"
    exit 1
fi

# Lint subcharts
print_status "Linting subcharts..."
for subchart in charts/metaflow-service charts/metaflow-ui; do
    if [ -d "$subchart" ]; then
        print_status "Linting $subchart..."
        if helm lint "$subchart"; then
            print_status "$subchart linting passed"
        else
            print_error "$subchart linting failed"
            exit 1
        fi
    fi
done

# Test template rendering with different configurations
print_status "Testing template rendering..."

# Test 1: Default values
print_status "Testing with default values..."
if helm template test-default . > /dev/null; then
    print_status "Default values template rendering passed"
else
    print_error "Default values template rendering failed"
    exit 1
fi

# Test 2: All components enabled
print_status "Testing with all components enabled..."
if helm template test-full . \
    --set postgresql.enabled=true \
    --set metaflow-service.enabled=true \
    --set metaflow-ui.enabled=true > /dev/null; then
    print_status "All components template rendering passed"
else
    print_error "All components template rendering failed"
    exit 1
fi

# Test 3: Selective components
print_status "Testing with selective components..."
if helm template test-selective . \
    --set postgresql.enabled=true \
    --set metaflow-service.enabled=true \
    --set metaflow-ui.enabled=false > /dev/null; then
    print_status "Selective components template rendering passed"
else
    print_error "Selective components template rendering failed"
    exit 1
fi

# Bug detection
print_status "Running bug detection tests..."

# Check for the metadatadb password bug
TEMPLATE_OUTPUT=$(helm template test-bug . --set metaflow-ui.enabled=true)
if echo "$TEMPLATE_OUTPUT" | grep -q "\.Values\.metadatadb\.password"; then
    print_error "Found bug in metaflow-ui helpers - using .Values.metadatadb.password instead of .Values.uiBackend.metadatadb.password"
    exit 1
fi

print_status "✓ Bug detection passed"

print_status "All tests completed successfully!"
print_status "Chart validation passed ✓" 