# Building the Apache TomCat image based on a Redhat Java image

RedHat as well provides Java base images which can be used to create TomCat images. The file [Containerfile.tomcat](./Containerfile.tomcat) can be used to install TomCat as well.    
In this example we are not downloading Apache Tomcat from  the [Apache download page for TomCat 9](https://dlcdn.apache.org/tomcat/tomcat-9) but installing the rpm from the Redhat Enterprise Linux repository. Hence the version installed will be the version which is available there at the time of the built. At the time of writing this documentation the version was 9.0.62     
**Note**: This requires the image to be built on a _RedHat Enterprise Linux_ system as otherwise the rpm repositories which require subscription are not available.

This image has the following _build-arg_ parameters:

- __JAVA_BASEIMAGE__ - the base image with Java installed. For example _registry.access.redhat.com/ubi9/openjdk-17:1.14-2.1681917140_
- __IMAGE_USER__ - The non-root user in the base image under which TomCat runs. This _build-arg_ defaults to the value **default**     
        **Note**: For the Java11 & Java17 base image the user must be **default**. For the Java8 base image the user must be **jboss**


So the build commands to build:

- Image with Java17 & TomCat is:
        ```podman build -f Containerfile.tomcat -t localhost/itrzzs/openjdk-17-tomcat:$(date +"%Y.%V") --build-arg JAVA_BASEIMAGE="registry.access.redhat.com/ubi9/openjdk-17:1.14-2.1681917140" --build-arg IMAGE_USER="default" .```
- Image with Java11 & TomCat is:
        ```podman build -f Containerfile.tomcat -t localhost/itrzzs/openjdk-11-tomcat:$(date +"%Y.%V") --build-arg JAVA_BASEIMAGE="registry.access.redhat.com/ubi9/openjdk-11:1.14-2.1681920275" --build-arg IMAGE_USER="default" .```
- Image with Java8 & TomCat is:
        ```podman build -f Containerfile.tomcat -t localhost/itrzzs/openjdk-8-tomcat:$(date +"%Y.%V") --build-arg JAVA_BASEIMAGE="registry.access.redhat.com/ubi8/openjdk-8:1.15-1.1682399183" --build-arg IMAGE_USER="jboss" .```
        **Note**: This image is based on the _ubi8-minimal__ image

# Running the images

You can run and test the images (assuming they were built in week 20 of 2023 - otherwise you need to adjust the tag accordingly) by running:

- ```podman run -d -p8080:8080 localhost/itrzzs/openjdk-17-tomcat:2023.20```
- ```podman run -d -p8081:8080 localhost/itrzzs/openjdk-11-tomcat:2023.20```
- ```podman run -d -p8082:8080 localhost/itrzzs/openjdk-8-tomcat:2023.20```

and then access TomCat via [http://localhost:8080](http://localhost:8080), [http://localhost:8081](http://localhost:8081) [http://localhost:8082](http://localhost:8082) - depending on which container you want to access.

# Size of the build images
The size of the resulting images when writing this documentation was:

| Image      | Size |
| :---        |    :----:   |
| openjdk-8-tomcat | 832 MB |
| openjdk-11-tomcat | 788 MB |
| openjdk-17-tomcat | 1.01 GB |
