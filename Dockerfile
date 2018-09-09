#
# tomcat8 Dockerfile
# Based on https://github.com/rossbachp/dockerbox
#
#
# Pull base image.
FROM ubuntu:18.04
MAINTAINER Sigurd Nes <sigurdne@online.no>


ENV JAVAVERSION 8

RUN \
  apt-get update && \
  apt-get install -y curl software-properties-common wget pwgen

# Install Java and clean up download cache.

RUN \
  echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
  echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \
  add-apt-repository -y ppa:webupd8team/java && \
  apt-get update && \
  apt-get install -y oracle-java${JAVAVERSION}-installer
RUN \
  rm -rf /var/cache/oracle-jdk${JAVAVERSION}-installer && \
  rm -f /usr/lib/jvm/java-${JAVAVERSION}-oracle/src.zip && \
  rm -f /usr/lib/jvm/java-${JAVAVERSION}-oracle/javafx-src.zip && \
  rm -rf /usr/share/doc /usr/share/man && \
  apt-get --purge remove -y software-properties-common && \
  apt-get clean autoclean && \
  apt-get autoremove -y && \
  rm -rf /var/lib/{apt,dpkg,cache,log}/


# install tomcat

ENV TOMCAT_MAJOR_VERSION 8
ENV TOMCAT_MINOR_VERSION 8.5.33
ENV CATALINA_HOME /opt/tomcat

ENV JAVA_MAXMEMORY 256

ENV TOMCAT_MAXTHREADS 250
ENV TOMCAT_MINSPARETHREADS 4
ENV TOMCAT_HTTPTIMEOUT 20000
#ENV TOMCAT_JVM_ROUTE tomcat80
ENV DEPLOY_DIR /webapps
ENV LIBS_DIR /libs
ENV PATH $PATH:$CATALINA_HOME/bin

# INSTALL TOMCAT
RUN wget -q https://archive.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_MINOR_VERSION}/bin/apache-tomcat-${TOMCAT_MINOR_VERSION}.tar.gz && \
  wget -qO- https://www.apache.org/dist/tomcat/tomcat-${TOMCAT_MAJOR_VERSION}/v${TOMCAT_MINOR_VERSION}/bin/apache-tomcat-${TOMCAT_MINOR_VERSION}.tar.gz.sha1 | sha1sum -c - && \
  tar zxf apache-tomcat-*.tar.gz && \
  rm apache-tomcat-*.tar.gz && \
  mv apache-tomcat* ${CATALINA_HOME}

# Remove unneeded apps and files
RUN rm -rf ${CATALINA_HOME}/webapps/examples ${CATALINA_HOME}/webapps/docs ${CATALINA_HOME}/webapps/ROOT ${CATALINA_HOME}/webapps/host-manager ${CATALINA_HOME}/RELEASE-NOTES ${CATALINA_HOME}/RUNNING.txt ${CATALINA_HOME}/bin/*.bat  ${CATALINA_HOME}/bin/*.tar.gz


ADD server.xml ${CATALINA_HOME}/conf/server.xml
ADD logging.properties ${CATALINA_HOME}/conf/logging.properties
ADD tomcat.sh ${CATALINA_HOME}/bin/tomcat.sh
RUN chmod +x ${CATALINA_HOME}/bin/*.sh

RUN groupadd -r tomcat -g 433 && \
useradd -u 431 -r -g tomcat -d ${CATALINA_HOME} -s /sbin/nologin -c "Docker image user" tomcat && \
chown -R tomcat:tomcat ${CATALINA_HOME}

RUN apt-get clean autoclean && \
    apt-get autoremove -y && \
    rm -rf /var/lib/{apt,dpkg,cache,log}/


## Start install BIMserver

RUN mkdir /var/www/localhost -p
RUN mkdir /var/bimserver/home -p
RUN chown -R tomcat /var/bimserver

# Download BIMserver into /webapps for autodeploy

RUN wget https://github.com/opensourceBIM/BIMserver/releases/download/v1.5.101/bimserverwar-1.5.101.war \
	-O /var/www/localhost/ROOT.war

# alternative: add from local file
#ADD ./bimserverwar-1.5.101.war /var/www/localhost/ROOT.war

RUN chown -R tomcat /var/www/localhost

ENV CATALINA_OPTS="-Xms512M -Xmx1024M -server -XX:+UseParallelGC"

VOLUME /var/bimserver/home

## End install BIMserver

WORKDIR /opt/tomcat

EXPOSE 8080
EXPOSE 8009

USER tomcat


CMD ["/opt/tomcat/bin/tomcat.sh"]


# NOTE TO SELF:
# docker build -t sigurdne/bimserver .
# docker run -p 8082:8080 -v "/var/bimserver/home:/var/bimserver/home" -d --name bimserver sigurdne/bimserver
# docker run -it --rm sigurdne/bimserver
# docker stop --time=10 bimserver
# docker stop $(docker ps -a -q)  > /dev/null 2>&1
# docker rm $(docker ps -a -q)
# docker images --no-trunc| grep none | awk '{print $3}' | xargs -r docker rmi
# docker push sigurdne/bimserver

