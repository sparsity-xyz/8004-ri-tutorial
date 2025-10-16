import argparse
import os
import json
import logging

import requests
from dotenv import load_dotenv

from contract import TEEAgentRegistryContract
from nitro_toolkit.crypto.signer import Signer
from nitro_toolkit.crypto.eth_key import EthereumKey

load_dotenv()


class AgentClient:

    def __init__(self, registry_contract, chain_rpc=""):
        self.signer = Signer()
        self.contract = TEEAgentRegistryContract(registry_contract, chain_rpc)

    def query_agent(self, agent_id):
        agent = self.contract.get_agent(agent_id)
        agent_data = json.dumps(agent, indent=4, sort_keys=True)
        print("Agent loaded on-chain", agent_data)
        return agent

    def verify(self, agent_id, path, data):
        try:
            agent = self.query_agent(agent_id)
            wallet_address = agent["agent_wallet_address"]
            base_url = agent["agent_url"]
            url = f"http://{base_url}{path}"
            if data != "":
                resp = requests.post(url, json=json.loads(data)).json()
            else:
                resp = requests.get(url).json()
            print("Response from agent", resp)
            self._verify(wallet_address, resp)
        except Exception as e:
            logging.error(e)
            logging.error("Verify failed, please try again")

    @staticmethod
    def _verify(wallet_address, json_data):
        # Verify signature
        msg_data = json_data["data"]
        sig_bytes = bytes.fromhex(json_data["sig"])

        verified = EthereumKey.verify(sig_bytes, msg_data, wallet_address)
        print(f"Signature verified: {verified}")
        if not verified:
            print("Warning: Signature verification failed!")


if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument("--agent-id", type=int, help="Agent ID", default=0)
    arg_parser.add_argument("--url-path", type=str, help="URL path", default="")
    arg_parser.add_argument("--data", type=str, help="Request data", default="")
    args = arg_parser.parse_args()

    registry_contract = os.getenv("REGISTRY")
    chain_rpc = os.getenv("RPC_URL")
    agent_client = AgentClient(registry_contract, chain_rpc)
    agent_client.verify(args.agent_id, args.url_path, args.data)
