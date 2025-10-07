from fastapi import Request

from dotenv import load_dotenv
import os

from nitro_toolkit.enclave import BaseNitroEnclaveApp
from nitro_toolkit.util.log import logger

load_dotenv()
OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")
print(OPENAI_API_KEY)

class App(BaseNitroEnclaveApp):

    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)

        self.add_endpoints()

    def add_endpoints(self):
        self.app.add_api_route("/add_two", self.add_two, methods=["POST"])
        self.app.add_api_route("/hello_world", self.hello_world, methods=["POST"])
    
    async def add_two(self, request: Request):
        body = await request.json()
        a = body.get("a")
        b = body.get("b")
        return self.response(str(int(a) + int(b)))

    async def hello_world(self, request: Request):
        return self.response("Hello World")


if __name__ == "__main__":
    app = App()
    # The BaseNitroEnclaveApp will handle running the application
    app.run()