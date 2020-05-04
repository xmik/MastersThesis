#!/bin/bash
set -e

custom_namespace="testing"
chart_release_name=apache-"${custom_namespace}"

function cleanup() {
  helm uninstall "${chart_release_name}" || echo "Cannot uninstall chart: ${chart_release_name}"
  kubectl delete namespace "${custom_namespace}" || echo "Cannot delete namespace: ${custom_namespace}"
  exit 1
}

# ensure k8s namespace exists
if [[ kubectl get namespace | grep "${custom_namespace}" ]]; then
  echo "Error: namespace: ${custom_namespace} already exists"
  cleanup
  exit 1
fi
kubectl create namespace "${custom_namespace}"

# deploy the apache chart
if [[ helm list | grep "${chart_release_name}" ]]; then
  echo "Error: chart release: ${chart_release_name} is already deployed"
  cleanup
  exit 1
fi
kubectl apply -f config-map-www-contesnts.yaml
helm repo add bitnami https://charts.bitnami.com/bitnami
helm install "${chart_release_name}" -f apache-chart-config.yaml bitnami/apache

echo "Success"
