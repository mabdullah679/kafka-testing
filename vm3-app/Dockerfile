FROM confluentinc/cp-kafka:7.4.0
WORKDIR /app

# Copy scripts as root and fix permissions
USER root
COPY connect-to-broker.sh broker-handler.sh join-chat.sh ./
RUN chmod +x connect-to-broker.sh broker-handler.sh join-chat.sh

# Optionally: ensure audit dir is writable
RUN mkdir -p /app/audit && chmod -R 777 /app/audit

# Stay as root to avoid permission issues with mounted volumes
# (Safer unless you set up a dedicated user and manage volume ownership)
USER root

# Healthcheck and default command
HEALTHCHECK --interval=10s --timeout=3s --start-period=5s CMD ["bash", "-c", "./broker-handler.sh --healthcheck"]
CMD ["bash", "broker-handler.sh"]