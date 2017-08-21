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

# Hardcodes prefixs of all dependencies.
#PATH#

#deluge-console -c /home35/jackal/.config/deluge/ "connect 5.79.67.48:21096 jackal DgVlV6HtNqW; info 30435a5872d07b226051516949bb04b1bfcfaf5a"

# XXX: tpslimit is purposely set fairly low to prevent sending to many
#      api requests at once since rclone does not throttle requests.

# Get necessary XDG directories or use defaults if undefined
XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
if [ -f "$XDG_CONFIG_HOME/user-dirs.dirs" ]; then
  source "$XDG_CONFIG_HOME/user-dirs.dirs"
elif [ -f '/etc/xdg/user-dirs.defaults' ]; then
  source '/etc/xdg/user-dirs.defaults'
fi
XDG_DOWNLOAD_DIR="${XDG_DOWNLOAD_DIR:-$HOME/.config}"
XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_CONFIG_HOME XDG_DATA_HOME XDG_DOWNLOAD_DIR

CONFIG_DIR="${CONFIG_DIR:-$XDG_CONFIG_HOME/conveyor}"

if [ ! -f "$CONFIG_DIR/config" ]; then
  install -D -m600 -v "$PREFIX/share/conveyor/config.template" \
    "$CONFIG_DIR/config"
fi

source "$CONFIG_DIR/config"

if [ "$DOWNLOAD_COMPLETE_DIR" == "$DOWNLOAD_DATA_DIR" ]; then
  echo "ERROR: DOWNLOAD_COMPLETE_DIR and DOWNLOAD_DATA_DIR must be different directories" >&2
  exit 1
fi

source "$(lib-bash)"

declare -a -r Vars=(
  DOWNLOAD_COMPLETE_DIR
  DOWNLOAD_DATA_DIR
  RCLONE_REMOTE
  RCLONE_REMOTE_OFFLOAD_DIR
  RCLONE_REMOTE_SORTED_DIR
)
for Var in "${Vars[@]}"; do
  eval VarEval="\$$Var"
  if [ -z "$VarEval" ]; then
    echo "ERROR: $Var undefined" >&2
    exit 1
  fi
done



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

archive_ext() {
  local Extension
  local -r File="$1"

  # FIXME: use grep perl regex

  # Find correct RAR file extension
  if [ "${File##*.}" == 'r00' ]; then
    Extension='r00'
  elif [ "${File##*.}" == 'rar' ]; then
    # FIXME: will break on filenames with periods
    if [ "${File#*.}" == 'part01.rar' ]; then
      Extension='part01.rar'
    elif [ "${File#*.}" == 'subs.rar' ]; then
      Extension='subs.rar'
    else
      Extension='rar'
    fi
  elif [ "${File##*.}" == 'zip' ]; then
    Extension='zip'
  else
    Log::Message 'error' "unknown archive extension: ${File}"
    return 1
  fi

  echo "$Extension"
}

archive_utility() {
  local -r Type="$1"

  if [ "$Type" == 'rar' ]; then
    if type 'unrar'; then
      echo 'unrar'
    elif type '7za'; then
      echo '7z'
    else
      return 2
    fi
  else
    return 1
  fi
}

archive_type() {
  local Extension
  local -r File="$1"

  Extension="$(archive_ext "$File")"

  case "$Extension" in
    'r00'|'rar'|'part01.rar'|'subs.rar') echo 'rar' ;;
    'zip') echo 'zip' ;;
    *) return 1 ;;
  esac
}

archive_unpack() {
  local -r Archive="$1"
  local -r Destination="$2"
  local ArchiveUtility

  ArchiveUtility="$(archive_utility "$Archive")"

  case "$ArchiveUtility" in
    'unrar')
      unrar x -o+ "$Archive" "$Destination"
      ;;
    '7z')
      echo "not implemented"
      return 1
      ;;
  esac
}

archive_scan() {
  local Archive
  local -a Archives
  local -r Dir="$1"

  # XXX: fucking scene cunts nest rar archives, *.subs.rar contains
  #      *.idx and *.rar which has the sub file.
  find_archives() {
    RCLONE_LS_EXTRA_ARGS+=('--include' '*.{rar,zip}') rc_ls "$Dir"
  }

  while true; do
    Archives=()
    mapfile -t Archives < <(find_archives "$Dir")
    if [ -n "$Archives[*]" ]; then
      for Archive in "${Archives[@]}"; do
        archive_unpack "$Archive" "$(dirname "$Archive")"
        rm -fv "$Archive"
      done
    else
      break
    fi
  done
}

relative_to_complete_dir() {
  Function::RequiredArgs '1' "$#"
  local -r Path="$1"
  local RelativePath

  RelativePath="$(echo "$Path" | sed -e "s,$DOWNLOAD_COMPLETE_DIR/,,")"

  echo "$RelativePath"
}

tolower() { echo ${@,,} ; }

local_archive_unpack() {
  local -r File="$1"
  local -r Destination="$2"
  local Type

  Type="$(archive_type "$File")"

  Utility="$(archive_utility "$Type")"

  if [ "$Type" == 'rar' ]; then
    if [ "$Utility" == 'unrar' ]; then
      unrar x -o+ "$File" "$Destination"
    elif [ "$Utility" = '7z' ]; then
      7za e -r -ao "$File" -o "$Destination"
    else
      return 1
    fi
  else
    echo "not implemented: $Type" >&2
    return 1
  fi
}

clear_empty_dirs() {
  local -r Dir="$1"

  rclone rmdirs \
    -vv \
    --low-level-retries 20 \
    --tpslimit 4 \
    --tpslimit-burst 10 \
    "$Dir" || true
}

rc_ls() {
  local -r Dir="$1"

  rclone ls \
    --low-level-retries 20 \
    --tpslimit 4 \
    --tpslimit 10 \
    "${RCLONE_LS_EXTRA_ARGS[@]}" \
    "$Dir" |
    # Print all but the first element (size).
    awk '{$1=""; print $0}' |
    # Remove leading/trailing whitespace
    sed -e 's/^\s\+//' -e 's/\s\+$//' 2>&- || true
}

rc_mkdir() {
  local -r Dir="$1"

  rclone mkdir -vv --low-level-retries 20 "$Dir"
}

# XXX: rclone move does not yet support moving files accross filesystem
#      boundaries.  Maybe use copy, then delete source.
rc_move() {
  local -r SourceDir="$1"
  local -r TargetDir="$2"

  rclone move \
    -vv \
    --stats 5s \
    --transfers 1 \
    --low-level-retries 20 \
    --checkers 20 \
    --tpslimit 4 \
    --tpslimit-burst 10 \
    "$SourceDir" "$TargetDir"
}
