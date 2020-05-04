load '/opt/bats-support/load.bash'
load '/opt/bats-assert/load.bash'

@test "kubernetes master has correct version" {
  run /bin/bash -c "kubectl version --server"
  assert_output --partial "Server Version: v1.16.8"
  assert_equal "$status" 0
}
@test "kubernetes nodes have correct version" {
  run /bin/bash -c "kubectl version --client"
  assert_output --partial "Client Version: v1.16.8"
  assert_equal "$status" 0
}
# https://kubernetes.io/docs/reference/kubectl/cheatsheet/
@test "2 kubernetes nodes have status: Ready" {
  run /bin/bash -c "JSONPATH='{range .items[*]}{@.metadata.name}:{range @.status.conditions[*]}{@.type}={@.status};{end}{end}' \
 && kubectl get nodes -o jsonpath="$JSONPATH" | grep 'Ready=True' | wc -l"
  assert_output "2"
  assert_equal "$status" 0
}
@test "a test service (test website) can be deployed on kubernetes" {
  run /bin/bash -c "chmod +x ./deploy-test-service.sh && ./deploy-test-service.sh"
  assert_output --partial "Success"
  assert_equal "$status" 0
}
@test "a test service is available (ingress resource works)" {
  run /bin/bash -c "/usr/bin/test-timeout-until.sh \"curl --max-time 2 http://localhost:80/ -H 'Host: my-test-website.com' | grep 'Welcome to my Master Thesis website'\" \"120\" \"curl --max-time 2 http://localhost:80/ -H 'Host: my-test-website.com' | grep 'Welcome to my Master Thesis website'\""
  assert_equal "$status" 0
}
@test "a test service (test website) can be deleted from kubernetes" {
  run /bin/bash -c "helm uninstall apache-testing && kubectl apply -f config-map-www-contesnts.yaml && kubectl delete namespace testing"
  assert_output --partial "Success"
  assert_equal "$status" 0
}
