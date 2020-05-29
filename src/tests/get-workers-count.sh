#!/bin/bash

# Returns a number of Kubernetes worker nodes with status: Ready
# https://kubernetes.io/docs/reference/kubectl/cheatsheet/

JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}'
kubectl get nodes -o jsonpath="$JSONPATH" | grep 'Ready=True' | wc -l
