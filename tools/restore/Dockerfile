FROM neo4j:4.2.7-enterprise
RUN apt-get update \
 && apt-get install -y curl wget gnupg apt-transport-https apt-utils lsb-release unzip less \
 && rm -rf /var/lib/apt/lists/*
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
RUN echo "deb http://packages.cloud.google.com/apt cloud-sdk-$(lsb_release -c -s) main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN echo "deb http://httpredir.debian.org/debian stretch-backports main" | tee -a /etc/apt/sources.list.d/stretch-backports.list

RUN apt-get update && apt-get install -y google-cloud-sdk && rm -rf /var/lib/apt/lists/*
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip" \
 && unzip awscliv2.zip && rm awscliv2.zip \
 && ./aws/install
RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

RUN mkdir -p /data
ADD restore/restore.sh /scripts/restore.sh
RUN chmod +x /scripts/restore.sh

ENTRYPOINT ["bash"]
CMD ["/scripts/restore.sh"]
