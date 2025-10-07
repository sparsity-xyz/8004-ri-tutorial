#!/bin/bash

# Setup AWS Nitro Enclave Environment
set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration variables
ENCLAVE_MAX_MEMORY=${ENCLAVE_MAX_MEMORY:-4096}
ENCLAVE_MAX_CPU_COUNT=${ENCLAVE_MAX_CPU_COUNT:-2}

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running on EC2
check_ec2_instance() {
    print_status "Checking if running on EC2 instance..."
    
    if ! curl -s -m 5 http://169.254.169.254/latest/meta-data/instance-id > /dev/null; then
        print_error "This script must be run on an EC2 instance"
        exit 1
    fi
    
    print_status "EC2 instance confirmed"
}

# Detect Amazon Linux version
detect_amazon_linux_version() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        if [[ "$ID" == "amzn" ]]; then
            if [[ "$VERSION_ID" == "2" ]]; then
                echo "2"
            elif [[ "$VERSION_ID" == "2023" ]]; then
                echo "2023"
            else
                echo "unknown"
            fi
        else
            echo "not-amazon"
        fi
    else
        echo "unknown"
    fi
}

# Update system packages
update_system() {
    print_status "Updating all system packages..."
    sudo yum update -y
    print_status "System packages updated successfully"
}

# Install essential packages
install_essential_packages() {
    print_status "Installing essential packages..."
    sudo yum install -y jq python3-pip
    print_status "Essential packages installed successfully"
}

# Install AWS Nitro CLI
install_nitro_cli() {
    print_status "Installing AWS Nitro CLI..."
    
    # Check if already installed
    if which nitro-cli > /dev/null 2>&1; then
        print_status "Nitro CLI already installed"
        nitro-cli --version
        return
    fi
    
    # Detect Amazon Linux version
    AL_VERSION=$(detect_amazon_linux_version)
    print_status "Detected Amazon Linux version: $AL_VERSION"
    
    if [[ "$AL_VERSION" == "2" ]]; then
        print_status "Installing Nitro Enclaves CLI for Amazon Linux 2..."
        sudo amazon-linux-extras install aws-nitro-enclaves-cli -y
        sudo yum install -y aws-nitro-enclaves-cli-devel
    elif [[ "$AL_VERSION" == "2023" ]]; then
        print_status "Installing Nitro Enclaves CLI for Amazon Linux 2023..."
        sudo dnf install -y aws-nitro-enclaves-cli aws-nitro-enclaves-cli-devel
    else
        print_error "Unsupported Amazon Linux version: $AL_VERSION"
        exit 1
    fi
    
    # Verify installation
    if which nitro-cli > /dev/null 2>&1; then
        print_status "Nitro CLI installed successfully"
        nitro-cli --version
    else
        print_error "Failed to install Nitro CLI"
        exit 1
    fi
}

# Install Docker
install_docker() {
    print_status "Installing Docker..."
    
    # Check if already installed
    if which docker > /dev/null 2>&1; then
        print_status "Docker already installed"
        docker --version
    else
        # Install Docker
        sudo yum install -y docker
        print_status "Docker installed successfully"
    fi
    
    # Start and enable docker service
    sudo systemctl start docker
    sudo systemctl enable docker
    
    # Add user to docker and nitro enclave groups
    print_status "Adding ec2-user to docker and ne groups..."
    sudo usermod -aG docker ec2-user
    sudo usermod -aG ne ec2-user

    print_warning "Please log out and log back in for group changes to take effect"
}

# Configure Nitro Enclaves
configure_nitro_enclaves() {
    print_status "Configuring Nitro Enclaves..."
    
    # Create nitro_enclaves directory
    print_status "Creating /etc/nitro_enclaves directory..."
    sudo mkdir -p /etc/nitro_enclaves
    
    # Configure memory and CPU for Nitro Enclaves
    print_status "Configuring allocator.yaml with Memory: ${ENCLAVE_MAX_MEMORY}MiB, CPU: ${ENCLAVE_MAX_CPU_COUNT} cores"
    sudo tee /etc/nitro_enclaves/allocator.yaml > /dev/null <<EOF
---
memory_mib: ${ENCLAVE_MAX_MEMORY}
cpu_count: ${ENCLAVE_MAX_CPU_COUNT}
EOF
    
    # Load nitro_enclaves kernel module
    print_status "Loading nitro_enclaves kernel module..."
    sudo modprobe nitro_enclaves || print_warning "Failed to load nitro_enclaves module (may need reboot)"
    
    # Check and fix nitro_enclaves device file
    print_status "Checking nitro_enclaves device file..."
    if [ -d /dev/nitro_enclaves ]; then
        print_warning "Found directory at /dev/nitro_enclaves, fixing..."
        sudo rmdir /dev/nitro_enclaves || true
        sudo modprobe -r nitro_enclaves || true
        sudo modprobe nitro_enclaves || true
    fi
    
    # Enable and start the nitro-enclaves-allocator service
    print_status "Starting nitro-enclaves-allocator service..."
    sudo systemctl enable nitro-enclaves-allocator.service || print_warning "Could not enable allocator service"
    sudo systemctl start nitro-enclaves-allocator.service || print_warning "Could not start allocator service"
    
    # Enable and start the docker service
    print_status "Starting docker service..."
    sudo systemctl enable docker.service
    sudo systemctl start docker.service
    
    # Add ec2-user to ne group
    print_status "Adding ec2-user to ne group..."
    sudo usermod -aG ne ec2-user || print_warning "Could not add ec2-user to ne group"
    
    # Ensure /home/ec2-user/tmp exists
    print_status "Creating /home/ec2-user/tmp directory..."
    sudo mkdir -p /home/ec2-user/tmp
    sudo chown ec2-user:ec2-user /home/ec2-user/tmp
    
    print_status "Nitro Enclaves configured successfully"
}

# Main setup function
main() {
    print_status "Starting AWS Nitro Enclave environment setup"
    print_status "Configuration: Memory=${ENCLAVE_MAX_MEMORY}MiB, CPU=${ENCLAVE_MAX_CPU_COUNT} cores"
    
    check_ec2_instance
    update_system
    install_essential_packages
    install_nitro_cli
    install_docker
    configure_nitro_enclaves
    
    print_status "============================================"
    print_status "Setup completed successfully!"
    print_status "============================================"
    print_warning "Rebooting instance to apply group membership changes..."
    sleep 1
    sudo reboot
}

# Run main function
main