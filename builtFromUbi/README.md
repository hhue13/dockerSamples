# Building the Java base containers from ubi image

You can use [Containerfile.java](./Containerfile.java) file to build an image with the Java package (from the rpm registry) name you want to have installed in the image. This image has the following _build-arg_ parameters:

- __REL_BASEIMAGE__ - the base minimal ubi image to use like for example _registry.redhat.io/ubi9/ubi-minimal:9.2-484_
- __JAVA_VERSION__ - the Java rpm to be installed in the container

So the build commands to build:

- Image with Java17:
        ```podman build -f Containerfile.java -t localhost/itrzzs/java17:$(date +"%Y.%V") --build-arg REL_BASEIMAGE="registry.redhat.io/ubi9/ubi-minimal:9.2-484" --build-arg JAVA_VERSION="java-17-openjdk" .```
- Image with Java11:
        ```podman build -f Containerfile.java -t localhost/itrzzs/java11:$(date +"%Y.%V") --build-arg REL_BASEIMAGE="registry.redhat.io/ubi9/ubi-minimal:9.2-484" --build-arg JAVA_VERSION="java-11-openjdk" .```
- Image with Java8:
        ```podman build -f Containerfile.java -t localhost/itrzzs/java8:$(date +"%Y.%V") --build-arg REL_BASEIMAGE="registry.redhat.io/ubi9/ubi-minimal:9.2-484" --build-arg JAVA_VERSION="java-1.8.0-openjdk" .```

# Building the Apache TomCat image based on a Java image

The Java images built in the step above can the be used to create TomCat images being used. The file [Containerfile.tomcat](./Containerfile.tomcat) can be used to install TomCat taking the binaries from the [Apache download page for TomCat 9](https://dlcdn.apache.org/tomcat/tomcat-9).

This image has the following _build-arg_ parameters:

- __JAVA_BASEIMAGE__ - the base image with Java installed. For example _localhost/itrzzs/java11:2023.20_
- __TOMCAT_VERSION__ - the TomCat version for the download from [https://dlcdn.apache.org/tomcat-9](https://dlcdn.apache.org/tomcat/tomcat-9/). For example _9.0.75_.
- __TOMCAT_BASE_DIR__ - the directory to which TomCat should be installed in the image. Defaults to _/opt/tomcat_


So the build commands to build:

- Image with Java17 & TomCat 9.0.75 is:
        ```podman build -f Containerfile.tomcat -t localhost/itrzzs/tomcat-9.0.75-java8:$(date +"%Y.%V") --build-arg JAVA_BASEIMAGE="localhost/itrzzs/java8:2023.20" --build-arg TOMCAT_VERSION="9.0.75" .```
- Image with Java11 & TomCat 9.0.75 is:
        ```podman build -f Containerfile.tomcat -t localhost/itrzzs/tomcat-9.0.75-java11:$(date +"%Y.%V") --build-arg JAVA_BASEIMAGE="localhost/itrzzs/java11:2023.20" --build-arg TOMCAT_VERSION="9.0.75" .```
- Image with Java8 & TomCat 9.0.75 is:
        ```podman build -f Containerfile.tomcat -t localhost/itrzzs/tomcat-9.0.75-java17:$(date +"%Y.%V") --build-arg JAVA_BASEIMAGE="localhost/itrzzs/java17:2023.20" --build-arg TOMCAT_VERSION="9.0.75" .```

# Running the images

You can run and test the images (assuming they were built in week 20 of 2023 - otherwise you need to adjust the tag accordingly) by running:

- ```podman run -d -p8080:8080 localhost/itrzzs/tomcat-9.0.75-java8:2023.20```
- ```podman run -d -p8081:8080 localhost/itrzzs/tomcat-9.0.75-java11:2023.20```
- ```podman run -d -p8082:8080 localhost/itrzzs/tomcat-9.0.75-java17:2023.20```

and then access TomCat via [http://localhost:8080](http://localhost:8080), [http://localhost:8081](http://localhost:8081) [http://localhost:8082](http://localhost:8082) - depending on which container you want to access.

# Size of the build images

The size of the resulting images when writing this documentation was:

| Image      | Size |
| :---        |    :----:   |
| tomcat-9.0.75-java8 | 814 MB |
| tomcat-9.0.75-java11 | 857 MB |
| tomcat-9.0.75-java17 | 866 MB |
