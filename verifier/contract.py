import os
import json

from web3 import Web3
from dotenv import load_dotenv

load_dotenv()


class TEEValidationRegistryContract:
    def __init__(self, contract_address, chain_rpc=""):
        self.w3 = Web3(Web3.HTTPProvider(chain_rpc))

        with open(os.path.join(os.path.dirname(__file__), "./abi.json")) as f:
            contract_abi = json.load(f)

        self.contract = self.w3.eth.contract(address=contract_address, abi=contract_abi)

    def zkVerifier(self) -> str:
        return self.contract.functions.zkVerifier().call()

    def get_agent(self, agent_id: int):
        agent = self.contract.functions.agents(agent_id).call()
        return {
            "agent_id": agent[0],
            "tee_arch": agent[1].hex(),
            "code_measurement": agent[2].hex(),
            "pubkey": agent[3].hex(),
            "url": agent[4],
        }

    def register_agent(self, agent_id: int, code_measurement, pubkey, url, tee_arch, verifier, zk_proof):
        return self.contract.functions.validateAgent(
            agent_id,
            code_measurement,
            pubkey,
            url,
            tee_arch,
            verifier,
            zk_proof
        )

    def get_agent_count(self):
        return self.contract.functions.agentCount().call()

if __name__ == '__main__':
    c = TEEValidationRegistryContract(
        contract_address=os.getenv("REGISTRY"),
        chain_rpc=os.getenv("RPC_URL")
    )

    print(c.get_agent_count())
