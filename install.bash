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

CONVEYOR_PATHS=(
  "$(dirname "$(type -P 7z 2>&-)")"
  "$(dirname "$(type -P awk 2>&-)")"
  "$(dirname "$(type -P curl 2>&-)")"
  "$(dirname "$(type -P cut 2>&-)")"
  "$(dirname "$(type -P dirname 2>&-)")"
  "$(dirname "$(type -P find 2>&-)")"
  "$(dirname "$(type -P flexget 2>&-)")"
  "$(dirname "$(type -P grep 2>&-)")"
  "$(dirname "$(type -P guessit 2>&-)")"
  "$(dirname "$(type -P iconv 2>&-)")"
  "$(dirname "$(type -P ln 2>&-)")"
  "$(dirname "$(type -P mkdir 2>&-)")"
  "$(dirname "$(type -P mktemp 2>&-)")"
  "$(dirname "$(type -P rclone 2>&-)")"
  "$(dirname "$(type -P readlink 2>&-)")"
  "$(dirname "$(type -P rm 2>&-)")"
  "$(dirname "$(type -P sed 2>&-)")"
  "$(dirname "$(type -P sleep 2>&-)")"
  "$(dirname "$(type -P sort 2>&-)")"
  "$(dirname "$(type -P tee 2>&-)")"
  "$(dirname "$(type -P touch 2>&-)")"
  "$(dirname "$(type -P tr 2>&-)")"
  "$(dirname "$(type -P uniq 2>&-)")"
  "$(dirname "$(type -P unrar 2>&-)")"
  "$(dirname "$(type -P unzip 2>&-)")"
)

unset CONVEYOR_PATH
for Path in "${CONVEYOR_PATHS[@]}"; do
  CONVEYOR_PATH+="${CONVEYOR_PATH:+:}$Path"
done

for bin in "$DIR"/src/bin/*; do
  install -D -m755 -v "$bin" "$PREFIX/bin/$(basename "$bin")"
  sed -i "$PREFIX/bin/$(basename "$bin")" \
    -e "s,^#!bash,#!$BASH_BIN,"
done

for data in "$DIR"/src/share/conveyor/*; do
  install -D -m644 -v "$data" "$PREFIX/share/conveyor/$(basename "$data")"
  sed -i "$PREFIX/share/conveyor/$(basename "$data")" \
    -e "s,#PATH#,PATH=\"$CONVEYOR_PATH\","
done
