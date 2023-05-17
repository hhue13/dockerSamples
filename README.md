# Some sample files for creating Containers

This project contains some sample Docker files which can be used to build Containers based on RedHat ubi images.

## RedHat registries
When working with RedHat UBI Images you can load the from the following registries:

- [Anonymous registry](registry.access.redhat.com)
- [Authenticated registry](registry.redhat.io). It is recommended to use a [RedHat registry service account](https://access.redhat.com/terms-based-registry/) for authentication. To login run
        podman login -u='<org>|<user>' -p=<token> registry.redhat.io

## Building the Tomcat images starting with the ubi image
If you want to build the images yourself starting with the ubi image please see the following [README.md](builtFromUbi/README.md)

## Building the Tomcat images starting using the pre-built Java images
If you want to build the images using the RedHat pre-built Java images and the Tomcat rpm provided by the RHEL Repo see the following [README.md](builtFromJavaPackages/README.md)

# Useful links
- [RedHat - Types of container images](https://access.redhat.com/documentation/de-de/red_hat_enterprise_linux/9/html/building_running_and_managing_containers/assembly_types-of-container-images_building-running-and-managing-containers)

- [RedHat certified container images](https://catalog.redhat.com/software/containers/search)
- [Red Hat Universal Base Image 9](https://catalog.redhat.com/software/containers/ubi9/ubi/615bcf606feffc5384e8452e)
- [Red Hat Universal Base Image 9 Minimal](https://catalog.redhat.com/software/containers/ubi9/ubi-minimal/615bd9b4075b022acc111bf5?container-tabs=gti)
- [OpenJDK 8 on UBI8](https://catalog.redhat.com/software/containers/ubi8/openjdk-8/5dd6a48dbed8bd164a09589a)
- [OpenJDK 11 on UBI9](https://catalog.redhat.com/software/containers/ubi9/openjdk-11/61ee7bafed74b2ffb22b07ab)
- [OpenJDK 17 on UBI9](https://catalog.redhat.com/software/containers/ubi9/openjdk-17/61ee7c26ed74b2ffb22b07f6)

- [RedHat registry service account](https://access.redhat.com/terms-based-registry/)
- [Register a system using the activation key](https://access.redhat.com/solutions/3341191)
- [Creating an activation key](https://access.redhat.com/articles/1378093)
- [RedHat activation keys](https://console.redhat.com/settings/connector/activation-keys)

- [Apache Tomcat versions supported by Red Hat](https://access.redhat.com/solutions/661403)
