#!/bin/bash
set -euo pipefail

# Colored logging (disable with NO_COLOR=1)
if [ -t 1 ] && [ "${NO_COLOR:-0}" != "1" ]; then
	RED="\033[0;31m"; GREEN="\033[0;32m"; YELLOW="\033[0;33m"; BLUE="\033[0;34m"; BOLD="\033[1m"; RESET="\033[0m"
else
	RED=""; GREEN=""; YELLOW=""; BLUE=""; BOLD=""; RESET=""
fi
info(){ printf "%b%s%b\n" "${BLUE}" "[INFO] $*" "${RESET}"; }
step(){ printf "%b%s%b\n" "${BOLD}${BLUE}" "==> $*" "${RESET}"; }
success(){ printf "%b%s%b\n" "${GREEN}" "[OK] $*" "${RESET}"; }
warn(){ printf "%b%s%b\n" "${YELLOW}" "[WARN] $*" "${RESET}"; }
err(){ printf "%b%s%b\n" "${RED}" "[ERROR] $*" "${RESET}" 1>&2; }
highlight(){ printf "%b%s%b\n" "${BOLD}${YELLOW}" "[NEXT] $*" "${RESET}"; }

trap 'err "Script failed at line $LINENO"' ERR

START_TIME=$(date +%s)

DOCKER_IMAGE_NAME=${DOCKER_IMAGE_NAME:-nitro-test}
CONTAINER_PORT=${CONTAINER_PORT:-9982}
HOST_PORT=${HOST_PORT:-9982}

step "Validation"
if ! command -v docker >/dev/null 2>&1; then err "docker command not found"; fi
success "Docker available"

if [ ! -d src ]; then err "src directory not found (expected application code in ./src)"; fi
success "Source directory present"

step "Stop existing container (if running)"
if docker ps -a --format '{{.Names}}' | grep -q "^${DOCKER_IMAGE_NAME}$"; then
	info "Stopping container $DOCKER_IMAGE_NAME"
	docker stop "$DOCKER_IMAGE_NAME" >/dev/null 2>&1 || true
	docker rm "$DOCKER_IMAGE_NAME" >/dev/null 2>&1 || true
	success "Old container removed"
else
	info "No existing container named $DOCKER_IMAGE_NAME"
fi

step "Building Docker image"
pushd src >/dev/null
docker build -t "$DOCKER_IMAGE_NAME:latest" .
success "Image built: $DOCKER_IMAGE_NAME:latest"
popd >/dev/null

step "Running container"
docker run -d --name "$DOCKER_IMAGE_NAME" -p ${HOST_PORT}:${CONTAINER_PORT} "$DOCKER_IMAGE_NAME:latest" >/dev/null
success "Container started (name: $DOCKER_IMAGE_NAME)"
info "Mapped host port ${HOST_PORT} -> container port ${CONTAINER_PORT}"

step "Health check"
SLEEP_SECS=${HEALTH_WAIT:-2}
info "Waiting ${SLEEP_SECS}s for service startup"
sleep "$SLEEP_SECS"
if curl -fsS "http://localhost:${HOST_PORT}/hello_world" >/dev/null 2>&1; then
	success "Endpoint /hello_world responding"
else
	warn "/hello_world not responding yet; tailing logs below"
fi

END_TIME=$(date +%s)
TOTAL=$((END_TIME-START_TIME))

step "Summary"
info "Image: $DOCKER_IMAGE_NAME:latest"
info "Container: $DOCKER_IMAGE_NAME"
info "Port: http://localhost:${HOST_PORT}"
highlight "Test: curl http://localhost:${HOST_PORT}/hello_world"
info "Elapsed: ${TOTAL}s"

step "Tailing container logs (Ctrl+C to exit)"
docker logs -f "$DOCKER_IMAGE_NAME"

