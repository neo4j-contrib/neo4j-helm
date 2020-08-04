FROM debian:stretch
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
