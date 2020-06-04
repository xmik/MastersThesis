@test "kubernetes machines have correct version" {
  run /bin/bash -c "kubectl version | grep 'Server Version'"
  # this is printed on test failure only
  echo "# test cmd output: $output"
  [[ "${output}" =~ "v1.16" ]]
  [ "$status" -eq 0 ]
}

@test "1 kubernetes worker nodes have status: Ready" {
  run /bin/bash -c "chmod +x get-workers-count.sh && ./get-workers-count.sh"
  # this is printed on test failure only
  echo "# test cmd output: $output"
  [[ "${output}" =~ "1" ]]
  [ "$status" -eq 0 ]
}

@test "kubectl cluster-info returns expected output" {
  run /bin/bash -c "kubectl cluster-info"
  # this is printed on test failure only
  echo "# test cmd output: $output"
  [[ "${output}" =~ "Kubernetes master" ]]
  [[ "${output}" =~ "https://api-testing-k8s-kops-for" ]]
  [ "$status" -eq 0 ]
}

@test "a test application can be deployed on kubernetes" {
  run /bin/bash -c "chmod +x ./deploy-test-service.sh && ./deploy-test-service.sh"
  # this is printed on test failure only
  echo "# test cmd output: $output"
  [[ "${output}" =~ "Success" ]]
  [ "$status" -eq 0 ]

  # k8s resource: pod was created
  run /bin/bash -c "kubectl get --namespace=testing pods"
  # this is printed on test failure only
  echo "# test cmd output: $output"
  [[ "${output}" =~ "apache-testing" ]]
  [[ "${output}" =~ "Running" ]]
  [ "$status" -eq 0 ]

  # k8s resource: svc was created
  run /bin/bash -c "kubectl get --namespace=testing svc"
  # this is printed on test failure only
  echo "# test cmd output: $output"
  [[ "${output}" =~ "apache-testing" ]]
  [ "$status" -eq 0 ]

  # k8s resource: ing was created
  run /bin/bash -c "kubectl get --namespace=testing ing"
  # this is printed on test failure only
  echo "# test cmd output: $output"
  [[ "${output}" =~ "apache-testing" ]]
  [ "$status" -eq 0 ]
}

@test "a test application is available (ingress resource works)" {
  # the LoadBalancer on AWS does not work right away, so here
  # we try it many times, until it works (max 400 trials)
  run /bin/bash -c "export SERVICE_IP=$(kubectl get svc --namespace testing apache-testing --template '{{ range (index .status.loadBalancer.ingress 0) }}{{.}}{{ end }}') && chmod +x test-timeout-until.sh && ./test-timeout-until.sh \"curl --max-time 2 -L http://\$SERVICE_IP 2>/dev/null | grep 'Welcome to my Master Thesis website'\" \"400\" \"curl --max-time 2 -L http://\$SERVICE_IP 2>/dev/null | grep 'Welcome to my Master Thesis website'\""
  # this is printed on test failure only
  echo "# test cmd output: $output"
  [[ "${output}" =~ "Welcome to my Master Thesis website" ]]
  [ "$status" -eq 0 ]
}

@test "a test service (test website) can be deleted from kubernetes" {
  run /bin/bash -c 'helm uninstall --namespace="testing" "apache-testing" && kubectl delete -f config-map-www-contents.yaml && kubectl delete namespace "testing"'
  echo "# test cmd output: $output"
  [[ "${output}" =~ "uninstalled" ]]
  [ "$status" -eq 0 ]

  # pod, svc and ing resources were deleted
  run /bin/bash -c 'kubectl get --namespace=testing pods,svc,ing'
  echo "# test cmd output: $output"
  [[ "${output}" =~ "No resources found in testing namespace" ]]
  [ "$status" -eq 0 ]
}
