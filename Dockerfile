# Use Tomcat with Java 17
FROM tomcat:9.0-jdk17-temurin

# Accept build argument from GitHub Actions
ARG APP_FILE

# Remove default Tomcat apps (optional but recommended)
RUN rm -rf /usr/local/tomcat/webapps/*

# Copy WAR file to Tomcat webapps directory
COPY ${APP_FILE} /usr/local/tomcat/webapps/ROOT.war

# Expose Tomcat port
EXPOSE 8080

# Start Tomcat
CMD ["catalina.sh", "run"]
