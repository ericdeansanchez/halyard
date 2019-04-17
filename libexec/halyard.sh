#!/bin/bash

# Path to the yard.
readonly YARD_DIR_PATH="$PWD/yard/"

# The yard directory stores Valgrind output.
readonly YARD_OUT_PATH="$YARD_DIR_PATH/yard.txt"

# Path to the toplevel halyard directory.
readonly HALYARD_PATH="$HOME/.halyard"

# Path to the toplevel halyard container.
readonly CONTAINER_PATH="$HALYARD_PATH/container"

readonly HALYARD_SAYS="\t\x1b[33mhalyard: \x1b[0m"
readonly HALYARD_SAYS_NO="\t\x1b[01;31mhalyard: \x1b[0m"

# Initialize a `yard` directory within the current
# working directory to store Valgrind output to be
# parsed.
# TODO: Ensure users can't init anywhere besides
# their current workspace.
init() {
  if [[ ! -e $YARD_DIR_PATH ]]; then
    mkdir $YARD_DIR_PATH
    printf "\x1b[33m Initialized empty yard in \x1b[0m ${PWD}\n"
  else
    printf "\x1b[33m ${YARD_DIR_PATH} \x1b[0m already exists!\n"
  fi
}

# Container status: [LOADED or UNLOADED]
#STATUS="UNLOADED"

# Utility function that formats and display contents of
# an array of collected files (file names).
display() {
  local divider=====================================
  local divider=$divider$divideri$divider$divider

  local header="\n%-15s %-25s %12s %10s\n"
  local format=""

  if [[ "$STATUS" == "LOADED" ]]; then
    format="\x1b[22;33m%-15s\x1b[0m %-25s \x1b[33m%12s\x1b[0m %10d\n"
  else
    format="%-15s %-25s \x1b[33m%12s\x1b[0m %10d\n"
  fi

  printf "${header}" "STATUS" "FILE_NAME" "FILE_EXTENSION" "FILE_SIZE"
  width=67

  printf "%$width.${width}s\n" "$divider"
  for file_name in "${file_array[@]}"; do
    EXTENSION=$([[ "$file_name" == *.* ]] && echo ".${file_name##*.}" || echo '')
    FILESIZE=$(stat -f '%z' "${file_name}")
    printf "$format" "[${STATUS}]" "${file_name}" "${EXTENSION} " "${FILESIZE}"
  done
  printf "\n"
}

# Load (via cp) the currenty directory's files into toplevel
# container.
load_container() {
  # Optional flag
  local opt="$1"
  local files="${@:2}"
  local file_array=()

  for file in $files; do
    if [[ ! -d "${file}" ]]; then
      cp ${opt} ${file} ${CONTAINER_PATH}
      file_array+=("${file##*/}")
    fi
  done

  display "${file_array[@]}"
}

# Loads this current directory's files into toplevel
# docker container.
load() {
  cat "${HALYARD_PATH}"/images/logo

  # Initially we are looking at all args
  local target=("$@")
  local dir_change
  local arg
  local opt

  if [ "$1" = "-y" ]; then
    arg="$2"
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
    pushd "$arg" >/dev/null 2>&1
    target="$(ls .)"
  fi

  STATUS="LOADED"
  # Copy this directory's files into container.
  load_container "${opt}" "${target[@]}"
  popd >/dev/null 2>&1
}

run() {
  # Ensure Docker Desktop is up
  open --background -a Docker &&
    if ! docker system info >/dev/null 2>&1; then
      echo "Staring Docker..." &&
        while ! docker system info >/dev/null 2>&1; do
          sleep 1
        done
    fi

  # Array for source files.
  local target=()
  local extension
  local compiler
  local file_count=0

  for file in "$CONTAINER_PATH"/*; do
    extension="${file##*.}"
    # Set compiler based on source extension
    if [ $extension = "c" ] || [ $extension = "cpp" ] || [ $extension = "cc" ]; then
      case $extension in
        "c") compiler="gcc" ;;
        "cpp" | "cc") compiler="g++" ;;
      esac
      target+=("${file##*/}")
      ((file_count = file_count + 1))
    fi
  done

  # No need to `run` on zero files.
  if [[ ! "$file_count" -gt 0 ]]; then
    printf "\n${HALYARD_SAYS_NO} \`run\` called on an empty vessel...\n"
    printf "${HALYARD_SAYS} try to \`load\` before the next \`run\`...\n\n"
    exit 1
  fi

  pushd $CONTAINER_PATH >/dev/null 2>&1

  # This is where the magic happens
  # TODO: Redirect output, parse, and display for user
  # Runs a full leak check and displays results
  docker run --rm -ti -v $PWD:/test halyard:0.1 bash -c \
    "cd /test/; $compiler -o memcheck ${target[*]} &&
                valgrind --leak-check=full ./memcheck"

  rm memcheck
  popd >/dev/null 2>&1
}

# Lists files that are currently loaded in container.
peek() {
  # The number of files in the vessel.
  local file_count=0

  # Array to hold the file names within the vessel.
  local file_array=()

  # Collect file names into `file_array` to be passed 
  # to display. Count the number of files on this pass 
  # to avoid a call to `display` if the vessel is empty.
  for file in "$CONTAINER_PATH"/*; do
    if [ ${file##*/} != "Dockerfile" ]; then
      file_array+=("${file##*/}")
      ((file_count = file_count + 1))
    fi
  done

  # HACK: [fix me] - there has to be a better solution
  STATUS="LOADED"
  # Only display from peek if the vessel is loaded.
  if [[ "$file_count" -gt 0 ]]; then
    display "${file_array[@]}"
  else
    printf "\n${HALYARD_SAYS_NO} \`peek\` called on an empty vessel...\n"
    printf "${HALYARD_SAYS} try to \`load\` the vessel before the next \`run\`...\n\n"
  fi
}

# Removes files that are currently loaded in container.
unload() {
  # The number of files in the vessel.
  local file_count=0

  # Array to hold the file names within the vessel.
  local file_array=()

  # Collect file names into `file_array` to be passed 
  # to display. Count the number of files on this pass 
  # to avoid a call to `display` if the vessel is empty.
  for file in "$CONTAINER_PATH"/*; do
    if [ ${file##*/} != "Dockerfile" ]; then
      file_array+=("${file##*/}")
      ((file_count = file_count + 1))
      rm "$file"
    fi
  done

  # Mark status as unloaded and display the files
  # we unloaded from the vessel.
  STATUS="UNLOADED"

  # Only `display` from `unload` if the vessel has been unloaded.
  if [[ "$file_count" -gt 0 ]]; then
    display "${file_array[@]}"
  else
    printf "\n${HALYARD_SAYS_NO} \`unload\` called on an empty vessel...\n"
    printf "${HALYARD_SAYS} vessel must be \`load[ed]\` before it can be \`unload[ed]\`...\n\n"
  fi
}

case "$1" in
  "init") init "${@:1}" ;;
  "load") load "${@:2}" ;;
  "run") run "${@:2}" ;;
  "peek") peek ;;
  "unload") unload ;;
esac
