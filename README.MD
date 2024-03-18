# textual-helm
Helm chart repository for deployment of Solar.

## Usage

[Helm](https://helm.sh) must be installed to use the charts.  Please refer to
Helm's [documentation](https://helm.sh/docs) to get started. The chart is published as an OCI package. It is recommended that you use a [Helm version >= 3.8.0](https://github.com/helm/helm/releases/tag/v3.8.0) which added full support for OCI registries.

To install the textual chart:

    helm install -n <your-namespace>  textual oci://quay.io/tonicai/textual -f values.yaml

To uninstall the chart:

    helm uninstall textual
