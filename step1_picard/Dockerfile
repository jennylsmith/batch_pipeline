#Original: https://github.com/FredHutch/docker-ls2/blob/master/picard/Dockerfile

FROM ubuntu:16.04

#Updating Ubuntu packages
RUN apt-get update && yes|apt-get upgrade
RUN apt-get install -y bzip2 curl unzip git gcc libc6-i386

#Set up the working directory
WORKDIR /picard

#Download the Picard tools jar
RUN curl -LO https://github.com/broadinstitute/picard/releases/download/2.13.2/picard.jar

#Download and install java
COPY jre-8u231-linux-x64.tar.gz /picard
RUN tar -zxf jre-8u231-linux-x64.tar.gz -C /picard \
    && rm jre-8u231-linux-x64.tar.gz
ENV JAVA_HOME /picard/jre1.8.0_231
RUN update-alternatives --install "/usr/bin/java" "java" "/picard/jre1.8.0_231/bin/java" 1
RUN update-alternatives --set java /picard/jre1.8.0_231/bin/java
