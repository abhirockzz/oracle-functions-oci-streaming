FROM fnproject/fn-java-fdk-build:1.0.85 as build-stage
WORKDIR /function
ENV MAVEN_OPTS -Dhttp.proxyHost= -Dhttp.proxyPort= -Dhttps.proxyHost= -Dhttps.proxyPort= -Dhttp.nonProxyHosts= -Dmaven.repo.local=/usr/share/maven/ref/repository
ADD pom.xml /function/pom.xml

ARG OCI_JAVA_SDK_VERSION=1.4.0
RUN echo "using OCI Java SDK version " $OCI_JAVA_SDK_VERSION
ARG OCI_JAVA_SDK_JAR_NAME=oci-java-sdk-full-$OCI_JAVA_SDK_VERSION.jar

ARG OCI_JAVA_SDK_RELEASE_URL=https://github.com/oracle/oci-java-sdk/releases/download/v$OCI_JAVA_SDK_VERSION/oci-java-sdk.zip
RUN curl -LJO $OCI_JAVA_SDK_RELEASE_URL
RUN unzip -d oci-java-sdk oci-java-sdk.zip

ARG OCI_JAVA_SDK_JAR_PATH=oci-java-sdk/lib/$OCI_JAVA_SDK_JAR_NAME
#deploy it to /function/repo. This location is referenced in <repository> in the pom.xml
RUN mvn deploy:deploy-file -Durl=file:///function/repo -Dfile=$OCI_JAVA_SDK_JAR_PATH -DgroupId=com.oracle.oci.sdk -DartifactId=oci-java-sdk -Dversion=$OCI_JAVA_SDK_VERSION -Dpackaging=jar

RUN ["mvn", "package", "dependency:copy-dependencies", "-DincludeScope=runtime", "-DskipTests=true", "-Dmdep.prependGroupId=true", "-DoutputDirectory=target", "--fail-never"]
ADD src /function/src
RUN ["mvn", "package"]

RUN rm -r oci-java-sdk

FROM fnproject/fn-java-fdk:1.0.85
WORKDIR /function
COPY --from=build-stage /function/target/*.jar /function/app/

# Add OCI private key for OCI Java SDK authentication (OCI object storage API)
ARG PRIVATE_KEY_NAME
COPY $PRIVATE_KEY_NAME /function/$PRIVATE_KEY_NAME
# OCI_PRIVATE_KEY_FILE_NAME is used as environment variable in the function code. Altered name to avoid confusion
ENV OCI_PRIVATE_KEY_FILE_NAME=${PRIVATE_KEY_NAME}

CMD ["com.example.fn.StreamProducerFunction::produce"]
