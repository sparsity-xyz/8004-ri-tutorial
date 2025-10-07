## Pre-requisites

### dependencies
ssh
python (3.11-3.12)
docker (for local testing)
foundry
 - forge install under contracts/ directory

## Environment variables & settings
1. request a TEE-enabled EC2 instance (which will come with a pem key for ssh access) and testnet tokens (will require them to submit their base sepolia ETH address to send the tokens to)
2. base sepolia 8004 registry contract address

## Steps
0. copy over setup-ec2.sh to the target EC2 instance and run it to install dependencies to run nitro enclave.
1. build a sample application by editing src/main.py (if the current one is already enough, skip)
2. (optional) local deployment and testing (use deploy-local.sh, and use docker to run the application)
3. remote deployment (use deploy-remote.sh, and use .env for remote AWS EC2 instance address and ssh key pem file)
4. interact with the instance (curl <EC2 address>/hello endpoint)
5. generate proof using the nitro-eth-prover service (should use script)
6. upload proof to the 8004 registry contract for proof verification & registry
7. interact with the agent

## Appendix


### troubleshooting
asdf

### Other resources
asdf