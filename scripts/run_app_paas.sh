#!/bin/bash

set -e -o pipefail

TERMINATE_TIMEOUT=10

function check_params {
  if [ -z "${NOTIFY_APP_NAME}" ]; then
    echo "You must set NOTIFY_APP_NAME"
    exit 1
  fi

  if [ -z "${CW_APP_NAME}" ]; then
    CW_APP_NAME=${NOTIFY_APP_NAME}
  fi
}

function configure_aws_logs {
  aws configure set plugins.cwlogs cwlogs

  mkdir -p /app/awslogs
  mkdir -p /app/logs
  touch /app/logs/app.log
  cat > /app/awslogs/awslogs.conf << EOF
[general]
state_file = /app/awslogs/awslogs-state

[/app/logs/app.log]
file = /app/logs/app.log*
log_group_name = paas-${CW_APP_NAME}-application
log_stream_name = {hostname}
EOF
}

function on_exit {
  echo "Terminating application process with pid ${APP_PID}"
  kill ${APP_PID} || true
  n=0
  while (kill -0 ${APP_PID} 2&>/dev/null); do
    echo "Application is still running.."
    sleep 1
    let n=n+1
    if [ "$n" -ge "$TERMINATE_TIMEOUT" ]; then
      echo "Timeout reached, killing process with pid ${APP_PID}"
      kill -9 ${APP_PID} || true
      break
    fi
  done
  echo "Application process terminated, waiting 10 seconds"
  sleep 10
  echo "Terminating remaining subprocesses.."
  kill 0
}

function start_application {
  freshclam -d
  clamd
  sleep 15
  exec "$@" &
  APP_PID=`jobs -p`
  echo "Application process pid: ${APP_PID}"
}

function start_aws_logs_agent {
  exec aws logs push --region eu-west-1 --config-file /app/awslogs/awslogs.conf &
  AWSLOGS_AGENT_PID=$!
  echo "AWS logs agent pid: ${AWSLOGS_AGENT_PID}"
}

function run {
  while true; do
    kill -0 ${APP_PID} 2&>/dev/null || break
    kill -0 ${AWSLOGS_AGENT_PID} 2&>/dev/null || start_aws_logs_agent
    sleep 1
  done
}

echo "Run script pid: $$"

check_params

trap "on_exit" EXIT

configure_aws_logs

# The application has to start first!
start_application "$@"

start_aws_logs_agent

run
