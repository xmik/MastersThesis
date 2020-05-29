# This script tries each second to run wait_cmd. If this command
# succeeds in less than timeout seconds, then test_cmd is run.
#
# Intentionally do not start this with: #!/bin/bash, because we may use
# cosmintitei/bash-curl:latest docker image which does not have: /bin/bash, but
# it has: /usr/local/bin/bash.
#
# This is obviously a temporary solution, initially written for ai_go cookbook.
# We use it, because it is easier to maintain than long bash one-liners and
# because it produces helpful stdout (which you can see in Graylog on a k8s dashboard).
# We need a better test framework to run commands like:
# `curl --silent http://10.1.1.73 -H 'Host: nginx-testing.ai-traders.com'`
# and we need a docker image with this framework installed.
# Will be solved by: https://aitraders.tpondemand.com/entity/11145

# wait_cmd command must succeed first
wait_cmd=$1
timeout=$2
# after wait_cmd succeeds, test_cmd will be invoked
test_cmd=$3

if [[ -z "${wait_cmd}" ]]; then
  echo "wait_cmd not set, exit 1"
  exit 1
fi
if [[ -z "${test_cmd}" ]]; then
  echo "test_cmd not set, exit 1"
  exit 1
fi
if [[ -z "${timeout}" ]]; then
  echo "timeout not set, exit 1"
  exit 1
fi

echo "K8S_EXP tests: wait_cmd: ${wait_cmd}"
echo "K8S_EXP tests: timeout: ${timeout}"
echo "K8S_EXP tests: test_cmd: ${test_cmd}"

i=0
while [ "$i" -le "$timeout" ]; do
  echo "K8S_EXP tests: trial ${i}"
  # do not use /bin/bash here, see comments above
  bash -c "${wait_cmd} >/dev/null"
  if [[ $? == 0 ]]; then
    echo "K8S_EXP tests: wait_cmd suceeded, running test_cmd"
    # do not use /bin/bash here, see comments above
    bash -c "${test_cmd} >/dev/null"
    if [[ $? == 0 ]]; then
      echo "K8S_EXP tests: test_cmd suceeded"
      exit 0;
    fi
    echo "K8S_EXP tests: test_cmd failed"
    exit 1;
  else
    if [[ "${i}" == ${timeout} ]]; then
      echo "K8S_EXP tests: That was last trial, return 1"
      exit 1
    fi
    sleep 1
  fi
  i=$((i + 1))
done
