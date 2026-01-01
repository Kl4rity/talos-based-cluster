#!/bin/bash

set -euo pipefail

# Check if IMAGE_ID is set
if [ -z "$IMAGE_ID" ]; then
    echo "Error: IMAGE_ID is not set. Please set it in your .env file or environment."
    echo "Example: Add 'IMAGE_ID=1234' to your .env file"
    exit 1
fi

echo "Using Image ID: $IMAGE_ID"

# Initialize OpenTofu if not already initialized
if [ ! -d .terraform ]; then
    tofu init
fi

# Plan and apply with image ID from environment
tofu plan -var="hcloud_token=$HCLOUD_TOKEN" -var="image_id=$IMAGE_ID"

echo "Plan generated successfully. Review the output above and run:"
echo "tofu apply -var=\"hcloud_token=$HCLOUD_TOKEN\" -var=\"image_id=$IMAGE_ID\""
