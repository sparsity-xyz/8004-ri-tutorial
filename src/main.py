from fastapi import Request
from fastapi.responses import JSONResponse
from dotenv import load_dotenv
import os, time, json
import httpx
from pathlib import Path

from nitro_toolkit.enclave import BaseNitroEnclaveApp
from nitro_toolkit.util.log import logger

load_dotenv()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

class App(BaseNitroEnclaveApp):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        # Optional external agent card file (defaults to /app/agent.json inside container)
        self.agent_card_path: Path = Path(os.getenv("AGENT_CARD_PATH", "/app/agent.json"))
        self._agent_card_cache = None
        self._agent_card_mtime = None
        self.add_endpoints()



    def add_endpoints(self):
        # Agent card endpoints (human + well-known)
        self.app.add_api_route("/agent.json", self.agent_card, methods=["GET"])
        self.app.add_api_route("/.well-known/agent.json", self.agent_well_known, methods=["GET"])

        # toy examples
        self.app.add_api_route("/hello_world", self.hello_world, methods=["GET"])
        self.app.add_api_route("/add_two", self.add_two, methods=["POST"])

        # agent example
        self.app.add_api_route("/chat", self.chat, methods=["POST"])

    
    async def agent_card(self, request: Request):
        # Return JSON metadata card
        return JSONResponse(self.load_agent_card())

    async def agent_well_known(self, request: Request):
        # Add short cache headers for discovery crawlers
        card = self.load_agent_card()
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

    def load_agent_card(self, force: bool = False):
        """Load agent card from JSON file if present; otherwise return empty.
        Caches content and auto-reloads on file mtime change.
        """
        try:
            if self.agent_card_path.exists():
                mtime = self.agent_card_path.stat().st_mtime
                if force or self._agent_card_cache is None or mtime != self._agent_card_mtime:
                    with self.agent_card_path.open("r", encoding="utf-8") as f:
                        data = json.load(f)
                    if isinstance(data, dict):
                        data.setdefault("timestamp", int(time.time()))
                        self._agent_card_cache = data
                        self._agent_card_mtime = mtime
                    else:
                        logger.warn("agent.json is not a JSON object; returning empty card")
                        self._agent_card_cache = {}
                return self._agent_card_cache
            else:
                # No agent.json present; return empty
                return {}
        except Exception as e:
            logger.error(f"Failed to load agent card from {self.agent_card_path}: {e}")
            return {}
    
    # please modify this function to build your own agent leveraging LLMs 
    async def chat(self, request: Request):
        body = await request.json()
        prompt = body.get("prompt")
        
        async with httpx.AsyncClient(timeout=60.0) as client:
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
        
        result = response.json()
        logger.info(result)
        
        if "error" in result:
            return self.response({"error": result["error"]})
        return self.response(result["choices"][0]["message"]["content"])


if __name__ == "__main__":
    app = App()
    # The BaseNitroEnclaveApp will handle running the application
    app.run()
