FROM debian:bookworm-slim

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
       sysbench \
       default-mysql-client \
    && rm -rf /var/lib/apt/lists/*

COPY run-load.sh /run-load.sh
RUN sed -i 's/\r$//' /run-load.sh && chmod +x /run-load.sh

ENTRYPOINT ["/run-load.sh"]
