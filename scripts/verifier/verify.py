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


class Color:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    RED = "\033[31m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    BLUE = "\033[34m"
    MAGENTA = "\033[35m"
    CYAN = "\033[36m"


def banner(title: str, subtitle: str = ""):
    line = f"{Color.DIM}{'-' * 70}{Color.RESET}"
    print(line)
    print(f"{Color.BOLD}{Color.CYAN}➤ {title}{Color.RESET}")
    if subtitle:
        print(f"{Color.DIM}{subtitle}{Color.RESET}")
    print(line)


def kv(key: str, value: str, color: str = Color.BLUE):
    print(f"  {Color.DIM}{key}:{Color.RESET} {color}{value}{Color.RESET}")


class AgentClient:

    def __init__(self, registry_contract, chain_rpc=""):
        self.signer = Signer()
        self.contract = TEEAgentRegistryContract(registry_contract, chain_rpc)

    def query_agent(self, agent_id):
        banner("Step 1/3: Query agent on-chain", "Fetching agent data from registry")
        agent = self.contract.get_agent(agent_id)
        agent_data = json.dumps(agent, indent=2, sort_keys=True)
        kv("agent_id", str(agent.get("agent_id", agent_id)))
        kv("owner", agent.get("owner", ""))
        kv("agent_wallet_address", agent.get("agent_wallet_address", ""))
        kv("agent_url", agent.get("agent_url", ""))
        print(f"\n{Color.DIM}Full agent record:{Color.RESET}\n{agent_data}\n")
        print(f"{Color.GREEN}✓ Agent loaded from chain{Color.RESET}\n")
        return agent

    def verify(self, agent_id, path, data):
        try:
            agent = self.query_agent(agent_id)
            wallet_address = agent["agent_wallet_address"]
            base_url = agent["agent_url"]
            # Build request
            method = "POST" if data else "GET"
            url = f"http://{base_url}{path}"

            banner("Step 2/3: Query agent endpoint", "Requesting data from the agent service")
            kv("method", method)
            kv("url", url)
            if data:
                print(f"{Color.DIM}request body:{Color.RESET}\n{json.dumps(json.loads(data), indent=2)}")

            # Send
            if data:
                http_resp = requests.post(url, json=json.loads(data))
            else:
                http_resp = requests.get(url)

            kv("http_status", str(http_resp.status_code),
               Color.GREEN if 200 <= http_resp.status_code < 300 else Color.YELLOW)

            try:
                resp_json = http_resp.json()
            except ValueError:
                resp_text = http_resp.text[:2000]
                print(f"{Color.RED}✗ Response is not valid JSON:{Color.RESET}\n{resp_text}")
                raise

            print(f"\n{Color.DIM}agent response (json):{Color.RESET}\n{json.dumps(resp_json, indent=2)}\n")
            print(f"{Color.GREEN}✓ Agent responded with JSON{Color.RESET}\n")

            banner("Step 3/3: Verify signature", "Checking agent wallet signature over response data")
            self._verify(wallet_address, resp_json)
        except Exception as e:
            print(f"{Color.RED}✗ Verification flow failed:{Color.RESET} {e}")
            logging.error(e)
            logging.error("Verify failed, please try again")

    @staticmethod
    def _verify(wallet_address, json_data):
        # Verify signature
        msg_data = json_data["data"]
        sig_bytes = bytes.fromhex(json_data["sig"])

        verified = EthereumKey.verify(sig_bytes, msg_data, wallet_address)
        if verified:
            print(f"{Color.GREEN}✓ Signature verified{Color.RESET} ({wallet_address})")
        else:
            print(f"{Color.RED}✗ Signature verification failed{Color.RESET} ({wallet_address})")


if __name__ == '__main__':
    arg_parser = argparse.ArgumentParser()
    arg_parser.add_argument("--agent-id", type=int, help="Agent ID", default=0)
    arg_parser.add_argument("--url-path", type=str, help="URL path", default="")
    arg_parser.add_argument("--data", type=str, help="Request data", default="")
    args = arg_parser.parse_args()

    registry_contract = os.getenv("REGISTRY")
    chain_rpc = os.getenv("RPC_URL")
    banner("TEE Agent Verification", "Starting verification flow")
    kv("registry", registry_contract or "<unset>")
    kv("rpc_url", chain_rpc or "<unset>")
    # show all inputs here as well
    kv("agent_id", str(args.agent_id))
    kv("url_path", args.url_path or "<empty>")
    kv("data", args.data or "<empty>")
    print()
    agent_client = AgentClient(registry_contract, chain_rpc)
    agent_client.verify(args.agent_id, args.url_path, args.data)
