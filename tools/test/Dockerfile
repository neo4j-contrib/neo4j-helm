FROM launcher.gcr.io/google/debian9
RUN apt-get update && apt-get -y upgrade && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y bash curl wget gnupg apt-transport-https curl apt-utils jq && rm -rf /var/lib/apt/lists/*
RUN echo 'deb https://ftp.debian.org/debian stretch-backports main' | tee /etc/apt/sources.list.d/stretch-backports.list
RUN apt-get update && apt-get install -y ca-certificates ca-certificates-java && rm -rf /var/lib/apt/lists/*
RUN curl https://debian.neo4j.com/neotechnology.gpg.key | apt-key add -
RUN echo 'deb https://debian.neo4j.com stable 4.2' | tee -a /etc/apt/sources.list.d/neo4j.list
RUN apt-get update && apt-get install -y cypher-shell=4.2.2  && rm -rf /var/lib/apt/lists/*
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

CMD ["/bin/bash"]
