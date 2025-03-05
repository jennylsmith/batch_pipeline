FROM ubuntu:noble

# Updating Ubuntu packages
RUN apt-get update && yes|apt-get upgrade
RUN apt-get install -y bzip2 curl unzip git gcc

# Version
ENV KALLISTO_VER="v0.51.1"

# Install Kallisto
RUN curl -LO  https://github.com/pachterlab/kallisto/releases/download/${KALLISTO_VER}/kallisto_linux-${KALLISTO_VER}.tar.gz
RUN tar -zxf kallisto_linux-${KALLISTO_VER}.tar.gz && cp kallisto/kallisto /usr/local/bin/kallisto
RUN rm -rf kallisto_linux-${KALLISTO_VER}.tar.gz  kallisto_linux/
