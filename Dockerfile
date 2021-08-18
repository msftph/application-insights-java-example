FROM maven:3.8.2-openjdk-11 as build
COPY src /app/src
COPY pom.xml /app
WORKDIR /app
RUN mvn install dependency:copy-dependencies

FROM openjdk:11.0.12-jre
VOLUME /tmp
ENV APPLICATION_VERSION=0.0.1
ENV APPLICATIONINSIGHTS_VERSION=3.1.1
ARG APPLICATIONINSIGHTS_CONNECTION_STRING
ARG JAVA_OPTS
ENV JAVA_OPTS=$JAVA_OPTS
COPY --from=build /app/target/demo-${APPLICATION_VERSION}-SNAPSHOT.jar applicationinsightsjavaexample.jar
COPY --from=build /app/target/dependency/applicationinsights-agent-${APPLICATIONINSIGHTS_VERSION}.jar applicationinsights-agent-${APPLICATIONINSIGHTS_VERSION}.jar
EXPOSE 8080
ENTRYPOINT exec java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -javaagent:applicationinsights-agent-${APPLICATIONINSIGHTS_VERSION}.jar -jar applicationinsightsjavaexample.jar
# For Spring-Boot project, use the entrypoint below to reduce Tomcat startup time.
#ENTRYPOINT exec java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar applicationinsightsjavaexample.jar
