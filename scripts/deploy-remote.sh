#!/bin/bash
set -e

# Load environment variables
if [ ! -f .env ]; then
    echo "Error: .env file not found"
    exit 1
fi
source .env

# Set default values
DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME:-test-app}
EIF_FILE_NAME=${EIF_FILE_NAME:-test-app.eif}
ENCLAVE_MEMORY=${ENCLAVE_MEMORY:-4096}
ENCLAVE_CPU_COUNT=${ENCLAVE_CPU_COUNT:-2}

# Terminate existing enclaves
echo "Terminating existing enclaves..."
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "HOME=/home/$EC2_USER nitro-cli terminate-enclave --all || true"

# Copy src/ to remote
echo "Copying source files..."
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "mkdir -p ~/app"
scp -i "$EC2_PEM_KEY" -r src/* "$EC2_USER@$EC2_HOST:~/app/"

# Build Docker image
echo "Building Docker image..."
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "cd ~/app && sudo docker build --no-cache --build-arg VSOCK=true --build-arg HTTP=true --build-arg DNS=true -t $DOCKER_IMAGE_NAME ."

# Build enclave image
echo "Building enclave image..."
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "cd ~/app && sudo nitro-cli build-enclave --docker-uri $DOCKER_IMAGE_NAME --output-file $EIF_FILE_NAME"

# Install nitro-toolkit on host if not already installed
echo "Installing nitro-toolkit on host..."
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "python3 -m venv ~/venv"
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "/home/ec2-user/venv/bin/python3 -m pip install --upgrade pip"
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "~/venv/bin/pip install  --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple/ nitro-toolkit~=0.0.7-dev6"

# Start host proxy
echo "Starting host proxy in background..."
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "pkill python || true"
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "cd ~/app/host && sudo ~/venv/bin/python3 host.py --vsock --cid 16 --server-port 80 > ~/host.log 2>&1 &"

sleep 2

# Run enclave in debug mode
echo "Running enclave in debug mode..."
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "cd ~/app && HOME=/home/$EC2_USER sudo nitro-cli run-enclave --eif-path $EIF_FILE_NAME --cpu-count $ENCLAVE_CPU_COUNT --memory $ENCLAVE_MEMORY --debug-mode --enclave-cid 16"
