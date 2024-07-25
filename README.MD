# Tonic Textual Helm Chart
This repository contains a Helm chart which can be used to install Tonic via ` helm install `.

Project structure:
```
.
├── templates
      └── <All template files>
├── values.yaml
└── README.md
```

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started. The chart is published as an OCI package. It is recommended that you use a [Helm version >= 3.8.0](https://github.com/helm/helm/releases/tag/v3.8.0) which added full support for OCI registries.

To install the textual chart:

    helm install -n <your-namespace> textual oci://quay.io/tonicai/textual -f values.yaml

To uninstall the chart:

    helm uninstall textual

Alternatively, if you have the templates downloaded into your machine, you may also use the following from within the Textual directory:

    helm install -n <your-namespace> textual -f values.yaml .



## Configuration

### values.yaml

Before deploying this setup, configure the following values.

### Environment Name

* ENVIRONMENT_NAME: E.g. "my-company-name", or if deploying multiple Tonic instances, "my-company-name-dev" or "my-company-name-prod to differentiate instances.

### Version

* textualVersion: A specific version tag. Tonic's tag convention is just the release number, e.g. "086". The latest version during installation will be supplied by Tonic.

### Textual Database

The connection details for the Postgres metadata/application database which holds Tonic's state (user accounts, workspaces, etc.).
* host
* port
* dbName
* user
* password


### Secret

This value is used as the secret for encryption
* textualEncryptionSecret: Any string value is valid


### Authorization to access Tonic application Docker images

Tonic hosts our application images on a private quay.io repository. Authorization is required to pull the images.
* dockerConfigAuth: This value will be provided to you by Tonic and will allow you to authenticate against our private docker image repository.


### Consistency

This value is used to maintain consistency of values across redactions
* solarStatisticsSeed: Any integer value


### Number of workers to deploy
* ` numberOfWorkers ` : An integer. Increase to more than 1 to deploy additional workers. Each worker can run a single redaction at a time. Multiple workers are needed to run jobs simultaneously. This sets the number of replicas in the Tonic Worker Deployment spec.


### Ingress
The Helm charts include default annotations for internal-facing load balancers for AWS, Azure, and GCP. You can change to your preferred ingress method by modifying solar-api-server-service.yaml as well as updating the annotations section included in values.yaml


### Resource requests and limits
Each of the deployment YAML template files contains resource requests and limits. In some cases these may need to be modified for your environment.


## Deploy

To install Tonic Textual, execute the following commands.

Create a namespace:

``` $ kubectl create namespace my-tonic-namespace ```

Deploy Tonic Textual:

``` $ helm install <name_of_release> -n <namespace_name> <path-to-helm-chart> ```


### Validate the deployment

Use kubectl get all -n <namespace_name> to check that the Textual pods are running:

The deployment may take a few minutes with pods in the ContainerCreating status. Re-run the command to get an updated status. Once all pods have a status of Running and deployments show READY as 1/1, Tonic should be available shortly after via browser at the URL/IP listed in the EXTERNAL-IP field next to the load balancer service. If you have modified the Helm chart ingress configuration, then this will vary. While not required, it's recommended to set up a more user-friendly domain routing to the Tonic web application.


You can validate that Tonic has fully started up and is in a healthy state by running ` kubectl logs deployment/textual-api-server -n <namespace_name> ` and check for output that reads ` "Now listening on: ...." `
