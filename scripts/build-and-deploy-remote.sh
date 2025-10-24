#!/bin/bash
set -e

# Color & logging helpers
RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[0;33m"; BLUE="\033[0;34m"; BOLD="\033[1m"; RESET="\033[0m"
info(){ printf "%b%s%b\n" "${BLUE}" "[INFO] $*" "${RESET}"; }
step(){ printf "%b%s%b\n" "${BOLD}${BLUE}" "==> $*" "${RESET}"; }
success(){ printf "%b%s%b\n" "${GREEN}" "[OK] $*" "${RESET}"; }
warn(){ printf "%b%s%b\n" "${YELLOW}" "[WARN] $*" "${RESET}"; }
err(){ printf "%b%s%b\n" "${RED}" "[ERROR] $*" "${RESET}" 1>&2; }

trap 'err "Script failed at line $LINENO"; exit 1' ERR

# Load environment variables
if [ ! -f .env ]; then
        err ".env file not found, please create one based on .env.example"
        exit 1
fi
source .env
step "Loaded .env file"

# Set default values
DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME:-demo-agent}
EIF_FILE_NAME=${EIF_FILE_NAME:-demo-agent.eif}
ENCLAVE_MEMORY=${ENCLAVE_MEMORY:-4096}
ENCLAVE_CPU_COUNT=${ENCLAVE_CPU_COUNT:-2}

# Validate required env vars
step "Validating environment variables"
MISSING=()
[ -z "$EC2_PEM_KEY" ] && MISSING+=(EC2_PEM_KEY)
[ -z "$EC2_USER" ] && MISSING+=(EC2_USER)
[ -z "$EC2_HOST" ] && MISSING+=(EC2_HOST)
if [ ${#MISSING[@]} -gt 0 ]; then
        err "Missing required env vars: ${MISSING[*]}"
        exit 1
fi
if [ ! -f "$EC2_PEM_KEY" ]; then
        err "EC2_PEM_KEY file does not exist: $EC2_PEM_KEY"
        exit 1
fi
success "Environment validation passed"

step "Deployment configuration"
info "Remote host: $EC2_USER@$EC2_HOST"
info "Docker image: $DOCKER_IMAGE_NAME"
info "EIF file: $EIF_FILE_NAME"
info "Enclave CPU: $ENCLAVE_CPU_COUNT | Memory: ${ENCLAVE_MEMORY}MiB"

# Terminate existing enclaves
step "Terminating existing enclaves"
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "HOME=/home/$EC2_USER sudo nitro-cli terminate-enclave --all || true"
success "Terminate command issued"

# Copy src/ to remote
step "Copying source files"
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "rm -rf ~/app || true"
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "mkdir -p ~/app"
if scp -i "$EC2_PEM_KEY" -r src/. "$EC2_USER@$EC2_HOST:~/app/"; then
    success "Sources copied"
else
    err "Failed to copy sources"; exit 1
fi

# Build Docker image
step "Building Docker image"
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "cd ~/app && sudo docker image rm $DOCKER_IMAGE_NAME || true"
# For persistent key
if [ "$PERSISTENT_KEY" = "true" ]; then
    echo "Persistent key is enabled"
    if [ -z "$APP_ID" ]; then
        err "APP_ID is required if you want PERSISTENT_KEY"
        exit 1
    fi
    if [ -z "$AWS_DEFAULT_REGION" ]; then
        err "AWS_DEFAULT_REGION is required if you want PERSISTENT_KEY"
        exit 1
    fi

    ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" \
    "TOKEN=\$(curl -s -X PUT 'http://169.254.169.254/latest/api/token' -H 'X-aws-ec2-metadata-token-ttl-seconds: 21600'); \
    ROLE_NAME=\$(curl -s -H 'X-aws-ec2-metadata-token: '\$TOKEN http://169.254.169.254/latest/meta-data/iam/security-credentials/); \
    CREDS=\$(curl -s -H 'X-aws-ec2-metadata-token: '\$TOKEN http://169.254.169.254/latest/meta-data/iam/security-credentials/\$ROLE_NAME); \
    export AWS_ACCESS_KEY_ID=\$(echo \$CREDS | jq -r '.AccessKeyId'); \
    export AWS_SECRET_ACCESS_KEY=\$(echo \$CREDS | jq -r '.SecretAccessKey'); \
    export AWS_SESSION_TOKEN=\$(echo \$CREDS | jq -r '.Token'); \
    cd ~/app && sudo docker build \
    --build-arg VSOCK=true \
    --build-arg HTTP=true \
    --build-arg DNS=true \
    --build-arg PERSISTENT_KEY=true \
    --build-arg APP_ID=$APP_ID \
    --build-arg KMS_KEY_ID=$KMS_KEY_ID \
    --build-arg BUCKET_NAME=$BUCKET_NAME \
    --build-arg AWS_DEFAULT_REGION=$AWS_DEFAULT_REGION \
    --build-arg AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID \
    --build-arg AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY \
    --build-arg AWS_SESSION_TOKEN=\$AWS_SESSION_TOKEN \
    -t $DOCKER_IMAGE_NAME ."

else
    echo "Persistent key is disabled"
    ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "cd ~/app && sudo docker build --build-arg VSOCK=true --build-arg HTTP=true --build-arg DNS=true -t $DOCKER_IMAGE_NAME ."
fi

success "Docker image built: $DOCKER_IMAGE_NAME"

# Build enclave image
step "Building enclave image (EIF)"
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "cd ~/app && sudo rm $EIF_FILE_NAME || true"
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "cd ~/app && sudo nitro-cli build-enclave --docker-uri $DOCKER_IMAGE_NAME --output-file $EIF_FILE_NAME"
success "EIF built: $EIF_FILE_NAME"

# Install nitro-toolkit on host
step "Installing nitro-toolkit (Python)"
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "python3 -m venv ~/venv"
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "/home/ec2-user/venv/bin/python3 -m pip install --upgrade pip"
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "~/venv/bin/pip install  --index-url https://test.pypi.org/simple/ --extra-index-url https://pypi.org/simple/ nitro-toolkit~=0.0.7-dev6"
success "nitro-toolkit installed"

# Start host proxy
step "Starting host proxy (background)"
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "sudo killall python3 || true"
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "sudo ~/venv/bin/python3 -m nitro_toolkit.host.main --vsock --cid 16 --server-port 80 > ~/host.log 2>&1 &"
success "Host proxy started (log: ~/host.log)"

info "Waiting 2s for host proxy warm-up"
sleep 2
success "Warm-up complete"

# Run enclave in debug mode
step "Running enclave in debug mode"
ssh -i "$EC2_PEM_KEY" "$EC2_USER@$EC2_HOST" "cd ~/app && HOME=/home/$EC2_USER sudo nitro-cli run-enclave --eif-path $EIF_FILE_NAME --cpu-count $ENCLAVE_CPU_COUNT --memory $ENCLAVE_MEMORY --enclave-cid 16"
success "Enclave launch command executed"

# Generate curl command for /agent.json endpoint
step "Generating curl command for enclave API (/agent.json)"
CURL_CMD="curl -s http://$EC2_HOST/agent.json | jq"
info "You can invoke the enclave endpoint with:"
echo "  $CURL_CMD"

success "Deployment workflow completed"


