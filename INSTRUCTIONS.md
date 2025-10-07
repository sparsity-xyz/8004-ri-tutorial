## Pre-requisites
dependencies
ssh
python (3.11-3.12)
docker (for local testing)
foundry

## Environment variables & settings
1. request a TEE-enabled EC2 instance (which will come with a pem key for ssh access) and testnet tokens (will require them to submit their base sepolia ETH address to send the tokens to)
2. base sepolia 8004 registry contract address

## Steps
1. build a sample application by editing main.py (if the current one is already enough, skip)
2. (optional) local deployment (use deploy-local.sh)
3. remote deployment (use deploy-remote.sh, and use .env for remote AWS EC2 instance address and ssh key pem file)
4. interact with the instance (curl <EC2 address>/hello endpoint)
5. generate proof
6. upload proof to the 8004 registry contract for proof verification & registry
7. interact with the agent

## Appendix


### troubleshooting
asdf

### Other resources
asdf