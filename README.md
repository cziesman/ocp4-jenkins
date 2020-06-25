# Jenkins Image for OCP4

This image was created to provide support for Java builds using JDK 11, Jenkins 2.222.4, and Maven 3.6.3 on OCP4. The official Red Hat images only support JDK 8, a much older Jenkins with numerous vulnerabilities, and Maven 3.5.

Additionally, this image includes `skopeo`, which is useful for image transfer and signing, and which is not included in the official Red Hat Jenkins image.

This image also installs a number of Jenkins plugins which are useful when interacting with OpenShift during a build.

## Primary Components

[OpenJDK 11](https://openjdk.java.net/projects/jdk/11/) - The open-source reference implementation of version 11 of the Java SE Platform as specified by by JSR 384 in the Java Community Process.

[OpenShift CLI](https://docs.openshift.com/container-platform/4.4/cli_reference/openshift_cli/getting-started-cli.html) - A command-line interface (CLI) that enables creating applications and managing OpenShift Container Platform projects from a terminal.

[Jenkins](https://www.jenkins.io/) - An open source automation server that provides hundreds of plugins to support building, deploying and automating any project.

[Maven](https://maven.apache.org/) - A software project management and comprehension tool. Based on the concept of a project object model (POM), Maven can manage a project's build, reporting and documentation from a central piece of information.

[Skopeo](https://github.com/projectatomic/skopeo/) - A command utility for various operations on container images and image repositories.

## Instructions for deployment

Log in to Openshift.

    oc login --token=<token> --server=https://api.example.com:6443

Create the `ci-cd` project.

    oc new-project ci-cd

If not using the `kubeadmin` user, allow the user to pull from and push images to the OpenShift registry.

    oc policy add-role-to-user registry-viewer <user_name>
    oc policy add-role-to-user registry-editor <user_name>

Patch the registry to set up the default route for external access.

    oc patch configs.imageregistry.operator.openshift.io/cluster \
    --patch '{"spec":{"defaultRoute":true}}' --type=merge


Log in to the redhat registry.

    podman login registry.redhat.io

Pull the openjdk image.

    podman pull registry.redhat.io/openjdk/openjdk-11-rhel7:1.1

Log in to the openshift registry

    podman login -u kubeadmin -p $(oc whoami -t) --tls-verify=false \
    default-route-openshift-image-registry.apps.example.com

Tag the openjdk image.

    podman tag registry.redhat.io/openjdk/openjdk-11-rhel7:1.1 \
    default-route-openshift-image-registry.apps.example.com/ci-cd/openjdk-11-rhel7:1.1

Push the openjdk image to the openshift registry.

    podman push  --tls-verify=false \
    default-route-openshift-image-registry.apps.example.com/ci-cd/openjdk-11-rhel7:1.1

Log in to the web console using your favorite browser at https://console-openshift-console.apps.example.com.

Switch to the Developer perspective.

* Select [Add From Dockerfile]().
* Use https://github.com/cziesman/ocp4-jenkins as the Git Repo URL.
* Leave all other values as the default.
* Select the [Create]() button.

Switch to the Administrator perspective.

* Select [Deployments]().
* Select [ocp-4-jenkins-git]().
* Select [Pods]().
* Wait until the status for `ocp-4-jenkins-git-xxxxxxxxxx` is `Running`.

#### Notes

After deploying the Dockerfile to OpenShift, run the command:

    oc adm policy add-scc-to-user anyuid -z default

Otherwise, Jenkins will not initialize properly. Re-run the deployment if Jenkins initializes with errors.

## Instructions for use

Once Jenkins is up and running, a builds can be configured and a pipeline can be created.

Clone the `spring-training` repository.

    * git clone https://github.com/cziesman/spring-training.git
    * cd spring-training

Create a new project for `spring-training-dev`.

    oc new-project spring-training-dev

Create the `spring-training-binary` build config.

    oc apply -f binary-build-config.yaml

Log in to the web console using your favorite browser at https://console-openshift-console.apps.example.com.

From the Administrator perspective:

* Select [Routes]().
* Select the Location URL: http://ocp-4-jenkins-git-ci-cd.apps.example.com/.
* Select [create a new pipeline]() from the Jenkins dashboard.
* Enter `spring-training` as the item name.
* Select [Pipeline]().
* Select the [OK]() button.

Provide the pipeline configuration:

* In the General section, select the checkbox for `Github project`.
* Enter https://github.com/cziesman/spring-training.git as the Project url.
* Select the checkbox for `This project is parameterized`.
* Select `Add parameter->Boolean Parameter`.
* Enter `SKIP_OWASP` as the name.
* In the Pipeline section, select `Definition->Pipeline script from SCM`.
* Select `SCM->Git`.
* Enter https://github.com/cziesman/spring-training.git as the Repository URL.
* Select the `Save` button

Credentials are required to pull images from the OpenShift internal registry and to push images to quay.io. From the Jenkins dashboard:

* Select [Manage Jenkins->Manage Credentials]().
* Select [(global)->Add credentials]() under `Stores scoped to Jenkins`.
* Enter `kubeadmin` as the Username and the admin password as the password.
* Enter `registry-secret` as the ID.
* Select the [OK]() button.

Repeat the steps for the quay.io credentials

* Select [(global)->Add credentials]() under `Stores scoped to Jenkins`.
* Enter your Quay username as the Username and your Quay password as the password.
* Enter `quay-secret` as the ID.
* Select the [OK]() button.

Run the build:

* Select [spring-training]() from the Jenkins dashboard.
* Select [Build with Parameters]() from the menu on the left.
* Select the checkbox for `SKIP_OWASP` if you want to skip the OWASP vulnerability checks during the build. Otherwise just leave it unchecked.
* Select the [Build]() button to start the build.
