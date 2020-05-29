#!/bin/bash
set -e

# TODO descr

custom_namespace="testing"
chart_release_name=apache-"${custom_namespace}"

function cleanup() {
  echo "Cleaning..."
  helm uninstall --namespace="${custom_namespace}" "${chart_release_name}" || echo "Cannot uninstall chart: ${chart_release_name}"
  kubectl delete -f config-map-www-contents.yaml
  kubectl delete namespace "${custom_namespace}" || echo "Cannot delete namespace: ${custom_namespace}"
  echo "Cleaning finished"
  exit 1
}

# ensure k8s namespace exists
if kubectl get namespace | grep "${custom_namespace}"; then
  echo "Error: namespace: ${custom_namespace} already exists"
  cleanup
  exit 1
fi
kubectl create namespace "${custom_namespace}"

# deploy the apache chart
if helm list --all-namespaces | grep "${chart_release_name}"; then
  echo "Error: chart release: ${chart_release_name} is already deployed"
  cleanup
  exit 1
fi
set -x
kubectl apply -f config-map-www-contents.yaml
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install "${chart_release_name}" -f apache-chart-config.yaml --namespace="${custom_namespace}" --wait --atomic bitnami/apache
# without the following line, we cannot curl the service. The exact error is:
# $ curl -L http://acf690c83d7924db2bed5cdb587525c9-529110400.eu-west-1.elb.amazonaws.com
# curl: (6) Could not resolve host: acf690c83d7924db2bed5cdb587525c9-529110400.eu-west-1.elb.amazonaws.com
helm upgrade "${chart_release_name}" -f apache-chart-config.yaml --namespace="${custom_namespace}" --wait --atomic bitnami/apache
set -x

echo "Success"
