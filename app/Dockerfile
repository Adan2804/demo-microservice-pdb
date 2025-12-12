# Build stage
FROM gradle:8.8-jdk21-alpine AS build
WORKDIR /app
COPY . .
# Ensure a fresh build so new controllers are included
RUN gradle clean :infrastructure:bootJar --no-daemon -x test

# Run stage
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=build /app/infrastructure/build/libs/*.jar app.jar
ARG APP_VERSION=v1
ENV APP_VERSION=${APP_VERSION}
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "app.jar"]
