# Sample Helm charts to setup an OCP cluster
In this directory tree we collect some sample Helm Charts which we can use to setup an OCP cluster

## setup-project: HELM Chart to setup and manage OCP projects
This Helm Chart can be used to manage the projects on the cluster as an [ArgoCD](https://argo-cd.readthedocs.io/en/stable/) application. 

The base logic behind this Helm chart is the following:

- There is a sets of defaults values configured in [default-values.yaml](setup-project/values/crc/default-values.yaml) which apply to all projects **unless**:
  - The default is **disabled** by setting the `enabled` attribute to `false`
  - The default is **overwritten** by project specific values
- There is **one** values files per OCP project and cluster to be setup. The values files is under `setup-project/values/<cluster>/<project-name>-values.yaml`

### Structure of the values files
This Helm chart has basically two categories of values files namely:

- the values file for the defaults. The name is not relevant however this file **must** contain the dictionary named _defaultSettings_.    
**Note**: There mist be only one values file with the _defaultSettings_ dictionary
- the values files(s) for the projects to be created. It is _highly recommended_ to create one values file per project. This values file(s) are used to set the values per project and must start with the following stanza:    
```yaml
projects:
  <name of the project>:
    metaData:
      displayName: "<displayName>"
      description: |
        This is just a test
        project to test the template
      requester: hhue
``` 
**Note**: _metaData.requester_ is the only required attribute from the _metdaData_ stanza
> **Note**: If using multiple values files containing the same object (list, dictionary) the **LISTS** are **replaced** and **DICTIONARIES** are **merged** to one dictionary.
### Supported 'kind:' objects
The Helm chart supports certain OpenShift **kind:** objects only. Please see the section _Template stanza for supported values_ of the provided [default-values.yaml](setup-project/values/crc/default-values.yaml) file for a list of supported objects. Each of the objects can be defined in the default values file or at the respective level on a per project basis.

### How defaults are handled
The Helm chart allows to enable / disabled OpenShift objects via the `enabled` attribute for every stanza. This applies to the defaults as well as for the project specific definitions as well.    
> **NOTE**: However the following ***rule*** applies: If an object type is enabled the matching data section **must** be specified as well!

#### Object is enabled in defaults and in project specific values file
If an object is enabled in the defaults and in the project specific values files then the **project specific** value has **priority**    

For example: The defaults file might contain the following stanza:
```yaml
defaultSettings:
  limitRanges:
    enabled: true
    limits:
      - type: "Container"
        max:
          cpu: "2"
          memory: "1Gi"
        min:
          cpu: "100m"
          memory: "4Mi"
        defaultRequest:
          cpu: "100m"
          memory: "100Mi"
```
while the values file for the yyproject contains:    
```yaml
projects:
  yy-project:
    metaData:
      requester: test-requester
    limitRanges:
      enabled: true
      limits:
        - type: "Container"
          max:
            cpu: "4"
            memory: "4Gi"
          min:
            cpu: "10m"
            memory: "10Mi"
          defaultRequest:
            cpu: "10m"
            memory: "10Mi"
``` 
This will generate the following stanza fpr the `LimitRange` object:
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: "yy-project-limit-ranges"
  namespace: "yy-project"
  labels:    
    helm.sh/chart: "setup-project-0.1.0"
    app.kubernetes.io/name: setup-project
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/version: "1.16.0"
    app.kubernetes.io/managed-by: Helm
spec:
  limits:
    - defaultRequest:
        cpu: 10m
        memory: 10Mi
      max:
        cpu: "4"
        memory: 4Gi
      min:
        cpu: 10m
        memory: 10Mi
      type: Container
```

#### Object is enabled in defaults values file and disabled or missing in project specific values file
If an object is enabled in the defaults values files and disabled or missing in the project specific values files then the values in te **defaults** will be used **priority**    
For example: The defaults file might contain the following stanza:

```yaml
defaultSettings:
  limitRanges:
    enabled: true
    limits:
      - type: "Container"
        max:
          cpu: "2"
          memory: "1Gi"
        min:
          cpu: "100m"
          memory: "4Mi"
        defaultRequest:
          cpu: "100m"
          memory: "100Mi"
```
but we update the project values file from the previous example to disable the `projects.yy-project.limitRanges.enabled=false` or completely remove that stanza from the project specific file:
```yaml
projects:
  yy-project:
    metaData:
      requester: test-requester
    limitRanges:
      enabled: false
      limits:
        - type: "Container"
          max:
            cpu: "4"
            memory: "4Gi"
          min:
            cpu: "10m"
            memory: "10Mi"
          defaultRequest:
            cpu: "10m"
            memory: "10Mi"
``` 
We get the following `LimitRange` object rendered:
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: "yy-project-limit-ranges"
  namespace: "yy-project"
  labels:    
    helm.sh/chart: "setup-project-0.1.0"
    app.kubernetes.io/name: setup-project
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/version: "1.16.0"
    app.kubernetes.io/managed-by: Helm
spec:
  limits:
    - defaultRequest:
        cpu: 100m
        memory: 100Mi
      max:
        cpu: "2"
        memory: 1Gi
      min:
        cpu: 100m
        memory: 4Mi
      type: Container
```

#### Object is disabled or missing in defaults values file and enabled project specific values file

For example: The defaults file might contain the following stanza:

```yaml
defaultSettings:
  limitRanges:
    enabled: false
    limits:
      - type: "Container"
        max:
          cpu: "2"
          memory: "1Gi"
        min:
          cpu: "100m"
          memory: "4Mi"
        defaultRequest:
          cpu: "100m"
          memory: "100Mi"
```

while the values file for the yyproject contains:

```yaml
projects:
  yy-project:
    metaData:
      requester: test-requester
    limitRanges:
      enabled: true
      limits:
        - type: "Container"
          max:
            cpu: "4"
            memory: "4Gi"
          min:
            cpu: "10m"
            memory: "10Mi"
          defaultRequest:
            cpu: "10m"
            memory: "10Mi"
```
We get the following `LimitRange` object rendered:
```yaml
apiVersion: v1
kind: LimitRange
metadata:
  name: "yy-project-limit-ranges"
  namespace: "yy-project"
  labels:    
    helm.sh/chart: "setup-project-0.1.0"
    app.kubernetes.io/name: setup-project
    app.kubernetes.io/instance: release-name
    app.kubernetes.io/version: "1.16.0"
    app.kubernetes.io/managed-by: Helm
spec:
  limits:
    - defaultRequest:
        cpu: 10m
        memory: 10Mi
      max:
        cpu: "4"
        memory: 4Gi
      min:
        cpu: 10m
        memory: 10Mi
      type: Container
```

#### Object is disabled or missing in defaults values file and disabled or missing in project specific values file
For example: The defaults file might contain the following stanza:

```yaml
defaultSettings:
  limitRanges:
    enabled: false
    limits:
      - type: "Container"
        max:
          cpu: "2"
          memory: "1Gi"
        min:
          cpu: "100m"
          memory: "4Mi"
        defaultRequest:
          cpu: "100m"
          memory: "100Mi"
```

while the values file for the yyproject contains:

```yaml
projects:
  yy-project:
    metaData:
      requester: test-requester
    limitRanges:
      enabled: false
      limits:
        - type: "Container"
          max:
            cpu: "4"
            memory: "4Gi"
          min:
            cpu: "10m"
            memory: "10Mi"
          defaultRequest:
            cpu: "10m"
            memory: "10Mi"
```
In this case **no** `LimitRange` object will be rendered.



### Testing the Helm chart and values files
Although the deployment of the project setup is done via the ArgoCD application it often makes sense to test and verify the project setup before commiting the changes to the SCM repository.    
To render the templates for the _crc_ cluster with two projects perform the following steps:
```shell
cd setup-project
##
## Template the chart and save the output to /dev/shm/test.yaml
helm template . --debug -f values/crc/default-values.yaml -f values/crc/xx-project-values.yaml -f values/crc/my-test-project-values.yaml | tee /dev/shm/test.yaml
##
## Inspect and evaluate the result
less /dev/shm/test.yaml
``` 
