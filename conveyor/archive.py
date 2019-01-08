# Copyright (c) 2017-2018, Cody Opel <codyopel@gmail.com>
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

#deluge-console -c /home35/jackal/.config/deluge/ "connect 5.79.67.48:21096 jackal DgVlV6HtNqW; info 30435a5872d07b226051516949bb04b1bfcfaf5a"

# FIXME: add to lib-bash
map() {
  if [ $# -le 1 ]; then
    return
  else
    local Command="$1"
    local Arg="$2"
    shift 2
    local -a Args=("$@")

    $Command "$Arg"

    map "$Command" "${Args[@]}"
  fi
}

import os

def archive_ext(f):
  # FIXME
  ext1 = os.path.splitext(f)[1].strip()
  ext2 = os.path.splitext(f)[2].strip()
  # Find correct RAR file extension
  if ext1 == 'r00':
    ext = 'r00'
  elif ext1 == 'rar':
    # FIXME: will break on filenames with periods
    if ext2 == 'part01.rar':
      ext = 'part01.rar'
    elif ext2 == 'subs.rar':
      ext = 'subs.rar'
    else:
      ext = 'rar'
  elif ext1 == 'zip':
    ext = 'zip'
  else:
    # FIXME
    echo "ERROR: unknown archive extension: ${File}"
    return 1

  return ext

def archive_type(f):
  ext = os.path.splitext(f).strip()

  if ext in ['r00','rar']:
    t = 'rar'
  elif ext == 'zip':
    t = 'zip'
  else:
    raise 'Unknown archive type'

  return t

def archive_unpack(archive, destination):
  
  ArchiveUtility="$(archive_utility "$Archive")"

  echo "unpacking: $Archive -> $Destination" >&2

  if [ ! -d "$Destination" ]; then
    mkdir -pv "$Destination"
  fi

  7za e -r -aoa "$Archive" -o"$Destination" || true
}

archive_scan() {
  local Archive
  local -a Archives
  local -r DirSource="$1"
  local -r DirTarget="$2"

  # XXX: fucking scene cunts nest rar archives, *.subs.rar contains
  #      *.idx and *.rar which has the sub file.
  find_archives() {
    local -r Dir2="$1"
    RCLONE_LS_EXTRA_ARGS='--include *.{rar,zip}' rc_ls "$Dir2"
  }

  set +o nounset
  while true; do
    Archives=()
    mapfile -t Archives < <(find_archives "$DirSource")
    if [ -n "${Archives[*]}" ]; then
      for Archive in "${Archives[@]}"; do
        pushd "$DirSource"
          archive_unpack "$Archive" "$DirTarget/$(dirname "$Archive")"
          rm -v "$Archive"
          rm -v "$(dirname "$Archive")/$(basename "$Archive").r"[0-9][0-9] || true
          rm -v "$(dirname "$Archive")/$(basename "$Archive").part"[0-9][0-9]".rar" || true
        popd
      done
    else
      break
    fi
  done
  set -o nounset
}

build_index () {
  local -a Array
  local i
  local -r Name="$1"
  declare -A -g ${Name}Index

  eval Array=("\"\${${Name}[@]}\"")

  set +o nounset
  for i in "${!Array[@]}"; do
    eval ${Name}Index["${Array["$i"]}"]="$i"
  done
  set -o nounset
}

