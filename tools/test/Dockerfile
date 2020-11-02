FROM launcher.gcr.io/google/debian9
RUN apt-get update && apt-get -y upgrade
RUN apt-get install -y bash curl wget gnupg apt-transport-https curl apt-utils jq
RUN echo 'deb http://ftp.debian.org/debian stretch-backports main' | tee /etc/apt/sources.list.d/stretch-backports.list
RUN apt-get update
RUN apt-get install -y ca-certificates ca-certificates-java
RUN curl https://debian.neo4j.com/neotechnology.gpg.key | apt-key add -
RUN echo 'deb http://debian.neo4j.com stable 4.1' | tee -a /etc/apt/sources.list.d/neo4j.list
RUN apt-get update
RUN apt-get install -y cypher-shell=4.1.2
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

CMD ["/bin/bash"]
