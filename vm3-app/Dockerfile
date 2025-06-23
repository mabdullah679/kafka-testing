FROM maven:3.9.6-eclipse-temurin-21 AS builder

WORKDIR /app
COPY . .

RUN mvn clean package -DskipTests

# ------------------------------

FROM eclipse-temurin:21-jdk
WORKDIR /app

COPY --from=builder /app/target/kafka-host-1.0-jar-with-dependencies.jar ./app.jar

# Main volume for audit logs
VOLUME ["/app/logs"]

CMD ["bash"]