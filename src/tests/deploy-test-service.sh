#!/bin/bash
set -e

# TODO descr

custom_namespace="testing"
chart_release_name=apache-"${custom_namespace}"

# ensure k8s namespace exists
if kubectl get namespace | grep "${custom_namespace}" >/dev/null; then
  echo "namespace: ${custom_namespace} already exists"
else
  kubectl create namespace "${custom_namespace}"
fi

# deploy the apache chart
if helm list --all-namespaces | grep "${chart_release_name}" >/dev/null; then
  echo "chart release: ${chart_release_name} is already deployed"
else
  set -x
  kubectl apply -f config-map-www-contents.yaml
  helm repo add bitnami https://charts.bitnami.com/bitnami
  set +e
  # this command may exit with error, e.g.
  # Error: release apache-testing failed, and has been uninstalled due to atomic being set: services "apache-testing" not found;
  # also, do not use --atomic deliberately, if the service is missing, it will be installed later
  # with helm upgrade
  helm install "${chart_release_name}" -f apache-chart-config.yaml --namespace="${custom_namespace}" --wait bitnami/apache
  # without the service installed, we cannot curl the service. The exact error is:
  # $ curl -L http://acf690c83d7924db2bed5cdb587525c9-529110400.eu-west-1.elb.amazonaws.com
  # curl: (6) Could not resolve host: acf690c83d7924db2bed5cdb587525c9-529110400.eu-west-1.elb.amazonaws.com
  set -e
fi

# sometimes k8s service resource is not created; so try again
if ! kubectl get -n "${custom_namespace}" svc | grep "${chart_release_name}" >/dev/null; then
  echo "service was not created, trying again"
  set -x
  helm upgrade "${chart_release_name}" -f apache-chart-config.yaml --namespace="${custom_namespace}" --wait --atomic bitnami/apache
  set +x
fi

echo "Success"
