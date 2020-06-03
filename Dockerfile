FROM centos:latest

MAINTAINER Craig Ziesman <cziesman@redhat.com>

USER root

RUN yum install -y java-11-openjdk-devel git skopeo zip unzip && yum clean all

FROM maven:3.6.3-openjdk-11

USER root

FROM jenkins/jenkins:jdk11

USER root

ENV  JAVA_OPTS="-Djenkins.install.runSetupWizard=false" \
     HOME=/var/jenkins_home

COPY plugins.txt ${REF}/plugins.txt
RUN /usr/local/bin/install-plugins.sh < ${REF}/plugins.txt

#RUN mkdir -p $HOME && \
#    chown -R 1000:0 $HOME && \
#    chmod -R go+rw $HOME && \
#    usermod -d $HOME -u 1000 -g 0 -m -s /bin/bash jenkins

#RUN chgrp -R 0 $HOME && \
#    chmod -R g=u $HOME

RUN chown -R 1000:0 $HOME && \
    find ${HOME} -type d -exec chmod g+ws {} \;
VOLUME $HOME

WORKDIR $HOME
USER 1000
