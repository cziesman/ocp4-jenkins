FROM centos:latest

MAINTAINER Craig Ziesman <cziesman@redhat.com>

USER root

RUN yum install -y java-11-openjdk-devel curl git skopeo which zip unzip && yum clean all

FROM maven:3.6.3-openjdk-11

USER root

RUN echo '$MAVEN_HOME='$MAVEN_HOME

FROM jenkins/jenkins:jdk11

USER root

ENV  JAVA_OPTS="-Djenkins.install.runSetupWizard=false" \
     HOME=/var/jenkins_home

COPY plugins.txt ${REF}/plugins.txt
RUN /usr/local/bin/install-plugins.sh < ${REF}/plugins.txt

RUN mkdir -p $HOME && \
    chown -R 1000:0 $HOME && \
    chmod -R g+rw $HOME

#VOLUME $HOME

USER 1000

WORKDIR $HOME
