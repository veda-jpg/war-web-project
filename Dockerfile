# Use lightweight Java runtime
FROM eclipse-temurin:17-jre-alpine

# Accept build argument from GitHub Actions
ARG APP_FILE

# Set working directory
WORKDIR /app

# Copy the jar/war file dynamically
COPY ${APP_FILE} app.jar

# Expose app port
EXPOSE 8080

# Run application
ENTRYPOINT ["java","-jar","app.jar"]
