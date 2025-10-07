FROM python:3.12-slim

RUN apt-get update && apt-get install -y

# Build arguments for Nitro enclave configuration
ARG VSOCK=false
ARG DNS=true
ARG HTTP=false
ENV VSOCK=${VSOCK}
ENV DNS=${DNS}
ENV HTTP=${HTTP}

WORKDIR /app
COPY . .

RUN pip install -r requirements.txt

CMD ["/usr/local/bin/python3", "/app/agent.py"] 