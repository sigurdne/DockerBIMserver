#
# BIMserver 1.5.184 on Tomcat 9.0
#

FROM tomcat:9.0
LABEL maintainer="Sigurd Nes <sigurdne@online.no>"

RUN echo "Europe/Oslo" > /etc/timezone
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure -f noninteractive tzdata


RUN mkdir /var/www/localhost -p
RUN mkdir /var/bimserver/home -p

# Download BIMserver into /webapps for autodeploy

RUN wget https://github.com/opensourceBIM/BIMserver/releases/download/v1.5.184/bimserverwar-1.5.184.war \
	-O /var/www/localhost/ROOT.war


# For local build
# ADD ./bimserverwar-1.5.184.war /var/www/localhost/ROOT.war

ENV CATALINA_OPTS="-Xms512M -Xmx8345M"


ENV CATALINA_HOME /usr/local/tomcat
ADD server.xml ${CATALINA_HOME}/conf/server.xml


RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

VOLUME /var/bimserver/home
EXPOSE 8080

# Command on startup
CMD ["catalina.sh", "run"]


# NOTE TO SELF:
# docker build -t sigurdne/bimserver .
# docker run -p 8080:8080 -v "/var/bimserver/home:/var/bimserver/home" -d --name bimserver sigurdne/bimserver
# docker run -it --rm sigurdne/bimserver
# docker stop --time=10 bimserver
# docker stop $(docker ps -a -q)  > /dev/null 2>&1
# docker rm $(docker ps -a -q)
# docker images --no-trunc| grep none | awk '{print $3}' | xargs -r docker rmi
# docker exec -i -t bimserver bash #by Name
# docker push sigurdne/bimserver
