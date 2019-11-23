FROM ubuntu:16.04

#Updating Ubuntu packages
RUN apt-get update && yes|apt-get upgrade
RUN apt-get install -y bzip2 curl unzip git gcc

#Install Kallisto
RUN curl -LO  https://github.com/pachterlab/kallisto/releases/download/v0.45.0/kallisto_linux-v0.45.0.tar.gz
RUN tar -zxf kallisto_linux-v0.45.0.tar.gz
RUN cp kallisto_linux-v0.45.0/kallisto /usr/local/bin/
RUN rm -rf kallisto_linux-v0.45.0.tar.gz  kallisto_linux-v0.45.0
