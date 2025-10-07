validate-agent:
	forge script script/ValidateAgent.s.sol:ValidateAgentScript \
		--rpc-url $(RPC_URL) \
		--private-key $(PRIVATE_KEY) \
		--broadcast \
		--sig 'validateAgent(string,uint256,string,string)' \
		$(PROOF_JSON) \
		$(AGENT_ID) \
		$(AGENT_URL) \
		$(TEE_ARCH)