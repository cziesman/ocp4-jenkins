FROM centos:latest

MAINTAINER Craig Ziesman <cziesman@redhat.com>

USER root

RUN yum install -y java-11-openjdk-devel curl git skopeo which zip unzip && yum clean all

ARG user=jenkins
ARG group=jenkins
ARG uid=1001
ARG gid=0
ARG http_port=8080
ARG agent_port=50000
ARG JENKINS_HOME=/var/jenkins_home
ARG M2_HOME=/usr/share/maven
ARG MAVEN_VERSION=3.6.3
ARG OC_CLIENT_RELEASE="4.4.0-202005281159.git.1.2775aaa.el7/linux-aarch64"

ENV JENKINS_VERSION="2.222.4" \
    JENKINS_USER=admin \
    JENKINS_PASS=admin \
    JENKINS_HOME=$JENKINS_HOME \
    JENKINS_SLAVE_AGENT_PORT=${agent_port} \
    JENKINS_UC=https://updates.jenkins.io \
    JENKINS_UC_EXPERIMENTAL=https://updates.jenkins.io/experimental \
    JENKINS_INCREMENTALS_REPO_MIRROR=https://repo.jenkins-ci.org/incrementals \
    MAVEN_VERSION=$MAVEN_VERSION \
    M2_HOME=$M2_HOME \
    M2=$M2_HOME/bin \
    HOME=$JENKINS_HOME \
    OC_CLIENT_RELEASE=$OC_CLIENT_RELEASE \
    JAVA_OPTS="-Djenkins.install.runSetupWizard=false"

ENV PATH=$M2:$PATH

RUN curl -fsSL https://mirror.openshift.com/pub/openshift-v4/clients/oc/$OC_CLIENT_RELEASE/oc.tar.gz | tar xzf - -C /usr/share && \
    chmod +x /usr/share/oc && \
    ln -s /usr/share/oc /usr/bin/oc

RUN curl -fsSL https://archive.apache.org/dist/maven/maven-3/$MAVEN_VERSION/binaries/apache-maven-$MAVEN_VERSION-bin.tar.gz | tar xzf - -C /usr/share && \
    mv /usr/share/apache-maven-$MAVEN_VERSION /usr/share/maven && \
    ln -s /usr/share/maven/bin/mvn /usr/bin/mvn

RUN mkdir -p $JENKINS_HOME/.m2/repository
RUN echo -e "<settings><localrepository>$JENKINS_HOME/.m2/repository</localrepository>\n</settings>\n" > $JENKINS_HOME/settings.xml

# Jenkins is run with user `jenkins`, uid = 1000
# If you bind mount a volume from the host or a data container,
# ensure you use the same uid
RUN mkdir -p $JENKINS_HOME \
  && chown -R ${uid}:${gid} $JENKINS_HOME \
  && chmod -R g+rw $JENKINS_HOME \
  && useradd -d "$JENKINS_HOME" -u ${uid} -g ${gid} -m -s /bin/bash ${user}

# Jenkins home directory is a volume, so configuration and build history
# can be persisted and survive image upgrades
VOLUME $JENKINS_HOME

# `/usr/share/jenkins/ref/` contains all reference configuration we want
# to set on a fresh new installation. Use it to bundle additional plugins
# or config file with your custom jenkins Docker image.
RUN mkdir -p /usr/share/jenkins/ref/init.groovy.d

# Use tini as subreaper in Docker container to adopt zombie processes
ENV TINI_VERSION v0.19.0
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini /sbin/tini
ADD https://github.com/krallin/tini/releases/download/${TINI_VERSION}/tini.asc /sbin/tini.asc
RUN gpg --batch --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 595E85A6B1B4779EA4DAAEC70B588DFF0527A9B7 && \
    gpg --batch --verify /sbin/tini.asc /sbin/tini
RUN chmod +x /sbin/tini

# jenkins.war checksum, download will be validated using it
ARG JENKINS_SHA=6c95721b90272949ed8802cab8a84d7429306f72b180c5babc33f5b073e1c47c

# Can be used to customize where jenkins.war get downloaded from
ARG JENKINS_URL=https://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/${JENKINS_VERSION}/jenkins-war-${JENKINS_VERSION}.war

# could use ADD but this one does not check Last-Modified header neither does it allow to control checksum
# see https://github.com/docker/docker/issues/8331
RUN curl -fsSL ${JENKINS_URL} -o /usr/share/jenkins/jenkins.war && \
    echo "${JENKINS_SHA}  /usr/share/jenkins/jenkins.war" | sha256sum -c -

RUN chown -R ${user} "$JENKINS_HOME" /usr/share/jenkins/ref

# for main web interface:
EXPOSE ${http_port}

# will be used by attached slave agents:
EXPOSE ${agent_port}

ENV COPY_REFERENCE_FILE_LOG $JENKINS_HOME/copy_reference_file.log

USER ${user}

COPY jenkins-support /usr/local/bin/jenkins-support
COPY jenkins.sh /usr/local/bin/jenkins.sh

COPY install-plugins.sh /usr/local/bin/install-plugins.sh

COPY plugins.txt /usr/share/jenkins/ref/plugins.txt
RUN /usr/local/bin/install-plugins.sh < /usr/share/jenkins/ref/plugins.txt

COPY config.xml /usr/share/jenkins/ref/config.xml

ENTRYPOINT ["/sbin/tini", "--", "/usr/local/bin/jenkins.sh"]
