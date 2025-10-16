
# signature verification

## install
```
pip install -r requirements.txt
```

## verify
- get the response from the agent like this
```
{"sig":"306402302c49d28b19149bcdd10e6f2075cf19092cbe467bcc2f04a7050a01b9782101f8ee0b165fbceabfdf6e8a6286f043fbf002307153953741d7af583d0a6b433a7432e4a1096d488a9f573862b38d74300e5cbf48bf531755d6368b7e9816f10fcb2238","data":"Hello World"}
```

- Run verification
```
python3 verify.py --agent-id=17 --response-data='{"sig":"306402302c49d28b19149bcdd10e6f2075cf19092cbe467bcc2f04a7050a01b9782101f8ee0b165fbceabfdf6e8a6286f043fbf002307153953741d7af583d0a6b433a7432e4a1096d488a9f573862b38d74300e5cbf48bf531755d6368b7e9816f10fcb2238","data":"Hello World"}'
```

the output would be like
```
Agent loaded on-chain {
    "agent_id": 17,
    "code_measurement": "725da0e38d91dc65362f4203cecbfa201af8ee5e88eac37d75c57de24e44ba7b",
    "pubkey": "3076301006072a8648ce3d020106052b810400220362000480e663d60e055fd5a717cd92dfaa053d377e335332331c79e82fafccf9f4f82d6860aff5629001b0b4a7acb4cd5d637689d77175b0f5f9c4a527153b245ac18c6e32ad33137b24cdfb476a8ee814fb6f68410c639d57ed34823bd5da0fe5df2f",
    "tee_arch": "6e6974726f000000000000000000000000000000000000000000000000000000",
    "url": "13.57.15.37"
}
Signature verified: True
```
