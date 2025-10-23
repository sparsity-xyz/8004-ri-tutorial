
# signature verification

## install
```
pip install -r requirements.txt
```

## verify
```
# GET
python3 verify.py --agent-id=17 --url-path=/hello_world

# POST
python3 verify.py --agent-id=17 --url-path=/add_two --data='{"a": 1, "b": 2}'
```

the output would be like:
```
----------------------------------------------------------------------
➤ TEE Agent Verification
Starting verification flow
----------------------------------------------------------------------
  registry: 0xe718aec274E36781F18F42C363A3B516a4427637
  rpc_url: https://sepolia.base.org
  agent_id: 18
  url_path: /hello_world
  data: <empty>

----------------------------------------------------------------------
➤ Step 1/3: Query agent on-chain
Fetching agent data from registry
----------------------------------------------------------------------
  agent_id: 18
  owner: 0x855D4db013dE51a0cf7528d0C294a79b162eF1aD
  agent_wallet_address: 0xdB6489882070D057d821CF0C6808bFcE1b06dA08
  agent_url: 3.101.88.22

Full agent record:
{
  "agent_id": 18,
  "agent_url": "3.101.88.22",
  "agent_wallet_address": "0xdB6489882070D057d821CF0C6808bFcE1b06dA08",
  "code_measurement": "b2dce0c0b533dfdcb2fe11ec73b0a4b67810bbbff2c3871e743cd0b7382436d5",
  "owner": "0x855D4db013dE51a0cf7528d0C294a79b162eF1aD",
  "tee_arch": "6e6974726f000000000000000000000000000000000000000000000000000000",
  "tee_pubkey": "3076301006072a8648ce3d020106052b81040022036200044bbefb39ef3a467d753d8d02b95a51dee2eefd977852a7adbbb7c47a8bab8efc9b9002028b8cd745bce9a8b9600e7fd6e71a0c3e569953b8027d77d250b1f461506bf5b88942664b810cd361210e5e2d368d79a670697df895973417651abe1f"
}

✓ Agent loaded from chain

----------------------------------------------------------------------
➤ Step 2/3: Query agent endpoint
Requesting data from the agent service
----------------------------------------------------------------------
  method: GET
  url: http://3.101.88.22/hello_world
  http_status: 200

agent response (json):
{
  "sig": "efb8d1be50cb5b84f4d405089c80c4cc4f47b8002cb53f2a2feee5cea1b7b53b35ef5ff95a61a443bcd508c7987b91c61c36603a7f4decb61bbe9e1a42cace6a01",
  "data": "Hello World"
}

✓ Agent responded with JSON

----------------------------------------------------------------------
➤ Step 3/3: Verify signature
Checking agent wallet signature over response data
----------------------------------------------------------------------
✓ Signature verified (0xdB6489882070D057d821CF0C6808bFcE1b06dA08)
```
