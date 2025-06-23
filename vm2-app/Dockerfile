FROM maven:3.9.6-eclipse-temurin-21 AS builder

WORKDIR /app
COPY . .

RUN mvn clean package -DskipTests

# ------------------------------

FROM eclipse-temurin:21-jdk
WORKDIR /app

COPY --from=builder /app/target/kafka-eclient2-1.0-jar-with-dependencies.jar ./app.jar

# Shared log volume (write-only for message output, not audit)
VOLUME ["/app/logs"]

CMD ["bash"]