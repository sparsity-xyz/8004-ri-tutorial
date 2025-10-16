import os
import json

from web3 import Web3
from dotenv import load_dotenv

load_dotenv()


class TEEAgentRegistryContract:
    def __init__(self, contract_address, chain_rpc=""):
        self.w3 = Web3(Web3.HTTPProvider(chain_rpc))

        with open(os.path.join(os.path.dirname(__file__), "./abi.json")) as f:
            contract_abi = json.load(f)

        self.contract = self.w3.eth.contract(address=contract_address, abi=contract_abi)

    def get_agent(self, agent_id: int):
        agent = self.contract.functions.agents(agent_id).call()
        return {
            "owner": agent[0],
            "agent_id": agent[1],
            "tee_arch": agent[2].hex(),
            "code_measurement": agent[3].hex(),
            "tee_pubkey": agent[4].hex(),
            "agent_wallet_address": agent[5],
            "agent_url": agent[6],
        }

    def get_agent_count(self):
        return self.contract.functions.nextAgentId().call()

if __name__ == '__main__':
    c = TEEAgentRegistryContract(
        contract_address=os.getenv("REGISTRY"),
        chain_rpc=os.getenv("RPC_URL")
    )

    print(c.get_agent_count())
