FROM debian:stretch

# Tools needed
# gcloud
# helm
# kubectl
# node
# npm

# Secure software install; required first in order to be able to process keys, packages, etc.
RUN apt-get update && apt-get install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common

# Google Cloud stuff
RUN echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
RUN curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -

# Docker stuff
RUN curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
RUN add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable"

# Will run apt-get update for us.
RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -

RUN apt-get install -y google-cloud-sdk wget make gettext-base jq nodejs npm

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash

# Install helm
RUN curl -LO https://get.helm.sh/helm-v3.2.1-linux-amd64.tar.gz
RUN tar zxvf helm-v3.2.1-linux-amd64.tar.gz
RUN mv linux-amd64/helm /usr/bin
RUN /usr/bin/helm version

# Kubectl
RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl
RUN chmod +x kubectl
RUN mv kubectl /usr/bin
RUN /usr/bin/kubectl --help
