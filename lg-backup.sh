#!/bin/bash

SUBFOLDER_NAME="Less"
COUNTER_FILE='.counter'
FILE_MASK="*.zip"
FILES_ON_LEVEL=4

function printHelp() {
  echo "Script recursively processes files in specified directories based on a given file mask."
  echo "It moves or deletes files according to a counter and organizes them into subfolders."
  echo "Usage: $0 [options] <folder1> <folder2> ..."
  echo "Options:"
  echo "  -s, --subfolder-name   Name of the subfolder to move files into (default: Less)"
  echo "  -c, --counter-file     File to store the counter (default: .counter)"
  echo "  -m, --file-mask        File mask to match files (default: *.zip)"
  echo "  -l, --files-on-level   Number of files to process on each level (default: 4)"
  echo "  -h, --help             Display this help message"
}

function scanDir() {
  local filename
  local -a files=()
  local counter
  local num_files
  local file

  # Read or initialize the counter
  if [ -f "$COUNTER_FILE" ]; then
    counter=$(<"$COUNTER_FILE")
  else
    counter=0
  fi

  while IFS= read -r -e filename; do
    echo "$filename"
    files+=("$filename")
  done < <(find . -maxdepth 1 -path "$FILE_MASK" -type f -print0 | xargs -0 stat --format='%y %n' | sort -n | cut -d' ' -f4-)

  # Process files
  num_files=${#files[@]}
  for file in "${files[@]}"; do
    if [ "$num_files" -gt "$FILES_ON_LEVEL" ]; then
      if [ "$counter" -eq 0 ]; then
        mkdir -p "$SUBFOLDER_NAME"
        mv "$file" "$SUBFOLDER_NAME"
      else
        rm -f "$file"
      fi
      ((counter++))
      counter=$((counter % FILES_ON_LEVEL))
      ((num_files--))
    else
      break
    fi
  done

  # Save the counter
  echo "$counter" >"$COUNTER_FILE"

  # Recursively process the subfolder if it exists
  if [ -d "$SUBFOLDER_NAME" ]; then
    cd "$SUBFOLDER_NAME" && scanDir
  fi
}

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
  -s | --subfolder-name)
    SUBFOLDER_NAME="$2"
    shift
    shift
    ;;
  -c | --counter-file)
    COUNTER_FILE="$2"
    shift
    shift
    ;;
  -m | --file-mask)
    FILE_MASK="$2"
    shift
    shift
    ;;
  -l | --files-on-level)
    FILES_ON_LEVEL="$2"
    shift
    shift
    ;;
  -h | --help)
    printHelp
    exit 0
    ;;
  -*)
    >&2 echo "Unknown option $1"
    exit 1
    ;;
  *)
    POSITIONAL_ARGS+=("$1")
    shift
    ;;
  esac
done

re='^[0-9]+$'
if ! [[ $FILES_ON_LEVEL =~ $re ]]; then
  >&2 echo "Files on each level not a number"
  exit 1
fi

set -- "${POSITIONAL_ARGS[@]}"

if [ ${#POSITIONAL_ARGS[@]} -eq 0 ]; then
  POSITIONAL_ARGS+=(".")
fi

CURRENT_FOLDER=$(pwd)
for folder in "${POSITIONAL_ARGS[@]}"; do
  if cd "$folder"; then
    scanDir
  else
    >&2 echo "Can't go to directory $folder"
    exit 1
  fi
  cd "$CURRENT_FOLDER" || exit 1
done
