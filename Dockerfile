FROM centos:latest

MAINTAINER Craig Ziesman <cziesman@redhat.com>

USER root

RUN yum install -y java-11-openjdk-devel curl git skopeo which zip unzip && yum clean all

FROM maven:3.6.3-openjdk-11

USER root

RUN echo '$MAVEN_HOME='$MAVEN_HOME

FROM jenkins/jenkins:jdk11

USER root

ENV JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

RUN echo JENKINS_HOME=$JENKINS_HOME

USER 1000

COPY plugins.txt ${REF}/plugins.txt
RUN /usr/local/bin/install-plugins.sh < ${REF}/plugins.txt

RUN chown -R 1000:1000 "$JENKINS_HOME" ${REF}

WORKDIR $JENKINS_HOME
