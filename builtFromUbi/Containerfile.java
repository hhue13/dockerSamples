##
## Get the tag of the latest test image:
## curl -L -o hhue.json -X GET https://registry.access.redhat.com/v2/ubi9/ubi-minimal/tags/list && cat hhue.json | jq ".tags" | tr -d '" ,' | grep -Po "[0-9]{1,2}\.[0-9]{1,2}\.{0,1}[0-9]{0,2}-{0,1}[0-9]{0,4}$" |sort | tail -1
##
## Sample build command:
## time podman build -f Containerfile.java11 -t localhost/itrzzs/java11:$(date +"%Y.%V") --build-arg REL_BASEIMAGE="registry.redhat.io/ubi9/ubi-minimal:9.2-484" --build-arg JAVA_VERSION="java-17-openjdk" . 2>&1
##
## Note on the registry:
## ====================
## Anonymous registry: registry.access.redhat.com
## Authenticated registry: registry.redhat.io --> Requires login! See https://access.redhat.com/terms-based-registry/ for token login.
## podman login -u='11730776|hhuebler' -p=<token> registry.redhat.io
##
## Install tomcat following: https://computingforgeeks.com/install-apache-tomcat-9-on-linux-rhel-centos/?utm_content=cmp-true

FROM ${REL_BASEIMAGE}

ARG REL_BASEIMAGE
ARG JAVA_VERSION

LABEL REL_BASEIMAGE=${REL_BASEIMAGE}
LABEL JAVA_VERSION=${JAVA_VERSION}


RUN 	microdnf --setopt=install_weak_deps=0 -y install tar \
        gzip \
        net-tools \
        procps \
        ${JAVA_VERSION} && \
        microdnf -y update && \
        microdnf clean all
