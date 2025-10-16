# Demo: TEE-Verified ChatGPT Agent

## 1. Setup API Key
```bash
# Create .env with OpenAI key
cp src/.env.example src/.env
echo 'OPENAI_API_KEY=sk-your-key-here' >> src/.env
```

## 2. Deploy to EC2
```bash
./scripts/build-and-deploy-remote.sh
```

## 3. Test Chat Endpoint
```bash
# Query the agent
curl -X POST http://$EC2_HOST/chat \
  -H "Content-Type: application/json" \
  -d '{"prompt": "What is 2+2?"}'

# Response includes signature
{
  "sig": "0x...",
  "data": "2 + 2 equals 4.",
}
```

## 4. Verify Agent in Registry
```bash
# Get agent details
./scripts/explore-agents.sh --agent-id <your_agent_id>

# Shows code measurement matches deployed enclave
```

**Result**: Cryptographically verified ChatGPT chatbot running in AWS Nitro TEE

