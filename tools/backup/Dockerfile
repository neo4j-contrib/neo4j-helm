FROM launcher.gcr.io/google/debian9
RUN apt-get update
RUN apt-get install -y bash curl wget gnupg apt-transport-https apt-utils lsb-release
RUN wget -O - https://debian.neo4j.com/neotechnology.gpg.key | apt-key add -
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN echo 'deb http://debian.neo4j.com stable latest' | tee -a /etc/apt/sources.list.d/neo4j.list
RUN echo "deb http://packages.cloud.google.com/apt cloud-sdk-$(lsb_release -c -s) main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN echo "deb http://httpredir.debian.org/debian stretch-backports main" | tee -a /etc/apt/sources.list.d/stretch-backports.list


RUN echo "neo4j-enterprise neo4j/question select I ACCEPT" | debconf-set-selections
RUN echo "neo4j-enterprise neo4j/license note" | debconf-set-selections

RUN apt-get update && apt-get install -y neo4j-enterprise=1:4.0.4
RUN apt-get install -y google-cloud-sdk

RUN mkdir /data
ADD backup/backup.sh /scripts/backup.sh
RUN chmod +x /scripts/backup.sh

CMD ["/scripts/backup.sh"]
