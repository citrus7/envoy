#!/bin/bash
# Script to build and upload Envoy Mobile Python wheel to PyPI
# Usage: ./mobile/ci/build_and_publish_python_whl.sh [--dry-run]

set -e

DRY_RUN=false
if [[ "$1" == "--dry-run" ]]; then
    DRY_RUN=true
    echo "Running in DRY-RUN mode"
fi

# Build the Python wheel using Bazel
echo "Building Python wheel..."
cd mobile
bazel build \
    --config=ci \
    --config=mobile-rbe \
    --config=mobile-release \
    -c opt --strip=always \
    //library/python:envoy_mobile_wheel \
    --//library/python:python_platform="manylinux2014_x86_64" \
    --@rules_python//python/config_settings:python_version="3.13.1"


# Extract the wheel file
echo "Locating built wheel..."
WHEEL_PATH=$(bazel info bazel-bin --config=mobile-release)/library/python/*.whl

if [[ ! -f "$WHEEL_PATH" ]]; then
    echo "ERROR: Wheel file not found at $WHEEL_PATH"
    exit 1
fi

echo "Wheel built successfully: $WHEEL_PATH"

# Prepare for upload
WHEEL_FILENAME=$(basename "$WHEEL_PATH")
OUTPUT_DIR="${OUTPUT_DIR:-.}"
cp "$WHEEL_PATH" "$OUTPUT_DIR/$WHEEL_FILENAME"

echo "Wheel copied to: $OUTPUT_DIR/$WHEEL_FILENAME"

# Upload to PyPI
if [[ "$DRY_RUN" == false ]]; then
    if [[ -z "$PYPI_TOKEN" ]]; then
        echo "ERROR: PYPI_TOKEN environment variable not set"
        exit 1
    fi
    
    echo "Uploading wheel to PyPI..."
    python3 -m pip install --upgrade twine
    python3 -m twine upload "$OUTPUT_DIR/$WHEEL_FILENAME" \
        --username __token__ \
        --password "$PYPI_TOKEN" \
        --skip-existing
    
    echo "Wheel successfully uploaded to PyPI!"
else
    echo "DRY-RUN: Would upload $OUTPUT_DIR/$WHEEL_FILENAME to PyPI"
fi

echo "Build and publish process completed successfully"