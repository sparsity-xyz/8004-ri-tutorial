from fastapi import Request
from dotenv import load_dotenv
import os
import httpx

from nitro_toolkit.enclave import BaseNitroEnclaveApp
from nitro_toolkit.util.log import logger

load_dotenv()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

class App(BaseNitroEnclaveApp):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.add_endpoints()

    def add_endpoints(self):
        self.app.add_api_route("/add_two", self.add_two, methods=["POST"])
        self.app.add_api_route("/hello_world", self.hello_world, methods=["GET"])
        self.app.add_api_route("/chat", self.chat, methods=["POST"])
    
    async def add_two(self, request: Request):
        body = await request.json()
        a = body.get("a")
        b = body.get("b")
        return self.response(str(int(a) + int(b)))

    async def hello_world(self, request: Request):
        return self.response("Hello World")

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