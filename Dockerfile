FROM frolvlad/alpine-oraclejdk8:cleaned
MAINTAINER Javier de Diego Navarro - Eager Minds [javier@eager-minds.com]

# Environment vars
ENV JIRA_HOME           /var/atlassian/jira
ENV JIRA_INSTALL        /opt/atlassian/jira
ENV JIRA_VERSION        7.8.1
ENV MYSQL_VERSION       5.1.45
ENV POSTGRES_VERSION    42.2.1

ENV RUN_USER            root
ENV RUN_GROUP           root

ARG DOWNLOAD_URL=https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-core-${JIRA_VERSION}.tar.gz
ARG MYSQL_CONNECTOR_DOWNLOAD_URL=https://dev.mysql.com/get/Downloads/Connector-J/mysql-connector-java-${MYSQL_VERSION}.tar.gz
ARG MYSQL_CONNECTOR_JAR=mysql-connector-java-${MYSQL_VERSION}/mysql-connector-java-${MYSQL_VERSION}-bin.jar
ARG OLD_POSTGRES_CONNECTOR_JAR=postgresql-9.4.1212.jar
ARG POSTGRES_CONNECTOR_DOWNLOAD_URL=https://jdbc.postgresql.org/download/postgresql-${POSTGRES_VERSION}.jar
ARG POSTGRES_CONNECTOR_JAR=postgresql-${POSTGRES_VERSION}.jar


# Print executed commands
RUN set -x

# Install requeriments
RUN apk update -qq
RUN apk add --no-cache     wget curl openssh bash procps openssl perl ttf-dejavu tini xmlstarlet
RUN update-ca-certificates

# Jira set up
RUN mkdir -p               "${JIRA_HOME}"
RUN chmod -R 700           "${JIRA_HOME}"
RUN mkdir -p               "${JIRA_INSTALL}"
RUN curl -Ls               "$DOWNLOAD_URL" | tar -xz --strip-components=1 -C "$JIRA_INSTALL"
RUN ls -la                 "${JIRA_INSTALL}/bin"

# Database connectors
RUN curl -Ls               "${MYSQL_CONNECTOR_DOWNLOAD_URL}"   \
     | tar -xz --directory "${JIRA_INSTALL}/lib"               \
                           "${MYSQL_CONNECTOR_JAR}"            \
                           --strip-components=1 --no-same-owner
RUN rm -f                  "${JIRA_INSTALL}/lib/${OLD_POSTGRES_CONNECTOR_JAR}"
RUN curl -Ls               "${POSTGRES_CONNECTOR_DOWNLOAD_URL}" -o "${JIRA_INSTALL}/lib/${POSTGRES_CONNECTOR_JAR}"
RUN echo -e                "\njira.home=$JIRA_HOME" >> "${JIRA_INSTALL}/atlassian-jira/WEB-INF/classes/jira-application.properties"
RUN touch -d               "@0" "${JIRA_INSTALL}/conf/server.xml"


USER root:root

# Expose default HTTP connector port.
EXPOSE 8080

VOLUME ["/var/atlassian/jira", "/opt/atlassian/jira/logs"]

WORKDIR $JIRA_HOME

COPY "entrypoint.sh" "/"

ENTRYPOINT ["/sbin/tini", "--"]
CMD ["/entrypoint.sh", "-fg"]
