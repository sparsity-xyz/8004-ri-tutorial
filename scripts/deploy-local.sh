#!/bin/bash
set -e


DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME:-nitro-test}

# Stop existing container
echo "Stopping existing container..."
docker stop $DOCKER_IMAGE_NAME 2>/dev/null || true
docker rm $DOCKER_IMAGE_NAME 2>/dev/null || true

# Build Docker image
echo "Building Docker image..."
cd src
docker build -t $DOCKER_IMAGE_NAME:latest .
cd ..

# Run container
echo "Running container..."
docker run -d --name $DOCKER_IMAGE_NAME -p 9982:9982 $DOCKER_IMAGE_NAME:latest

echo "Container started!"
echo "Test with: curl http://localhost:9982/hello_world"

# Show logs
docker logs -f $DOCKER_IMAGE_NAME

