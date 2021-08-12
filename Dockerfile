FROM openjdk:11.0.12-jdk
VOLUME /tmp
ENV APPLICATION_VERSION=0.0.1
ENV APPLICATIONINSIGHTS_VERSION=3.1.1
ENV APPLICATIONINSIGHTS_CONNECTION_STRING=
ARG JAVA_OPTS
ENV JAVA_OPTS=$JAVA_OPTS
COPY target/demo-${APPLICATION_VERSION}-SNAPSHOT.jar applicationinsightsjavaexample.jar
COPY target/dependency/applicationinsights-agent-${APPLICATIONINSIGHTS_VERSION}.jar applicationinsights-agent-${APPLICATIONINSIGHTS_VERSION}.jar
EXPOSE 3000
ENTRYPOINT exec java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -javaagent:applicationinsights-agent-${APPLICATIONINSIGHTS_VERSION}.jar -jar applicationinsightsjavaexample.jar
# For Spring-Boot project, use the entrypoint below to reduce Tomcat startup time.
#ENTRYPOINT exec java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -jar applicationinsightsjavaexample.jar
