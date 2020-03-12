#!/usr/bin/env bash
# Script emulates GitHub Action execution in local env.
# Used for the testing cluster creation and performs basic tests

# Import variables
. config.sh

readonly SRC_PATH=$(realpath $(dirname $(readlink -f $0))/../)
cd ${SRC_PATH}
source ${SRC_PATH}/bin/bash-logger.sh

readonly GIT_SHORT_COMMIT=$(git rev-parse --short HEAD)
readonly DOCKER_IMAGE_NAME="cluster.dev:${GIT_SHORT_COMMIT}-local-tests"

docker build -t ${DOCKER_IMAGE_NAME} .

# Get from config.sh
readonly USER="${AWS_ACCESS_KEY_ID}"
readonly PASS="${AWS_SECRET_ACCESS_KEY}"
readonly WORKFLOW_PATH="${GH_ACTION_WORKFLOW_PATH}"
readonly TIMEOUT="${ACTION_TIMEOUT}"

# Trap ctrl+c to remove docker container and kill timeout script.
trap ctrl_c INT
function ctrl_c() {
    docker rm -f clusterdev-test-${GIT_SHORT_COMMIT}
    kill ${timer_pid}
}

# Script waits for $1 seconds and than remove $2 containet.
${SRC_PATH}/tests/timeout.sh ${TIMEOUT} clusterdev-test-${GIT_SHORT_COMMIT} &
timer_pid=$!

# Run docker in localhost
docker run -d --name clusterdev-test-${GIT_SHORT_COMMIT} --workdir /github/workspace --rm -v "${SRC_PATH}":"/github/workspace" \
           -e GITHUB_REPOSITORY="shalb" \
           ${DOCKER_IMAGE_NAME} "${WORKFLOW_PATH}" "${USER}" "${PASS}"

sleep 1

# Show pipeline containet output.
docker logs -f clusterdev-test-${GIT_SHORT_COMMIT}


