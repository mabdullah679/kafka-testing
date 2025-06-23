FROM maven:3.9.6-eclipse-temurin-21 AS builder

WORKDIR /app
COPY . .

RUN mvn clean package -DskipTests

# ------------------------------

FROM eclipse-temurin:21-jdk
WORKDIR /app

# Copy fat JAR from builder stage
COPY --from=builder /app/target/kafka-eclient1-1.0-jar-with-dependencies.jar ./app.jar

# Optional volume for shared logs (even if vm1 can't read audit)
VOLUME ["/app/logs"]

CMD ["java", "-jar", "app.jar"]