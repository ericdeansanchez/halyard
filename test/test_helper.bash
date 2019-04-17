#!/usr/bin/env bats

setup() {
  export HALYARD_PATH="${HOME}/.halyard"
  export CONTAINER_PATH="${HALYARD_PATH}/container"
}

teardown() {
  rm "${CONTAINER_PATH}/test.cpp" || true
  rm "${CONTAINER_PATH}/test.hpp" || true
}