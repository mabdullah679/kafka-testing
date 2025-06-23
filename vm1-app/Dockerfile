FROM eclipse-temurin:17-jdk-alpine
WORKDIR /app

# Set Kafka version environment variables
ENV KAFKA_VERSION=3.5.1
ENV SCALA_VERSION=2.13

# Install required tools and Kafka CLI
RUN apk add --no-cache curl tar bash && \
    curl -fsSL "https://archive.apache.org/dist/kafka/${KAFKA_VERSION}/kafka_${SCALA_VERSION}-${KAFKA_VERSION}.tgz" -o kafka.tgz && \
    tar -xzf kafka.tgz -C /opt && \
    rm kafka.tgz && \
    ln -s "/opt/kafka_${SCALA_VERSION}-${KAFKA_VERSION}" /opt/kafka && \
    ln -s /opt/kafka/bin/kafka-console-producer.sh /usr/bin/kafka-console-producer && \
    ln -s /opt/kafka/bin/kafka-run-class.sh /usr/bin/kafka-run-class && \
    chmod +x /usr/bin/kafka-console-producer /usr/bin/kafka-run-class && \
    [ -x /usr/bin/kafka-console-producer ] || (echo "❌ kafka-console-producer not installed correctly" && exit 1)

# Kafka tools available in PATH
ENV PATH="/opt/kafka/bin:$PATH"

# Copy app artifacts
COPY target/*-jar-with-dependencies.jar app.jar
COPY send-msg.sh .
RUN chmod +x send-msg.sh

# Keep the container alive for exec/debug
CMD ["tail", "-f", "/dev/null"]