Jenkins Image for OCP4
=============================

## Primary Components

[Skopeo](https://github.com/projectatomic/skopeo/) - A command utility for various operations on container images and image repositories.

This image will run without issue using Docker or Podman, but needs help to run in Openshift.

After deploying the Dockerfile to Openshift, run the command:
  oc adm policy add-scc-to-user anyuid -z default
Otherwise, Jenkins will not initialize properly.
