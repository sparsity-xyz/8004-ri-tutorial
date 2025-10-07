import argparse
import os
import signal
import multiprocessing
import time
from multiprocessing import Process

from nitro_toolkit.connection.client import VSockClient, TCPClient
from nitro_toolkit.connection.server import Server, ENCLAVE_SERVER_PORT, HOST_SERVER_PORT, HOST_PROXY_SERVER_PORT
from nitro_toolkit.util.log import logger

from nitro_toolkit.host.server import HostConnectionHandler
from nitro_toolkit.host.proxy import HostProxyHandler

DEFAULT_ENCLAVE_ADDR = "127.0.0.1"


class HostApp:
    def __init__(self, vsock: bool, cid: int, server_port: int, server_only: bool):
        self.cid = cid
        self.server_port = server_port
        self.vsock = vsock
        self.server_only = server_only
        self.procs = []

        cli = VSockClient(self.cid, ENCLAVE_SERVER_PORT) if self.vsock else TCPClient(DEFAULT_ENCLAVE_ADDR, ENCLAVE_SERVER_PORT)
        self.server = Server(self.server_port, HostConnectionHandler(cli), 4)
        self.proxy = Server(HOST_PROXY_SERVER_PORT, HostProxyHandler(), 4, self.vsock)

        self.server_process = Process(target=self.server.start)
        self.procs.append(self.server_process)
        if not self.server_only:
            self.proxy_process = Process(target=self.proxy.start)
            self.procs.append(self.proxy_process)

    def start(self):
        for proc in self.procs:
            proc.start()

    def stop(self):
        logger.info("Stopping host app...")
        for proc in self.procs:
            if proc.is_alive():
                proc.terminate()

        for proc in self.procs:
            proc.join()
        
        logger.info("All processes terminated.")


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--vsock", action="store_true", help="Enable vsock mode (optional)")
    parser.add_argument("--cid",type=int,default=None, help="Enclave CID (optional)")
    parser.add_argument("--server-only", action="store_true", help="Only start the server (optional)")
    parser.add_argument("--server-port", type=int, default=HOST_SERVER_PORT, help="Server port (optional)")
    args = parser.parse_args()
    
    host_app = HostApp(args.vsock, args.cid, args.server_port, args.server_only)

    shutdown_flag = multiprocessing.Event()

    def shutdown_handler(signum, frame):
        logger.info(f"Signal {signum} received, shutting down.")
        shutdown_flag.set()

    signal.signal(signal.SIGINT, shutdown_handler)
    signal.signal(signal.SIGTERM, shutdown_handler)

    host_app.start()

    while not shutdown_flag.is_set():
        if not all(p.is_alive() for p in host_app.procs):
            logger.error("A subprocess has died unexpectedly. Shutting down.")
            break
        time.sleep(0.5)

    host_app.stop()


if __name__ == '__main__':
    multiprocessing.set_start_method('spawn')
    main()
