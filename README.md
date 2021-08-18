# Application Insights Java Example Using In-Process Agent

This example project is based off the documentation here: https://docs.microsoft.com/en-us/azure/azure-monitor/app/java-in-process-agent

## Tools

For this example I will be using Visual Studio Code Dev Containers. This extension will allow a consistent environment when developing the application. If you don't want to use devcontainers make sure you have the following dependencies installed on your machine: 

* java 11
* maven

The devcontainer configuration can be found in the `.devcontainer` folder.

Dev Containers require the remote containers extension https://marketplace.visualstudio.com/items?itemName=ms-vscode-remote.remote-containers

## Overview

Most of the steps below are already completed if using using the devcontainer extension in vscode. They are outlined here to show how to go from nothing to a fully instrumnted application.

## Step 1 : Create a Spring Boot Application using Spring Initializer

The following quickstart shows you have to create a spring boot application with spring initializer. https://spring.io/quickstart

Here is the link to the project I used. 

https://start.spring.io/#!type=maven-project&language=java&platformVersion=2.5.3&packaging=jar&jvmVersion=11&groupId=com.example&artifactId=demo&name=demo&description=Demo%20project%20for%20Spring%20Boot&packageName=com.example.demo&dependencies=web

## Step 2 : Add the applicationinsights-agent sdk

Edit pom.xml and add the following section

```xml
<!-- https://mvnrepository.com/artifact/com.microsoft.azure/applicationinsights-agent -->
<dependency>
    <groupId>com.microsoft.azure</groupId>
    <artifactId>applicationinsights-agent</artifactId>
    <version>3.1.1</version>
</dependency>
```

## Step 3 : Create a Dockerfile to run the application

The Docker extension should be installed in vscode devconatiner. If you are not using devcontainers you will need create a dockerfile by hand. https://marketplace.visualstudio.com/items?itemName=ms-azuretools.vscode-docker

See the link for generating docker files https://code.visualstudio.com/docs/containers/overview#_generating-docker-files

## Step 4 : Build the application and copy local dependencies

Maven will copy dependencies to the .m2 directory under `/home/vscode/.m2/` by default. For a docker file, we need the dependency to be in the root. Specify the `dependency:copy-dependencies` argument to the `mvn install` command to accomplish this.

```bash
mvn install dependency:copy-dependencies
```

This puts the application insights jar file under target/dependency/applicationinsights-agent-3.1.1.jar (version number may vary).

## Step 5 : Patch in the application insights jar to the jvm entrypoint in the docker file

Now that the jar file is copied locally, we need to edit the dockerfile to move the dependency to the application root. The following copy command will do this. I've added an ARG argument for the version number to ensure edits to the docker file are easier moving forward. 

Add ENV

```Dockerfile
ENV APPLICATIONINSIGHTS_VERSION=3.1.1
```

Add COPY

```Dockerfile
COPY target/dependency/applicationinsights-agent-${APPLICATIONINSIGHTS_VERSION}.jar applicationinsights-agent-${APPLICATIONINSIGHTS_VERSION}.jar
```

Edit Entrypoint as defined here: https://docs.microsoft.com/en-us/azure/azure-monitor/app/java-standalone-arguments#spring-boot-via-docker-entry-point

```Dockerfile
ENTRYPOINT exec java $JAVA_OPTS -Djava.security.egd=file:/dev/./urandom -javaagent:applicationinsights-agent-${APPLICATIONINSIGHTS_VERSION}.jar -jar applicationinsightsjavaexample.jar
```

When the container starts up, the application insights in process agent will look for environment variables or configuration files in order to connect itself to application insights. We need to supply this configuration as environment variables or as configuration files. In order to keep configuraiton information out of the container it is recommended to use environemnt variables that are injected at runtime. 

Add ARG for configuring application insights in order to avoid persisting the connection string in the final image

```Dockerfile
ARG APPLICATIONINSIGHTS_CONNECTION_STRING
```

Build the container from the same folder as the Dockerfile

```bash
docker build . -t app-insights-demo
```

**Optional Step 5a**

Using multi stage containers, we can automate this step for the Dockerfile build. Without the multi stage containers, the application will need to be built first and then you can run `docker build`. Using multi-stage containers the build of the application happens within a build phase and then only the build artifacts are copied to a streamlined version of the container with only runtime dependencies. 

## Step 6: Create Log Analytics Workspace

Go to the azure portal or open the azure cli and create a log analtyics workspace. The workspace is used to store logs from application insights and is required in order to move forward creating the application insights resource. Select the same region as the resource group you chose.

* [Create Via CLI](https://docs.microsoft.com/en-us/azure/azure-monitor/logs/quick-create-workspace-cli)
* [Create Via Portal](https://docs.microsoft.com/en-us/azure/azure-monitor/logs/quick-create-workspace)

## Step 7: Create Application Insights

Go to the azure portal or open the azure cli and create an application insights resource. The following documentation covers how to create an application insights resource. Make sure to select `workspace based` and select the log analytics workspace created in the previous step. Select the same region as the resource group you chose.

* [Create in the Azure Portal](https://docs.microsoft.com/en-us/azure/azure-monitor/app/create-workspace-resource)
* [Create via the CLI](https://docs.microsoft.com/en-us/azure/azure-monitor/app/create-workspace-resource#creating-a-resource-automatically)

## Step 8: Test the application

First you need to get the connection string from the application insights resource you just created. See this link on how to locate the connection string https://docs.microsoft.com/en-us/azure/azure-monitor/app/sdk-connection-string?tabs=net#finding-my-connection-string

```bash
export APPLICATIONINSIGHTS_CONNECTION_STRING=<your connection string here>
```

Setting the environment variable in the shell like this will allow the docker cli to pick up the environment variable and pass it to the container on startup. 

Run the following command to start the docker container with the current environment variable. [see](https://docs.docker.com/engine/reference/commandline/run/#set-environment-variables--e---env---env-file)

```bash
 docker run -e APPLICATIONINSIGHTS_CONNECTION_STRING -p 8080:8080 app-insights
```

## Step 9: Look in logs analytics workspace

Go to your log analtyics workspace and view the logs https://docs.microsoft.com/en-us/azure/developer/javascript/tutorial/nodejs-virtual-machine-vm/azure-monitor-application-insights-logs#view-application-traces-in-azure-portal