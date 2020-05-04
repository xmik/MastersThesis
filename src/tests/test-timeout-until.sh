# This script tries each second to run command_to_succeed. If this command
# succeeds in less than timeout seconds, then command_actual is run.
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

command_to_succeed=$1
timeout=$2
command_actual=$3

echo "Running AIT tests"

if [[ -z "${command_to_succeed}" ]]; then
  echo "command_to_succeed not set, exit 1"
  exit 1
fi
if [[ -z "${command_actual}" ]]; then
  echo "command_actual not set, exit 1"
  exit 1
fi
if [[ -z "${timeout}" ]]; then
  echo "timeout not set, exit 1"
  exit 1
fi

echo "Ewa tests: command_to_succeed: ${command_to_succeed}"
echo "Ewa tests: timeout: ${timeout}"
echo "Ewa tests: command_actual: ${command_actual}"

i=0
while [ "$i" -le "$timeout" ]; do
  echo "Ewa tests: trial ${i}"
  # do not use /bin/bash here, see comments above
  bash -c "${command_to_succeed}"
  if [[ $? == 0 ]]; then
    echo "Ewa tests: command_to_succeed suceeded, running command_actual"
    # do not use /bin/bash here, see comments above
    bash -c "${command_actual}"
    if [[ $? == 0 ]]; then
      echo "Ewa tests: command_actual suceeded"
      exit 0;
    fi
    echo "Ewa tests: command_actual failed"
    exit 1;
  else
    if [[ "${i}" == ${timeout} ]]; then
      echo "Ewa tests: That was last trial, return 1"
      exit 1
    fi
    sleep 1
  fi
  i=$((i + 1))
done
