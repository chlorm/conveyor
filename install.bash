#!/usr/bin/env bash
# Copyright (c) 2017, Cody Opel <codyopel@gmail.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit
set -o errtrace
set -o functrace
set -o nounset
set -o pipefail

XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
if [ "$XDG_DATA_HOME" != "$HOME/.local/share" ]; then
  echo "non standard XDG_DATA_HOME, you must explicitly set PREFIX" >&2
  echo "run: PREFIX=\"<install prefix>\" install.sh"
  exit 1
fi
XDG_PREFIX="$(dirname "$XDG_DATA_HOME")"
PREFIX="${PREFIX:-$XDG_PREFIX}"
DIR="$(readlink -f "$(readlink -f "$(dirname "$(readlink -f "$0")")")")"

BASH_BIN="$(type -P bash)"

declare -a REQUIRED_UTILS=(
  7z
  awk
  curl
  cut
  dirname
  find
  flexget
  grep
  guessit
  iconv
  install
  ln
  mkdir
  mktemp
  rclone
  readlink
  rm
  sed
  sleep
  sort
  tee
  touch
  tr
  uniq
)

declare -a CONVEYOR_PATHS=()
for requiredutil in "${REQUIRED_UTILS[@]}"; do
  if ! type $requiredutil >/dev/null; then
    echo "$requiredutil not found" >&2
    exit 1
  fi
  CONVEYOR_PATHS+=("$(dirname "$(type -P "$requiredutil")")")
done

# Filter out duplicate prefixes
mapfile -t CONVERYOR_PATHS_FILTERED < <(
  printf '%s\n' "${CONVEYOR_PATHS[@]}" | sort -u
)

unset CONVEYOR_PATH
for Path in "${CONVERYOR_PATHS_FILTERED[@]}"; do
  CONVEYOR_PATH+="${CONVEYOR_PATH:+:}$Path"
done

for bin in "$DIR"/src/bin/*; do
  install -D -m755 -v "$bin" "$PREFIX/bin/$(basename "$bin")"
  sed -i "$PREFIX/bin/$(basename "$bin")" \
    -e "s,^#!bash,#!$BASH_BIN," \
    -e "s,#PATH#,PATH=\"$CONVEYOR_PATH\","
done

for data in "$DIR"/src/share/conveyor/*; do
  install -D -m644 -v "$data" "$PREFIX/share/conveyor/$(basename "$data")"
done
