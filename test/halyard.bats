#!/usr/bin/env bats

load test_helper

@test "display logo" {
  run cat "${HALYARD_PATH}"/images/logo
  [ "$status" -eq 0 ]
}

@test "load called with directory: no requested overwrite permission" {
  run halyard -y load testfiles
  [ "$status" -eq 0 ]
  rm "${CONTAINER_PATH}"/test.cpp
  rm "${CONTAINER_PATH}"/test.hpp
}

@test "load called with directory: requested overwrite permission" {
  run halyard load testfiles
  yes | run halyard load testfiles
  [ "$status" -eq 0 ]
  rm "${CONTAINER_PATH}"/test.cpp
  rm "${CONTAINER_PATH}"/test.hpp
}

@test "load called with single file: no requested overwrite permission" {
  run halyard -y load testfiles/test.cpp
  [ "$status" -eq 0 ]
  rm "${CONTAINER_PATH}"/test.cpp
}

@test "load called with single file: requested overwrite permission" {
  run halyard load testfiles/test.cpp
  yes | run halyard load testfiles/test.cpp
  [ "$status" -eq 0 ]
  rm "${CONTAINER_PATH}"/test.cpp
}

@test "load called with multiple files: no requested overwrite permission" {
  run halyard -y load testfiles/test.cpp testfiles/test.hpp
  [ "$status" -eq 0 ]
  rm "${CONTAINER_PATH}"/test.cpp
  rm "${CONTAINER_PATH}"/test.hpp
}

@test "load called with multiple files: requested overwrite permission" {
  run halyard load testfiles/test.cpp testfiles/test.hpp
  yes | run halyard load testfiles/test.cpp testfiles/test.hpp
  [ "$status" -eq 0 ]
  rm "${CONTAINER_PATH}"/test.cpp
  rm "${CONTAINER_PATH}"/test.hpp
}

@test "load called without args: usage displayed and exit status 1" {
  run halyard load
  [ "$status" -eq 1 ]
  [ $(expr "${lines[0]}" : "usage:") -ne 0 ]
}

@test "halyard executed without args: usage displayed and exit status 1" {
  run halyard
  [ "$status" -eq 1 ]
  [ $(expr "${lines[0]}" : "usage:") -ne 0 ]
}


