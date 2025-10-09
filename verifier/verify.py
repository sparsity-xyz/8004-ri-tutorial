import argparse
import os
import json
import logging

import requests
from dotenv import load_dotenv

from contract import TEEValidationRegistryContract
from nitro_toolkit.crypto.signer import Signer
from nitro_toolkit.crypto.verifier import Verifier

load_dotenv()


class AgentClient:

    def __init__(self, registry_contract, chain_rpc=""):
        self.signer = Signer()
        self.contract = TEEValidationRegistryContract(registry_contract, chain_rpc)

    def query_agent(self, agent_id):
        agent = self.contract.get_agent(agent_id)
        agent_data = json.dumps(agent, indent=4, sort_keys=True)
        print("Agent loaded on-chain", agent_data)
        return agent

    def chat(self, agent_id, msg):
        agent = self.query_agent(agent_id)
        pubkey = agent["pubkey"]
        url = agent["url"]
        data = {
            "message": msg,
        }
        self.request_agent(url, pubkey, data)

    def privacy_chat(self, agent_id, msg):
        agent = self.query_agent(agent_id)
        pubkey = agent["pubkey"]
        url = agent["url"]
        data = {
            "message": msg,
        }
        nonce = os.urandom(32)
        req = {
            "nonce": nonce.hex(),
            "public_key": self.signer.get_public_key_der().hex(),
            "data": self.signer.encrypt(bytes.fromhex(pubkey), nonce, json.dumps(data).encode()).hex()
        }
        self.request_agent(url, pubkey, req)

    def add_two(self, agent_id, a, b):
        agent = self.query_agent(agent_id)
        pubkey = agent["pubkey"]
        url = agent["url"] + "/add_two"
        data = {
            "a": a,
            "b": b,
        }
        self.request_agent(url, pubkey, data)

    def verify(self, agent_id, resp):
        try:
            agent = self.query_agent(agent_id)
            pubkey = agent["pubkey"]
            self._verify(pubkey, json.loads(resp))
        except Exception as e:
            logging.error(e)
            logging.error("Verify failed, please try again")

    def request_agent(self, url, pubkey, payload):
        resp = requests.post(f"http://{url}", json=payload)
        resp = resp.json()
        print(resp)
        self._verify(pubkey, resp)

    def _verify(self, pubkey, json_data):
        # Verify signature
        pubkey_bytes = bytes.fromhex(pubkey)
        msg_data = json_data["data"]
        sig_bytes = bytes.fromhex(json_data["sig"])

        verified = Verifier.verify_signature(
            pub_key=pubkey_bytes,
            msg=msg_data,
            signature=sig_bytes
        )

        print(f"Signature verified: {verified}")
        if not verified:
            print("Warning: Signature verification failed!")


if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument("--agent-id", type=int, help="Agent ID", default=0)
    arg_parser.add_argument("--response-data", type=str, help="Response from API", default="")
    args = arg_parser.parse_args()

    registry_contract = os.getenv("REGISTRY")
    chain_rpc = os.getenv("RPC_URL")
    agent_client = AgentClient(registry_contract, chain_rpc)
    agent_client.verify(args.agent_id, args.response_data)
