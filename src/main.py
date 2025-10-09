from fastapi import Request
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
import os, time
import httpx

from nitro_toolkit.enclave import BaseNitroEnclaveApp
from nitro_toolkit.util.log import logger

load_dotenv()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

class App(BaseNitroEnclaveApp):

    def build_agent_card(self):
        return {
            "name": os.getenv("AGENT_NAME", "SampleEnclaveAgent"),
            "description": os.getenv("AGENT_DESCRIPTION", "Example Nitro Enclave based trusted agent"),
            "version": os.getenv("AGENT_VERSION", "0.1.0"),
            "schema_version": 1,
            "tee_arch": os.getenv("TEE_ARCH", "nitro"),
            "zk_type": os.getenv("ZK_TYPE", "Risc0"),
            "registry": os.getenv("REGISTRY", ""),
            "network": os.getenv("NETWORK", ""),
            "endpoints": ["/add_two", "/hello_world", "/agent_card", "/.well-known/agent.json"],
            "attestation_endpoint": os.getenv("ATTESTATION_PATH", "/attestation"),
            "timestamp": int(time.time()),
        }

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.add_endpoints()


    def add_endpoints(self):
        # Agent card endpoints (human + well-known)
        self.app.add_api_route("/agent_card", self.agent_card, methods=["GET"])
        self.app.add_api_route("/.well-known/agent.json", self.agent_well_known, methods=["GET"])

        # toy examples
        self.app.add_api_route("/hello_world", self.hello_world, methods=["GET"])
        self.app.add_api_route("/add_two", self.add_two, methods=["POST"])

        # agent example
        self.app.add_api_route("/chat", self.chat, methods=["POST"])

    
    async def agent_card(self, request: Request):
        # Return JSON metadata card
        return JSONResponse(self.build_agent_card())

    async def agent_well_known(self, request: Request):
        # Add short cache headers for discovery crawlers
        card = self.build_agent_card()
        resp = JSONResponse(card)
        resp.headers["Cache-Control"] = "public, max-age=300"
        return resp


    async def hello_world(self, request: Request):
        return self.response("Hello World")

    async def add_two(self, request: Request):
        body = await request.json()
        a = body.get("a")
        b = body.get("b")
        return self.response(str(int(a) + int(b)))

    
    # please modify this function to build your own agent leveraging LLMs 
    async def chat(self, request: Request):
        body = await request.json()
        prompt = body.get("prompt")
        
        async with httpx.AsyncClient() as client:
            response = await client.post(
                "https://api.openai.com/v1/chat/completions",
                headers={
                    "Authorization": f"Bearer {OPENAI_API_KEY}",
                    "Content-Type": "application/json"
                },
                json={
                    "model": "gpt-4o-mini",
                    "messages": [{"role": "user", "content": prompt}]
                }
            )
        logger.info(response.json())
            
        return self.response(response.json()["choices"][0]["message"]["content"])


if __name__ == "__main__":
    app = App()
    # The BaseNitroEnclaveApp will handle running the application
    app.run()
