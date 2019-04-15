#!/bin/bash

# Will conform to Google style guide
# https://google.github.io/styleguide/shell.xml

readonly HALYARD_PATH="$HOME/.halyard"
readonly CONTAINER_PATH="$HALYARD_PATH/container"

copy_files() {
  # Optional flag
  local opt=$1
  local files="${@:2}"

  for file in $files; do
    echo "Loading ${file##*/}"
    cp $opt $file $CONTAINER_PATH
  done
}

load() {
  cat $HALYARD_PATH/images/logo

  # Initially we are looking at all args
  local target=("$@")
  local dir_change
  local arg
  local opt

  if [ $1 = "-y" ]; then
    arg=$2
    # If --yes option is provided, target begins at 2nd arg
    unset target[0]
  else
    arg=$1
    opt=-i
  fi

  if [ -d $arg ]; then
    echo "Preparing contents of ${PWD##*/}..."
    # Since provided target is a dir, switch target to its contents
    unset target
    pushd "$arg" > /dev/null 2>&1
    target="$(ls .)"
  fi

  copy_files "${opt}" "${target[@]}"
  popd > /dev/null 2>&1
}

run() {
  # Ensure Docker Desktop is up
  open --background -a Docker &&
    if ! docker system info > /dev/null 2>&1; then
      echo "Staring Docker..." &&
        while ! docker system info > /dev/null 2>&1; do
          sleep 1
        done
    fi

  local target=() # Container for source files
  local extension
  local compiler

  for file in "$CONTAINER_PATH"/*; do
    extension="${file##*.}"
    # Set compiler based on source extension
    if [ $extension = "c" ] || [ $extension = "cpp" ] || [ $extension = "cc" ]; then
      case $extension in
        "c") compiler="gcc" ;;
        "cpp" | "cc") compiler="g++" ;;
      esac
      target+=("${file##*/}")
    fi
  done

  pushd $CONTAINER_PATH > /dev/null 2>&1

  # This is where the magic happens
  docker run --rm -ti -v $PWD:/test halyard:0.1 bash -c \
    "cd /test/; $compiler -o memcheck ${target[*]} && valgrind --leak-check=full ./memcheck"

  rm memcheck
  popd > /dev/null 2>&1
}

peek() {
  for file in "$CONTAINER_PATH"/*; do
    if [ ${file##*/} != "Dockerfile" ]; then
      echo "${file##*/}"
    fi
  done
}

unload() {
  for file in "$CONTAINER_PATH"/*; do
    if [ ${file##*/} != "Dockerfile" ]; then
      echo "Unloading ${file##*/}"
      rm $file
    fi
  done
}

case "$1" in
  "load") load "${@:2}" ;;
  "run") run "${@:2}" ;;
  "peek") peek ;;
  "unload") unload ;;
esac